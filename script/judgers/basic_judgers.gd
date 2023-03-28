extends Node

const GLOBAL_JUDGERS = [
	'judge_covered_points',
	'judge_covered_cosmic_aliens',
	'preprocess_filament',
	'judge_rings',
]

const REGION_JUDGERS = [
	'judge_region_rings',
	'judge_region_eliminators',
	'judge_region_filament',
	'judge_region_cosmic_aliens',
	'judge_region_points',
	'judge_region_ghosts',
	'judge_region_self_intersections',
	'judge_region_myopia',
	'judge_region_big_points',
	'judge_region_squares',
	'judge_region_stars',
	'judge_region_lands',
	'judge_region_triangles',
	'judge_region_minesweeper',
	'judge_region_circle_arrows',
	'judge_region_graph_counter',
	'judge_region_collapse',
	'judge_region_water',
	'judge_region_artless_numbers',
	'judge_region_arrows',
	'judge_region_tetris',
]

func judge_all(validator: Validation.Validator, require_errors: bool) -> bool:
	for way_vertices in validator.solution.vertices:
		var v = way_vertices[0]
		if v < len(validator.puzzle.vertices) and validator.puzzle.vertices[v].decorator.rule == 'all-error':
			# require all errors
			for global_judger in GLOBAL_JUDGERS:
				call(global_judger, validator, true)
			var ok = true
			var any_error = false
			var collected_responses = []
			var all_error_responses = []
			for response in validator.decorator_responses:
				if response.rule == 'all-error':
					collected_responses.append(response)
					all_error_responses.append(response)
				elif response.rule in ['broken', 'laser-emitter']:
					continue
				else:
					if not response.is_error():
						ok = false
					else:
						any_error = true
					collected_responses.append(response)
			if not require_errors:
				return any_error and ok
			if any_error:
				for response in collected_responses:
					response.state_before_elimination = response.state
					if response.is_error():
						response.mark_as_eliminated()
					else:
						response.mark_as_error()
				for response in all_error_responses:
					response.mark_as_eliminated()
				validator.elimination_happended = true
			else:
				for response in all_error_responses:
					response.mark_as_error()
			return any_error and ok

	var ok = true
	for global_judger in GLOBAL_JUDGERS:
		var judger_ok = call(global_judger, validator, require_errors)
		ok = ok and judger_ok
		if not ok and not require_errors:
			return false
	return ok

func __match_color(solution_color: Color, point_color: Color) -> bool:
	if point_color == Color.BLACK: # black point matches every color
		return true
	return point_color == solution_color


func preprocess_filament(validator: Validation.Validator, _require_errors: bool) -> bool:
	for v in validator.decorator_responses_of_vertex:
		for response in validator.decorator_responses_of_vertex[v]:
			if response.rule == 'filament-pillar':
				response.decorator.calculate_validity()
	return true

func judge_covered_points(validator: Validation.Validator, require_errors: bool) -> bool:
	var all_ok = true
	for v in validator.decorator_responses_of_vertex:
		for response in validator.decorator_responses_of_vertex[v]:
			if not (
				response.rule == 'point' or
				response.rule == 'self-intersection' or
				response.rule == 'big-point'
			):
				continue
			var ok = true
			if validator.vertex_region[v] < -1: # covered point
				if (response.rule == 'self-intersection'):
					var intersection_colors = []
					for way in range(validator.puzzle.n_ways):
						for solution_vertex_id in validator.solution.vertices[way]:
							if solution_vertex_id == v:
								intersection_colors.append(validator.puzzle.solution_colors[way])
					if not (
						len(intersection_colors) == 2 and # must pass 2 times
						(
							(
								__match_color(intersection_colors[0], response.decorator.color1) and
								__match_color(intersection_colors[1], response.decorator.color2)
							) or (
								__match_color(intersection_colors[1], response.decorator.color1) and
								__match_color(intersection_colors[0], response.decorator.color2)
							)
						)
					):
						ok = false
				else: # point and big-points
					if ok and response.rule == 'big-point':
						ok = false
						for way in range(validator.puzzle.n_ways):
							var solution_vertex_id = validator.solution.vertices[way][0]
							if (solution_vertex_id == v):
								# big points only match starts
								ok = true
								break
					var way_id = -validator.vertex_region[v] - 2
					var color = response.color
					if not __match_color(validator.puzzle.solution_colors[way_id], color):
						ok = false
			elif validator.vertex_region[v] == -1: # points that do not belong to any region, neither covered
				ok = false
			if not ok:
				if not require_errors:
					return false
				response.mark_as_error()
				all_ok = false
	return all_ok

