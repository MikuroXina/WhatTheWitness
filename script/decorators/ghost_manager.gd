extends "../decorator.gd"

var rule = 'ghost-manager'

const Puzzle = Graph.Puzzle

const GHOST_COLOR_INTERP_START = 0.2


func draw_indicators(
	puzzle: Puzzle,
	last_pos: Vector2,
	solution_color: Color,
	vertices_way: Array,
	percentage: float,
):
	var line_color = puzzle.line_color
	var canvas = puzzle.canvas
	canvas.add_circle(last_pos, puzzle.line_width / 2.7, line_color)
	canvas.add_circle(last_pos, puzzle.line_width / 3.1, solution_color)
	if (len(vertices_way) >= 3):
		var last_v_pos = puzzle.vertices[vertices_way[-1]].pos
		var second_last_v_pos = puzzle.vertices[vertices_way[-2]].pos
		var third_last_v_pos = puzzle.vertices[vertices_way[-3]].pos
		var last_distance = last_v_pos.distance_to(second_last_v_pos) * percentage
		var second_last_distance = second_last_v_pos.distance_to(third_last_v_pos)
		var follow_distance = 0.5 # the distance that the second indicator from the first indicator
		var second_percentage = (last_distance + second_last_distance - follow_distance) / second_last_distance
		second_percentage = clamp(second_percentage, 0.0, 1.0)
		var second_indicator_pos = second_percentage * second_last_v_pos + (1 - second_percentage) * third_last_v_pos
		canvas.add_circle(second_indicator_pos, puzzle.line_width / 3.4, line_color)
		canvas.add_circle(second_indicator_pos, puzzle.line_width / 3.8, solution_color)


func draw_below_solution(canvas, id, _owner_type, puzzle: Puzzle, solution):
	if (
		solution == null or
		not solution.started or
		len(solution.state_stack[-1].event_properties) <= id
	):
		return
	var state = solution.state_stack[-1]
	var vertex_ghost_property = state.event_properties[id]
	var main_way = Solution.MAIN_WAY
	var vertices_main_way = state.vertices[main_way]
	for way in range(puzzle.n_ways):
		if (
			way >= len(state.vertices) or
			len(state.solution_stage) <= way or
			state.solution_stage[way] != Solution.SOLUTION_STAGE_GHOST
		):
			continue

		var vertices_way = state.vertices[way]
		var solution_color = puzzle.solution_colors[way]
		if solution.validity == -1:
			solution_color = Color.BLACK
		elif solution.validity == 0: # drawing illumination
			solution_color = Color(
				1 - (1 - solution_color.r) * 0.6,
				1 - (1 - solution_color.g) * 0.6,
				1 - (1 - solution_color.b) * 0.6,
				solution_color.a,
			)

		var last_pos = puzzle.vertices[vertices_way[0]].pos
		canvas.add_circle(last_pos, puzzle.start_size, solution_color)
		var last_point_ghosted = false
		var percentage = 0.0
		for i in range(1, len(vertices_way)):
			var segment = [puzzle.vertices[vertices_way[i - 1]].pos, puzzle.vertices[vertices_way[i]].pos]

			if i + 1 == len(vertices_way):
				var segment_main = [puzzle.vertices[vertices_main_way[-2]].pos, puzzle.vertices[vertices_main_way[-1]].pos]
				var main_line_length = (segment_main[1] - segment_main[0]).length()
				var line_length = (segment[1] - segment[0]).length()
				var segment_progress = solution.progress
				percentage = segment_progress * main_line_length / line_length
			else:
				percentage = 1.0

			var pos = segment[0] * (1.0 - percentage) + segment[1] * percentage
			var point_ghosted = is_solution_point_ghosted(vertex_ghost_property, way, i)
			if last_pos != null:
				var a = 0 if point_ghosted else 1
				var prev_a = 0 if last_point_ghosted else 1
				if (percentage < 1 - GHOST_COLOR_INTERP_START):
					var t = max(0, (percentage - GHOST_COLOR_INTERP_START) / (1 - 2 * GHOST_COLOR_INTERP_START))
					a = a * t + prev_a * (1 - t)
				var point_color = Color(solution_color, a)
				var prev_point_color = Color(solution_color, prev_a)

				var t1 = min(percentage, GHOST_COLOR_INTERP_START) / percentage
				var t2 = min(percentage, 1 - GHOST_COLOR_INTERP_START) / percentage
				canvas.add_circle(pos, puzzle.line_width / 2.0, point_color)
				canvas.add_gradient_lines(
					[last_pos, last_pos * (1 - t1) + pos * t1,
					last_pos * (1 - t2) + pos * t2, pos],
					puzzle.line_width, [prev_point_color, prev_point_color, point_color, point_color])
			last_pos = pos
			last_point_ghosted = point_ghosted
		if solution.validity == 0: # drawing indicators for invisible line
			draw_indicators(puzzle, last_pos, solution_color, vertices_way, percentage)


func is_solution_point_ghosted(vertex_ghost_property, way, id) -> bool:
	if len(vertex_ghost_property) <= way:
		return false

	var way_ghost_points = vertex_ghost_property[way]
	var phase = 0 if len(way_ghost_points) == 0 else abs(way_ghost_points[0]) - 1
	for i in range(len(way_ghost_points) + 1):
		var prev_pos = 0 if i == 0 else way_ghost_points[i - 1]
		var next_pos = way_ghost_points[i] if i < len(way_ghost_points) else id + 1 # INF
		if id <= abs(next_pos) - 1:
			if prev_pos > 0: # pattern = 0, or equivalently cycle 100011
				return (id - phase) % 6 in [1, 2, 3]
			if prev_pos < 0: # pattern = 1, or equivalently cycle 000010
				return (id - phase) % 6 != 5
			# normal line, not ghosted
			return false
	return false

func init_property(puzzle, solution_state, _start_vertex):
	solution_state.solution_stage.clear()
	for way in range(puzzle.n_ways):
		solution_state.solution_stage.append(Solution.SOLUTION_STAGE_GHOST)
	var vertex_ghost_property = []
	for way in range(puzzle.n_ways):
		vertex_ghost_property.append([])
	return vertex_ghost_property

func property_to_string(vertex_ghost_property) -> String:
	var ghost_result = PackedStringArray()
	for way_property in vertex_ghost_property:
		var way_result = PackedStringArray()
		for v in way_property:
			way_result.append(str(v))
		ghost_result.append(','.join(way_result))
	return '/'.join(ghost_result)

func string_to_property(string: String):
	var ghost_result = string.split('/')
	var vertex_ghost_property = []
	for way_result in ghost_result:
		var way_property = []
		var v_result = way_result.split(',')
		for v_string in v_result:
			way_property.append(int(v_string))
		vertex_ghost_property.append(way_property)
	return vertex_ghost_property

func post_load_state(puzzle, solution_state):
	solution_state.solution_stage.clear()
	for way in range(puzzle.n_ways):
		solution_state.solution_stage.append(Solution.SOLUTION_STAGE_GHOST)

