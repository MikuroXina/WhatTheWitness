extends "../decorator.gd"

var rule = 'laser-manager'

var n_laser = 0
var init_lasers = []
var obstacle_positions = []
var laser_colors = []
const INF_FAR = 9999.99
const MAX_REFLECTION = 512
const LASER_EMITTER_OBS_RADIUS = 0.05
const LASER_EMITTER_RADIUS = 0.1
const CORNER_SIZE = 0.02
var min_x = -INF
var min_y = -INF
var max_x = INF
var max_y = INF

func draw_additive_layer(canvas: PuzzleCanvas, id, _owner_type, puzzle, solution):
	var lasers = (
		init_lasers
		if (
			solution == null or
			not solution.started or
			len(solution.state_stack[-1].event_properties) <= id
		)
		else solution.state_stack[-1].event_properties[id]
	)

	for k in range(len(lasers)):
		if k >= n_laser:
			continue
		var transparent_color = Color(laser_colors[k], 0.5)
		var laser = lasers[k]
		for i in range(len(laser) - 1):
			var start_pos = laser[i]
			var end_pos = laser[i + 1]
			canvas.add_line(
				start_pos,
				end_pos,
				puzzle.line_width / 4,
				transparent_color)

func laser_reflection(laser, puzzle, solution_state):
	if len(laser) < 2 or len(laser) >= MAX_REFLECTION:
		return

	var laser_pos = laser[-2]
	var laser_dir = (laser[-1] - laser[-2]).normalized()
	var laser_end = laser_pos + laser_dir * INF_FAR
	laser_pos += laser_dir * 1e-3

	var nearest_collision_pos = null
	var nearest_collision_dist = INF
	var nearest_collision_normal = null
	var collision_is_reflection = true
	if solution_state != null:
		for way_vertices in solution_state.vertices:
			var last_cut_pos = null
			for i in range(len(way_vertices) - 1):
				var pos1 = puzzle.vertices[way_vertices[i]].pos
				var pos2 = puzzle.vertices[way_vertices[i + 1]].pos
				var edge_dir = (pos2 - pos1).normalized()
				# cut corners
				pos1 += edge_dir * CORNER_SIZE
				pos2 -= edge_dir * CORNER_SIZE
				if i + 2 < len(way_vertices): # line collision
					var intersect = Geometry2D.segment_intersects_segment(pos1, pos2, laser_pos, laser_end)
					if intersect != null:
						var collision_dist = intersect.distance_to(laser_pos)
						if collision_dist >= 0 and collision_dist < nearest_collision_dist:
							nearest_collision_dist = collision_dist
							nearest_collision_pos = intersect
							nearest_collision_normal = edge_dir
				if last_cut_pos == null:
					last_cut_pos = pos2
					continue
				# corners collision
				var corner_intersect = Geometry2D.segment_intersects_segment(pos1, last_cut_pos, laser_pos, laser_end)
				if corner_intersect == null:
					last_cut_pos = pos2
					continue
				# print('collision!', pos1, last_cut_pos)
				var collision_dist = corner_intersect.distance_to(laser_pos)
				if collision_dist >= 0 and collision_dist < nearest_collision_dist:
					# print('new nearest!', pos1, last_cut_pos)
					nearest_collision_dist = collision_dist
					nearest_collision_normal = (pos1 - last_cut_pos).normalized()
					var actual_corner = puzzle.vertices[way_vertices[i]].pos
					nearest_collision_pos = actual_corner + (corner_intersect - actual_corner).reflect(Vector2(-nearest_collision_normal.y, nearest_collision_normal.x))
				last_cut_pos = pos2
	for obs_pos in obstacle_positions:
		var dist = Geometry2D.segment_intersects_circle(laser_pos, laser_end, obs_pos, LASER_EMITTER_OBS_RADIUS) * INF_FAR
		if dist > 0 and dist < nearest_collision_dist + 1e-2:
			nearest_collision_dist = dist
			nearest_collision_pos = laser_pos + laser_dir * dist
			collision_is_reflection = false

	if max(max_x, max_y) < INF_FAR:
		for border_id in range(4):
			var x1 = [min_x, min_x, max_x, min_x][border_id]
			var x2 = [min_x, max_x, max_x, max_x][border_id]
			var y1 = [min_y, min_y, min_y, max_y][border_id]
			var y2 = [max_y, min_y, max_y, max_y][border_id]
			var intersect = Geometry2D.segment_intersects_segment(laser_pos, laser_end, Vector2(x1, y1), Vector2(x2, y2))
			if intersect == null:
				continue
			var dist = intersect.distance_to(laser_pos)
			if dist > 0 and dist < nearest_collision_dist + 1e-2:
				nearest_collision_dist = dist
				nearest_collision_pos = intersect
				collision_is_reflection = false

	if nearest_collision_pos == null:
		return false
	# print('adopts', nearest_collision_dist, nearest_collision_normal)
	laser[-1] = nearest_collision_pos
	if collision_is_reflection:
		var new_dir = laser_dir.reflect(nearest_collision_normal)
		laser.push_back(nearest_collision_pos + new_dir * INF_FAR)
	return collision_is_reflection

func update_lasers(lasers, puzzle, solution_state):
	for i in range(len(lasers)):
		lasers[i].clear()
		for pos in init_lasers[i]:
			lasers[i].append(pos)
		while laser_reflection(lasers[i], puzzle, solution_state):
			pass
	# print(lasers)

func add_laser_emitter(puzzle, pos, laser_color, laser_angle):
	n_laser += 1
	laser_colors.append(laser_color)
	init_lasers.append([
		pos + Vector2.from_angle(-laser_angle) * LASER_EMITTER_RADIUS,
		pos + Vector2.from_angle(-laser_angle) * INF_FAR
	])
	obstacle_positions.append(pos)
	# initial reflection / blocking
	for i in range(len(init_lasers)):
		while(laser_reflection(init_lasers[i], puzzle, null)):
			pass

func init_property(_puzzle, _solution_state, _start_vertex):
	return init_lasers

func vector_to_string(vec: Vector2) -> String:
	return '%.2f/%.2f' % [vec.x, vec.y]

func string_to_vector(string: String) -> Vector2:
	var split_string = string.split('/')
	if len(split_string) == 2:
		return Vector2(float(split_string[0]), float(split_string[1]))
	return Vector2.ZERO

func property_to_string(lasers) -> String:
	var lasers_result = PackedStringArray()
	if (lasers != null):
		for laser in lasers:
			var laser_result = PackedStringArray()
			for pos in laser:
				laser_result.append(vector_to_string(pos))
			lasers_result.append(','.join(laser_result))
	return ';'.join(lasers_result)

func string_to_property(string: String):
	var lasers = []
	var lasers_result = string.split(';')
	for laser_string in lasers_result:
		var laser = []
		var laser_result = laser_string.split(',')
		for pos_string in laser_result:
			laser.append(string_to_vector(pos_string))
		lasers.append(laser)
	return lasers