func judge_covered_cosmic_aliens(validator: Validation.Validator, require_errors: bool) -> bool:
	var all_ok = true
	for v in validator.decorator_responses_of_vertex:
		for response in validator.decorator_responses_of_vertex[v]:
			if response.rule == 'cosmic-alien':
				if not require_errors:
					return false
				response.mark_as_error()
				all_ok = false
	return all_ok

func judge_rings(validator: Validation.Validator, require_errors: bool) -> bool:
	var clonable_decorators = []
	var paste_positions = []
	for region in validator.regions:
		if validator.puzzle.select_one_subpuzzle and not region.is_near_solution_line:
			continue
		if region.has_any('ring'):
			for decorator_id in region.decorator_indices:
				if not (
					validator.decorator_responses[decorator_id].rule in ['ring', 'circle', 'point', 'filament'] or
					validator.decorator_responses[decorator_id].decorator.color == null
				):
						clonable_decorators.append(decorator_id)
			for decorator_id in region.decorator_dict['ring']:
				paste_positions.append([decorator_id, region])
		if region.has_any('circle'):
			for decorator_id in region.decorator_dict['circle']:
				paste_positions.append([decorator_id, region])
	if paste_positions.is_empty() or clonable_decorators.is_empty():
		return judge_all_regions(validator, require_errors)

	for cloned_decorator_id in clonable_decorators:
		for paste_position in paste_positions:
			var decorator_response = validator.decorator_responses[paste_position[0]]
			validator.alter_rule(paste_position[0], paste_position[1], validator.decorator_responses[cloned_decorator_id].rule)
			decorator_response.clone_source_decorator = decorator_response.decorator
			decorator_response.decorator = validator.decorator_responses[cloned_decorator_id].decorator
		if judge_all_regions(validator, false):
			if require_errors:
				return judge_all_regions(validator, require_errors)
			return true
		for paste_position in paste_positions:
			var decorator_response = validator.decorator_responses[paste_position[0]]
			decorator_response.decorator = decorator_response.clone_source_decorator
	if require_errors:
		var rnd = clonable_decorators[randi() % len(clonable_decorators)]
		for paste_position in paste_positions:
			var decorator_response = validator.decorator_responses[paste_position[0]]
			validator.alter_rule(paste_position[0], paste_position[1], validator.decorator_responses[rnd].rule)
			decorator_response.clone_source_decorator = decorator_response.decorator
			decorator_response.decorator = validator.decorator_responses[rnd].decorator
			# print('current: ', decorator_response.rule)
		return judge_all_regions(validator, require_errors)

	return false

func judge_all_regions(validator: Validation.Validator, require_errors: bool) -> bool:
	var ok = true
	for region in validator.regions:
		if (
			validator.puzzle.select_one_subpuzzle and
			not region.is_near_solution_line
		):
			continue
		var judger_ok = judge_region(validator, region, require_errors)
		ok = judger_ok and ok
	return ok


