extends Node
class_name DiscreteSolutionState

const Puzzle = Graph.Puzzle
const Vertex = Graph.Vertex

var vertices: Array
var event_properties: Array
var solution_stage: Array
var solution_transform: Transform2D
var start_way: int

func _init():
	vertices = []
	event_properties = []
	solution_stage = []

func copy() -> DiscreteSolutionState:
	var result = DiscreteSolutionState.new()
	result.vertices = vertices.duplicate(true)
	result.event_properties = event_properties.duplicate(true)
	result.solution_stage = solution_stage.duplicate(true)
	result.start_way = start_way
	return result

func get_vertex_position(puzzle: Puzzle, way: int, id: int) -> Vector2:
	return puzzle.vertices[vertices[way][id]].pos

func get_end_position(puzzle: Puzzle, way: int) -> Vector2:
	return puzzle.vertices[vertices[way][-1]].pos

func get_end_vertex(puzzle: Puzzle, way: int) -> Vertex:
	return puzzle.vertices[vertices[way][-1]]

func is_retraction(_puzzle, main_way_vertex_id: int) -> bool:
	if (len(vertices[Solution.MAIN_WAY]) >= 2):
		return main_way_vertex_id == vertices[Solution.MAIN_WAY][-2]
	return false

func transist(puzzle: Puzzle, main_way_vertex_id: int) -> Array:
	var limit = 1.0 + 1e-6
	var main_way_pos = puzzle.vertices[main_way_vertex_id].pos
	var blocked_by_boxes = false
	var new_state = copy()
	var main_way_dir = (
		main_way_pos
		- puzzle.vertices[vertices[Solution.MAIN_WAY][-1]].pos
	).normalized()
	var new_snake_points = []
	var ghost_properties = null
	var new_ghost_properties = null
	var ghost_manager = null

	# preprocess
	for i in range(len(puzzle.decorators)):
		if (puzzle.decorators[i].rule == 'snake-manager'):
			new_snake_points = new_state.event_properties[i]
		elif (puzzle.decorators[i].rule == 'ghost-manager'):
			ghost_manager = puzzle.decorators[i]
			ghost_properties = event_properties[i]
			new_ghost_properties = new_state.event_properties[i]
		elif (puzzle.decorators[i].rule == 'cosmic-manager'):
			new_state.event_properties[i] = puzzle.decorators[i].transist(puzzle, vertices, event_properties[i])

	# introduce new vertices
	for way in range(puzzle.n_ways):
		var way_vertex_id
		if (way == Solution.MAIN_WAY):
			way_vertex_id = main_way_vertex_id
		else:
			var way_crossroad_vertex_id = vertices[way][-1]
			var way_dir = get_symmetry_vector(puzzle, way, main_way_dir)
			way_vertex_id = -1
			for edge in puzzle.edges:
				var new_vertex_id
				var edge_dir
				if (edge.start.index == way_crossroad_vertex_id):
					new_vertex_id = edge.end.index
					edge_dir = edge.end.pos - edge.start.pos
				elif (edge.end.index == way_crossroad_vertex_id):
					new_vertex_id = edge.start.index
					edge_dir = edge.start.pos - edge.end.pos
				else:
					continue
				edge_dir = edge_dir.normalized()
				if ((edge_dir - way_dir).length() < 1e-4):
					way_vertex_id = new_vertex_id
					break
		if (way_vertex_id == -1):
			return [null, null]
		new_state.vertices[way].push_back(way_vertex_id)
		var line_stage = solution_stage[way]
		if (line_stage == Solution.SOLUTION_STAGE_SNAKE):
			new_state.vertices[way].pop_front()
			var v = new_state.vertices[way][0]
			if (v in new_snake_points):
				line_stage = Solution.SOLUTION_STAGE_EXTENSION
				new_snake_points.erase(v)
		if (line_stage == Solution.SOLUTION_STAGE_EXTENSION):
			if (vertices[way][-1] in new_snake_points):
				line_stage = Solution.SOLUTION_STAGE_SNAKE
		if (line_stage == Solution.SOLUTION_STAGE_GHOST):
			if (puzzle.vertices[vertices[way][-1]].decorator.rule == 'ghost'):
				if (ghost_manager.is_solution_point_ghosted(ghost_properties, way, len(vertices[way]) - 1)):
					continue
				var mark = len(vertices[way]) if puzzle.vertices[vertices[way][-1]].decorator.pattern == 0 else -len(vertices[way])
				new_ghost_properties[way].append(mark)
		new_state.solution_stage[way] = line_stage

	# limit calculation
	var main_edge_length = (
		puzzle.vertices[new_state.vertices[Solution.MAIN_WAY][-1]].pos
		- puzzle.vertices[new_state.vertices[Solution.MAIN_WAY][-2]].pos
	).length()
	var occupied_vertices = {}
	var endpoint_occupied = 0
	for way in range(puzzle.n_ways):
		for i in range(len(new_state.vertices[way]) - 1):
			if (ghost_manager != null and ghost_manager.is_solution_point_ghosted(new_ghost_properties, way, i)):
				continue
			occupied_vertices[new_state.vertices[way][i]] = 2 if i == 0 else 1
	for way in range(puzzle.n_ways):
		var second_point = puzzle.vertices[new_state.vertices[way][-2]]
		var end_point = puzzle.vertices[new_state.vertices[way][-1]]
		var edge_length = (end_point.pos - second_point.pos).length()
		if (abs(edge_length - main_edge_length) > 1e-3):
			limit = min(limit, 1.0 - 1e-6)
			if (edge_length < main_edge_length):
				limit = min(limit, 1.0 * edge_length / main_edge_length)
		if (new_state.vertices[way][-1] in occupied_vertices):
			if (ghost_manager != null and ghost_manager.is_solution_point_ghosted(new_ghost_properties, way, len(new_state.vertices[way]) - 1)):
				continue
			endpoint_occupied = max(endpoint_occupied, occupied_vertices[new_state.vertices[way][-1]])
		occupied_vertices[new_state.vertices[way][-1]] = 1 # end of solution also collides
		if (second_point.decorator.rule == 'self-intersection' and endpoint_occupied != 0):
			return [null, null]
		if end_point.decorator.rule != 'self-intersection':
			if (endpoint_occupied == 1): # colliding with other lines / self-colliding
				limit = min(limit, 1.0 - puzzle.line_width / edge_length)
			elif (endpoint_occupied == 2): # colliding with start points
				limit = min(limit, 1.0 - (puzzle.start_size + puzzle.line_width / 2) / edge_length)
		if (end_point.decorator.rule == 'broken'): # broken
			limit = min(limit, 0.5)
	for i in range(len(puzzle.decorators)):
		if (puzzle.decorators[i].rule == 'box'):
			var box_v = new_state.event_properties[i]
			if (!(box_v in occupied_vertices)):
				occupied_vertices[box_v] = 3 # box - box collision
	for i in range(len(puzzle.decorators)):
		if (puzzle.decorators[i].rule == 'box'):
			var box_v = new_state.event_properties[i]
			if (box_v in occupied_vertices and occupied_vertices[box_v] <= 2):
				var colliding_way = -1
				for way in range(puzzle.n_ways):
					var way_end_v = new_state.vertices[way][-1]
					if (way_end_v == box_v):
						if (colliding_way == -1):
							colliding_way = way
						else:
							colliding_way = -2
				if (colliding_way >= 0):
					var way_end_v = new_state.vertices[colliding_way][-1]
					var way_secondary_end_v = new_state.vertices[colliding_way][-2]
					var old_box_position = puzzle.vertices[way_end_v].pos
					var way_edge_dir = (old_box_position - puzzle.vertices[way_secondary_end_v].pos).normalized()
					if (!self.__perform_push(puzzle, new_state, i, way_edge_dir, occupied_vertices)):
						blocked_by_boxes = true
				else:
					blocked_by_boxes = true
	if (blocked_by_boxes):
		limit = min(limit, 0.22)

	# postprocess
	for i in range(len(puzzle.decorators)):
		if (puzzle.decorators[i].rule == 'laser-manager'):
			puzzle.decorators[i].update_lasers(new_state.event_properties[i], puzzle, new_state)

	return [new_state, limit]