func judge_region(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if region.has_any('eliminator'):
		return judge_region_elimination(validator, region, require_errors)

	var ok = true
	for region_judger in REGION_JUDGERS:
		var region_judger_ok = call(region_judger, validator, region, require_errors)
		ok = ok and region_judger_ok
		if not ok and not require_errors:
			return false
	return ok

func judge_region_squares(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('square'):
		return true

	var color = null
	var ok = true
	for decorator_id in region.decorator_dict['square']:
		var response = validator.decorator_responses[decorator_id]
		if response.color != color:
			if color != null:
				ok = false
				break
			color = response.color
	if require_errors and not ok:
		var color_counts = {}
		var max_color_count = 0
		var max_color_type = null
		var all_errors = false
		for decorator_id in region.decorator_dict['square']:
			var response = validator.decorator_responses[decorator_id]
			if response.color in color_counts:
				color_counts[response.color] += 1
			else:
				color_counts[response.color] = 1
		for c in color_counts:
			max_color_count = max(color_counts[c], max_color_count)
		for c in color_counts:
			if color_counts[c] == max_color_count:
				if max_color_type == null:
					max_color_type = c
				else:
					all_errors = true
		for decorator_id in region.decorator_dict['square']:
			var response = validator.decorator_responses[decorator_id]
			if all_errors or response.color != max_color_type:
				response.mark_as_error()
	return ok

func judge_region_points(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('point'):
		return true

	var all_ok = true
	for decorator_id in region.decorator_dict['point']:
		var ok = false
		var response = validator.decorator_responses[decorator_id]
		if validator.has_boxes:
			var v_id = response.vertex_index
			for j in region.decorator_indices:
				if j == decorator_id:
					continue
				if validator.decorator_responses[j].vertex_index == v_id:
					ok = __match_color(validator.decorator_responses[j].color, response.color)
					break
		if validator.has_lasers and LaserJudger.laser_pass_point(validator, response.pos, response.color):
			ok = true
		if not ok:
			if not require_errors:
				return false
			response.mark_as_error()
			all_ok = false
	return all_ok

func judge_region_self_intersections(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('self-intersection'):
		return true

	if require_errors:
		for decorator_id in region.decorator_dict['self-intersection']:
			var response = validator.decorator_responses[decorator_id]
			response.mark_as_error()
	return false

func judge_region_ghosts(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('ghost'):
		return true

	if require_errors:
		for decorator_id in region.decorator_dict['ghost']:
			var response = validator.decorator_responses[decorator_id]
			response.mark_as_error()
	return false

func judge_region_big_points(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('big-point'):
		return true
	if require_errors:
		for decorator_id in region.decorator_dict['big-point']:
			var response = validator.decorator_responses[decorator_id]
			response.mark_as_error()
	return false

func judge_region_stars(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('star'):
		return true

	var color_dict = {}
	for decorator_id in region.decorator_indices:
		var response = validator.decorator_responses[decorator_id]
		if not (
			response.rule.begins_with('!eliminated_') or
			response.color == null
		):
			if response.color in color_dict:
				color_dict[response.color] += 1
			else:
				color_dict[response.color] = 1
	var ok = true
	for decorator_id in region.decorator_dict['star']:
		var response = validator.decorator_responses[decorator_id]
		if color_dict[response.color] != 2:
			ok = false
			if not require_errors:
				return false
			response.mark_as_error()
	return ok

func get_region_area(puzzle, region: Validation.Region) -> float:
	var area = 0.0
	for v in region.vertices_indices:
		if puzzle.vertices[v].linked_facet != null:
			var facet = puzzle.vertices[v].linked_facet
			for i in range(2, len(facet.vertices)):
				area += TetrisJudger.calc_triangle_area(
					facet.vertices[0].pos,
					facet.vertices[i - 1].pos,
					facet.vertices[i].pos,
				)
	return area

func judge_region_lands(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	# Not competible with eliminators
	if not region.has_any('land'):
		return true

	var area = get_region_area(validator.puzzle, region)
	var color_count = {}
	for decorator_id in region.decorator_dict['land']:
		var response = validator.decorator_responses[decorator_id]
		var color = response.color
		if color in color_count:
			color_count[color] += 1
		else:
			color_count[color] = 1
	var ok = true
	for color in color_count:
		var color_ok = false
		for region2 in validator.regions:
			var color_count2 = 0
			if region2.has_any('land') and region != region2:
				for decorator_id2 in region2.decorator_dict['land']:
					var response2 = validator.decorator_responses[decorator_id2]
					if response2.color == color:
						color_count2 += 1
				if color_count2 > 0:
					var area2 = get_region_area(validator.puzzle, region2)
					if abs(area2 * color_count[color] - area * color_count2) > 1e-3:
						color_ok = false
						break
					color_ok = true
		if not color_ok:
			if not require_errors:
				return false
			for decorator_id in region.decorator_dict['land']:
				var response = validator.decorator_responses[decorator_id]
				if response.color == color:
					response.mark_as_error()
			ok = false
	return ok

func judge_region_artless_numbers(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('artless-number'):
		return true

	var edge_dict = {}
	var ok = true
	for facet_id in region.facet_indices:
		for edge_tuple in validator.puzzle.facets[facet_id].edge_tuples:
			var v = validator.puzzle.edge_detector_node[edge_tuple]
			if validator.vertex_region[v] < -1: # covered by any line
				edge_dict[v] = true
	for decorator_id in region.decorator_dict['artless-number']:
		var response = validator.decorator_responses[decorator_id]
		if response.decorator.count != len(edge_dict):
			if not require_errors:
				return false
			response.mark_as_error()
			ok = false
	return ok

func judge_region_triangles(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('triangle'):
		return true

	var all_ok = true
	for decorator_id in region.decorator_dict['triangle']:
		var ok = true
		var response = validator.decorator_responses[decorator_id]
		var facet = validator.puzzle.vertices[response.vertex_index].linked_facet
		if facet == null: # the triangle is not placed on facets
			ok = false
		else:
			var count = 0
			for edge_tuple in facet.edge_tuples:
				var v = validator.puzzle.edge_detector_node[edge_tuple]
				if validator.vertex_region[v] < -1: # covered by any line
					count += 1
			if count != response.decorator.count:
				ok = false
		if not ok:
			if not require_errors:
				return false
			response.mark_as_error()
			all_ok = false
	return all_ok

func judge_region_water(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('water'):
		return true

	var all_ok = true
	for decorator_id in region.decorator_dict['water']:
		var ok = true
		var response = validator.decorator_responses[decorator_id]
		var facet = validator.puzzle.vertices[response.vertex_index].linked_facet
		if facet == null: # not placed on facets
			ok = false
		else:
			var count = 0
			for edge_tuple in facet.edge_tuples:
				for f in validator.puzzle.edge_shared_facets[edge_tuple]:
					var v = validator.puzzle.facets[f].center_vertex_index
					if (validator.vertex_region[v] == validator.vertex_region[facet.center_vertex_index]):
						if (v != facet.center_vertex_index and validator.puzzle.vertices[v].decorator.rule == 'water'):
							count += 1
			if count >= 2:
				ok = false
		if not ok:
			if not require_errors:
				return false
			response.mark_as_error()
			all_ok = false
	return all_ok

func judge_region_minesweeper(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('minesweeper'):
		return true

	var all_ok = true
	var vertex_shared_facets = {}
	for facet in validator.puzzle.facets:
		for vertex in facet.vertices:
			if vertex.index in vertex_shared_facets:
				vertex_shared_facets[vertex.index].append(facet.center_vertex_index)
			else:
				vertex_shared_facets[vertex.index] = [facet.center_vertex_index]
	for decorator_id in region.decorator_dict['minesweeper']:
		var ok = true
		var response = validator.decorator_responses[decorator_id]
		var facet = validator.puzzle.vertices[response.vertex_index].linked_facet
		if facet == null: # not placed on facets
			ok = false
		else:
			var count = 0
			var neighbor_facet_vertex_ids = {}
			for vertex in facet.vertices:
				for facet_center_vertex_id in vertex_shared_facets[vertex.index]:
					neighbor_facet_vertex_ids[facet_center_vertex_id] = true
			for v in neighbor_facet_vertex_ids:
				if (validator.vertex_region[v] != validator.vertex_region[facet.center_vertex_index]): # different region
					count += 1
			if count != response.decorator.count:
				ok = false
		if not ok:
			if not require_errors:
				return false
			response.mark_as_error()
			all_ok = false
	return all_ok

func judge_region_circle_arrows(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('circle-arrow'):
		return true

	var all_ok = true
	for decorator_id in region.decorator_dict['circle-arrow']:
		var ok = true
		var response = validator.decorator_responses[decorator_id]
		var is_clockwise = response.decorator.is_clockwise
		var passed_edge_detector_nodes = []
		var facet = validator.puzzle.vertices[response.vertex_index].linked_facet
		if facet == null: # the triangle is not placed on facets
			ok = false
		var center = validator.puzzle.vertices[response.vertex_index].pos
		for edge_tuple in facet.edge_tuples:
			var v = validator.puzzle.edge_detector_node[edge_tuple]
			if validator.vertex_region[v] < -1: # covered by any line
				passed_edge_detector_nodes.append(v)
		if passed_edge_detector_nodes.is_empty():
			ok = false
		else:
			for way_vertices in validator.solution.vertices:
				if len(way_vertices) <= 1: # no direction
					continue
				for i in range(len(way_vertices)):
					var v = way_vertices[i]
					if (v in passed_edge_detector_nodes):
						var v1 = way_vertices[i - 1] if i != 0 else v
						var v2 = way_vertices[i + 1] if i == 0 else v
						if v1 >= len(validator.puzzle.vertices) or v2 >= len(validator.puzzle.vertices):
							continue
						var cross = TetrisJudger.det(
							validator.puzzle.vertices[v2].pos - center,
							validator.puzzle.vertices[v1].pos - center,
						)
						if (cross > 0 and is_clockwise) or (cross < 0 and not is_clockwise):
							ok = false
							break
		if not ok:
			if not require_errors:
				return false
			response.mark_as_error()
			all_ok = false
	return all_ok

func judge_region_myopia(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('myopia'):
		return true

	var ok = true
	for decorator_id in region.decorator_dict['myopia']:
		var response = validator.decorator_responses[decorator_id]
		var origin = validator.puzzle.vertices[response.vertex_index].pos
		var dist_list = []
		var global_min_dist = INF
		for direction in response.decorator.directions:
			var min_dist = INF
			for i in range(len(validator.puzzle.vertices)):
				if validator.vertex_region[i] >= -1:
					continue
				if i == response.vertex_index:
					continue
				var vertex_dir = validator.puzzle.vertices[i].pos - origin
				if abs(vertex_dir.dot(direction.vector) - vertex_dir.length()) < 1e-3:
					min_dist = min(min_dist, vertex_dir.length())
			dist_list.append(min_dist)
			if direction.is_nearest:
				global_min_dist = min(global_min_dist, min_dist)
		for k in range(len(response.decorator.directions)):
			# We test the not condition to handle issues with infinite
			if (
				(response.decorator.directions[k].is_nearest and not (global_min_dist + 1e-3 > dist_list[k])) or
				(not response.decorator.directions[k].is_nearest and not (global_min_dist + 1e-3 < dist_list[k]))
			):
				if not require_errors:
					return false
				response.mark_as_error()
				ok = false
				break
	return ok


func judge_region_arrows(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('arrow'):
		return true

	var ok = true
	for decorator_id in region.decorator_dict['arrow']:
		var response = validator.decorator_responses[decorator_id]
		var origin = validator.puzzle.vertices[response.vertex_index].pos
		var direction = Vector2(-sin(response.decorator.angle), cos(response.decorator.angle))
		var count = 0
		for i in range(len(validator.puzzle.vertices)):
			if validator.vertex_region[i] >= -1:
				continue
			if i == response.vertex_index:
				continue
			var vertex_dir = validator.puzzle.vertices[i].pos - origin
			if abs(vertex_dir.dot(direction) - vertex_dir.length()) < 1e-3:
				count += 1

		if count != response.decorator.count:
			if not require_errors:
				return false
			response.mark_as_error()
			ok = false
	return ok

func judge_region_collapse(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('collapse'):
		return true

	var ok = true
	for decorator_id in region.decorator_dict['collapse']:
		var response = validator.decorator_responses[decorator_id]
		if not response.decorator.passed:
			if not require_errors:
				return false
			response.mark_as_error()
			ok = false
	return ok


func judge_region_tetris(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('tetris'):
		return true
	return TetrisJudger.judge_region_tetris_implementation(validator, region, require_errors)

func judge_region_rings(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('ring') and not region.has_any('circle'):
		return true
	if not require_errors:
		return false
	if region.has_any('ring'):
		for decorator_id in region.decorator_dict['ring']:
			var response = validator.decorator_responses[decorator_id]
			response.mark_as_error()
	if region.has_any('circle'):
		for decorator_id in region.decorator_dict['circle']:
			var response = validator.decorator_responses[decorator_id]
			response.mark_as_error()
	return false

func judge_region_eliminators(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	# only for uneliminated eliminators
	if not region.has_any('eliminator'):
		return true
	if require_errors:
		for decorator_id in region.decorator_dict['eliminator']:
			var response = validator.decorator_responses[decorator_id]
			response.mark_as_error()
	return false

func judge_region_filament(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('filament-pillar'):
		return true
	var all_ok = true
	for decorator_id in region.decorator_dict['filament-pillar']:
		var response = validator.decorator_responses[decorator_id]
		if not response.decorator.valid:
			if not require_errors:
				return false
			response.mark_as_error()
			all_ok = false
	return all_ok

func judge_region_cosmic_aliens(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	var all_ok = true
	if region.has_any('cosmic-alien'):
		for decorator_id in region.decorator_dict['cosmic-alien']:
			var response = validator.decorator_responses[decorator_id]
			if not require_errors:
				return false
			response.mark_as_error()
			all_ok = false
	if region.has_any('cosmic-house'):
		for decorator_id in region.decorator_dict['cosmic-house']:
			var response = validator.decorator_responses[decorator_id]
			if not response.decorator.satisfied:
				if not require_errors:
					return false
				response.mark_as_error()
				all_ok = false
	return all_ok

func judge_region_graph_counter(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	if not region.has_any('graph-counter'):
		return true

	var graph_counter
	var all_ok = true
	var vertex_shapes = {}
	var shape_counter = {}
	for decorator_id in region.decorator_dict['graph-counter']:
		var response = validator.decorator_responses[decorator_id]
		graph_counter = response.decorator
		for line in graph_counter.matrix:
			for original_symbol in line:
				var symbol = (
					graph_counter.get_rotational_symbol(original_symbol)
					if graph_counter.rotational
					else original_symbol
				)
				if symbol > 0:
					if symbol in shape_counter:
						shape_counter[symbol] += 1
					else:
						shape_counter[symbol] = 1
	for v in region.vertices_indices:
		vertex_shapes[v] = 0
	for edge in validator.puzzle.edges:
		var edge_direction = (edge.end.pos - edge.start.pos).normalized()
		var dir_forward = -1
		var dir_backward = -1
		for dir in range(graph_counter.N_DIRS):
			if edge_direction.distance_to(graph_counter.dir_to_vec(dir)) < 1e-3:
				dir_forward = dir
				dir_backward = (dir + graph_counter.N_DIRS / 2) % graph_counter.N_DIRS
		if dir_backward >= 0 and edge.end.index in vertex_shapes:
			vertex_shapes[edge.end.index] |= 1 << dir_backward
			if edge.end.decorator.rule == 'broken':
				vertex_shapes[edge.end.index] |= 1 << graph_counter.MASK_BROKEN
		if dir_forward >= 0 and edge.start.index in vertex_shapes:
			vertex_shapes[edge.start.index] |= 1 << dir_forward
			if edge.start.decorator.rule == 'broken':
				vertex_shapes[edge.start.index] |= 1 << graph_counter.MASK_BROKEN
	# print('Old:', shape_counter)
	for v in region.vertices_indices:
		var original_symbol = vertex_shapes[v]
		var rotational_symbol = graph_counter.get_rotational_symbol(original_symbol)
		for symbol in [original_symbol, rotational_symbol]:
			if symbol in shape_counter:
				shape_counter[symbol] -= 1
			else:
				shape_counter[symbol] = -1
	# print('New:', shape_counter)
	for decorator_id in region.decorator_dict['graph-counter']:
		var response = validator.decorator_responses[decorator_id]
		var decorator = response.decorator
		for line in decorator.matrix:
			for original_symbol in line:
				var symbol = graph_counter.get_rotational_symbol(original_symbol) if graph_counter.rotational else original_symbol
				if (symbol > 0) and not (symbol in shape_counter and shape_counter[symbol] == 0):
					if not require_errors:
						return false
					response.mark_as_error()
					all_ok = false
	return all_ok

func __judge_region_elimination_case(
	validator: Validation.Validator,
	region: Validation.Region,
	require_errors: bool,
	error_list: Array,
	eliminator_list: Array,
	eliminator_targets: Array,
) -> bool:
	for i in range(len(eliminator_list)):
		for id in [eliminator_list[i], error_list[eliminator_targets[i]]]:
			validator.alter_rule(id, region, '!eliminated_' + validator.decorator_responses[id].rule)

	var ok = true
	for region_judger in REGION_JUDGERS:
		var region_judger_ok = call(region_judger, validator, region, require_errors)
		ok = ok and region_judger_ok
		if not ok and not require_errors:
			break
	for i in range(len(eliminator_list)):
		for id in [eliminator_list[i], error_list[eliminator_targets[i]]]:
			validator.alter_rule(id, region, validator.decorator_responses[id].rule.substr(12))
	if require_errors:
		for i in range(len(eliminator_list)):
			for id in [eliminator_list[i], error_list[eliminator_targets[i]]]:
				validator.decorator_responses[id].mark_as_eliminated()
	return ok


func judge_region_elimination(validator: Validation.Validator, region: Validation.Region, require_errors: bool) -> bool:
	var ok = true
	for region_judger in REGION_JUDGERS:
		if region_judger == 'judge_region_eliminators':
			continue
		var region_judger_ok = call(region_judger, validator, region, true)
		ok = ok and region_judger_ok
	var error_list = []
	var eliminator_list = []
	for decorator_id in region.decorator_indices:
		var response = validator.decorator_responses[decorator_id]
		if response.is_error():
			error_list.append(decorator_id)
		if response.rule == 'eliminator':
			eliminator_list.append(decorator_id)
		response.eliminate()
	if error_list.is_empty() and len(eliminator_list) == 1:
		# special case: only one eliminator exists and there is no error
		# the eliminator cannot erase itself
		if require_errors:
			validator.decorator_responses[eliminator_list[0]].mark_as_error()
			validator.decorator_responses[eliminator_list[0]].mark_as_error_before_elimination()
		return false
	validator.elimination_happended = true
	# otherwise, one eliminator can erase any error (which is the assumption in searching)
	# if it happens to eliminate itself, it is still a valid solution
	# since we can swap the targets of two eliminators to bypass this
	while len(error_list) < len(eliminator_list): # number of errors is insufficient
		var last_eliminator = eliminator_list.back()
		error_list.append(last_eliminator) # mark the eliminator as error
		eliminator_list.pop_back()
		validator.decorator_responses[last_eliminator].mark_as_error_before_elimination()
	var eliminator_targets = []
	var random_eliminator_targets = []
	var max_random_weights = randf()
	for i in range(len(eliminator_list)):
		eliminator_targets.append(i)
		random_eliminator_targets.append(i)
	var diff = len(error_list) - len(eliminator_list)
	while true:
		if __judge_region_elimination_case(validator, region, false, error_list, eliminator_list, eliminator_targets):
			if require_errors:
				return __judge_region_elimination_case(validator, region, require_errors, error_list, eliminator_list, eliminator_targets)
			break
		var rnd = randf()
		if rnd > max_random_weights:
			max_random_weights = rnd
			for i in range(len(eliminator_list)):
				random_eliminator_targets[i] = eliminator_targets[i]
		for j in range(len(eliminator_list) - 1, -1, -1):
			if eliminator_targets[j] < j + diff:
				eliminator_targets[j] += 1
				for k in range(j + 1, len(eliminator_list)):
					eliminator_targets[k] = eliminator_targets[k - 1] + 1
				break
			if j != 0:
				continue
			# all combination fails
			for i in range(len(eliminator_list)):
				if not require_errors:
					return false
				eliminator_targets[i] = random_eliminator_targets[i]
				return __judge_region_elimination_case(
					validator,
					region,
					require_errors,
					error_list,
					eliminator_list,
					eliminator_targets,
				)
	return true