func __perform_push(puzzle: Puzzle, state: DiscreteSolutionState, box_id: int, dir: Vector2, occupied_vertices: Array) -> bool:
	var old_vertex_id = state.event_properties[box_id]
	var old_box_position = puzzle.vertices[old_vertex_id].pos
	var new_box_position = old_box_position + dir
	var new_vertex = puzzle.get_vertex_at(new_box_position)
	if (new_vertex == null):
		return false # out of bounds
	if (new_vertex.index in occupied_vertices):
		if (occupied_vertices[new_vertex.index] != 3):
			return false
		# recursive box-box pushing
		for i in range(len(puzzle.decorators)):
			if (puzzle.decorators[i].rule == 'box'):
				var box_v = state.event_properties[i]
				if (box_v == new_vertex.index):
					if (!__perform_push(puzzle, state, i, dir, occupied_vertices)):
						return false
	# todo: update occupied vertices in case multiple pushes
	state.event_properties[box_id] = new_vertex.index
	return true

func get_symmetry_point(puzzle: Puzzle, way: int, pos: Vector2) -> Vector2:
	if (way == 0 or len(puzzle.symmetry_transforms) == 0):
		return pos
	return puzzle.symmetry_transforms[(way + start_way) % puzzle.n_ways].basis_xform(
		puzzle.symmetry_transforms[start_way].basis_xform_inv(pos)
	)

func get_symmetry_vector(puzzle: Puzzle, way: int, vec: Vector2) -> Vector2:
	if (way == 0 or len(puzzle.symmetry_transforms) == 0):
		return vec
	return puzzle.symmetry_transforms[(way + start_way) % puzzle.n_ways].basis_xform(
		puzzle.symmetry_transforms[start_way].basis_xform_inv(vec))

func pos_to_vertex_id(puzzle: Puzzle, pos: Vector2, eps=1e-3) ->int:
	for vertex in puzzle.vertices:
		if (vertex.pos.distance_to(pos) < eps):
			return vertex.index
	return -1

func get_nearest_start(puzzle: Puzzle, pos: Vector2):
	var best_dist = puzzle.start_size
	var result = null
	for vertex in puzzle.vertices:
		if (vertex.is_puzzle_start):
			var dist = (pos - vertex.pos).length()
			if (dist < best_dist):
				result = vertex
				best_dist = dist
	return result

func initialize(puzzle: Puzzle, pos: Vector2) -> bool:
	start_way = 0
	while (start_way < puzzle.n_ways):
		vertices.clear()
		var est_start_vertex = get_nearest_start(puzzle, pos)
		if (est_start_vertex == null):
			start_way += 1
			continue
		var ok = true
		for way in range(puzzle.n_ways):
			var est_way_start_pos = get_symmetry_point(puzzle, way, est_start_vertex.pos)
			var way_start_vertex = get_nearest_start(puzzle, est_way_start_pos)
			if (way_start_vertex == null):
				ok = false
				break
			vertices.push_back([way_start_vertex.index])
			solution_stage.push_back(Solution.SOLUTION_STAGE_EXTENSION)
		if (ok):
			event_properties.clear()
			for decorator in puzzle.decorators:
				event_properties.append(decorator.init_property(puzzle, self, est_start_vertex))
			return true
		start_way += 1
	return false
