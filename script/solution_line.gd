extends Node
class_name SolutionLine

const DiscreteSolutionState = preload("discrete_solution_state.gd")

const Puzzle = Graph.Puzzle
const Vertex = Graph.Vertex

var started: bool
var state_stack: Array
var progress: float
var limit: float
var validity = 0
var vertices_occupied: Array

const EPS = 1e-6

func det(v1: Vector2, v2: Vector2) -> float:
	return v1.x * v2.y - v2.x * v1.y

func try_start_solution_at(puzzle: Puzzle, pos: Vector2) -> bool:
	var state = DiscreteSolutionState.new()
	if (state.initialize(puzzle, pos)):
		validity = 0
		started = true
		progress = 1.0
		state_stack.clear()
		state_stack.push_back(state)
		return true
	return false

func is_completed(puzzle: Puzzle) -> bool:
	if (!started):
		return false
	var crossroad_vertex = state_stack[-1].get_end_vertex(puzzle, Solution.MAIN_WAY)
	if (crossroad_vertex == null):
		return false
	return crossroad_vertex.decorator != null and crossroad_vertex.is_puzzle_end and progress >= 0.8 # allow small gap

func get_total_length(puzzle: Puzzle) -> float:
	if (!started):
		return 0.0
	var result = 0.0
	for i in range(len(state_stack[-1].vertices) - 1):
		var pos1 = state_stack[-1].get_vertex_position(puzzle, Solution.MAIN_WAY, i)
		var pos2 = state_stack[-1].get_vertex_position(puzzle, Solution.MAIN_WAY, i + 1)
		if (i + 2 == len(state_stack[-1].vertices)):
			result += (pos1 - pos2).length() * progress
		else:
			result += (pos1 - pos2).length()
	return result

func get_current_way_position(puzzle: Puzzle, way: int):
	if (!started):
		return null
	var way_vertices = state_stack[-1].vertices[way]
	if (len(way_vertices) == 1):
		return puzzle.vertices[way_vertices[0]].pos
	var p1 = puzzle.vertices[way_vertices[-1]].pos
	var p2 = puzzle.vertices[way_vertices[-2]].pos
	return p1 * progress + p2 * (1 - progress)


func __finish_solution(puzzle: Puzzle, delta: Vector2):
	var crossroad_vertex = state_stack[-1].get_end_vertex(puzzle, Solution.MAIN_WAY)
	var chosen_edge = null
	var best_aligned_score = 0.0
	for edge in puzzle.edges:
		var target_vertex
		var edge_dir
		if (edge.start == crossroad_vertex):
			target_vertex = edge.end
			edge_dir = (edge.end.pos - edge.start.pos).normalized()
		elif (edge.end == crossroad_vertex):
			target_vertex = edge.start
			edge_dir = (edge.start.pos - edge.end.pos).normalized()
		else:
			continue
		var aligned_score = edge_dir.dot(delta)
		if (aligned_score > best_aligned_score):
			chosen_edge = [edge, target_vertex, edge_dir]
			best_aligned_score = aligned_score
	if (chosen_edge == null):
		return
	var vertex_id = chosen_edge[1].index
	if (state_stack[-1].is_retraction(puzzle, vertex_id)):
		progress = 1.0 - EPS
	else:
		var new_state_with_limit = state_stack[-1].transist(puzzle, vertex_id)
		var new_state = new_state_with_limit[0]
		var new_limit = new_state_with_limit[1]
		if (new_state != null):
			state_stack.push_back(new_state)
			limit = new_limit
			progress = EPS
		else:
			progress = 1.0 - EPS


func __calculate_new_progress(
	puzzle: Puzzle,
	delta: Vector2,
	edge_vec: Vector2,
	v1: Vertex,
	v2: Vertex,
) -> float:
	var edge_length = edge_vec.length()
	var projected_length = edge_vec.normalized().dot(delta) / edge_length
	var projected_det = det(edge_vec.normalized(), delta) / edge_length
	var projected_progress = progress + projected_length
	var encourage_extension = false
	if (v1.is_attractor):
		if (v2.is_attractor):
			encourage_extension = progress > 0.5
		else:
			encourage_extension = true
	if (encourage_extension):
		if ([v2, v1] in puzzle.edge_turning_angles):
			var angle = puzzle.edge_turning_angles[[v2, v1]][1 if projected_det < 0 else 0]
			# print('encourage ', angle, ' to add ', projected_det / tan(angle / 2))
			projected_progress -= projected_det / tan(angle / 2 - EPS) * 0.5
	else: # discourage extension
		if ([v1, v2] in puzzle.edge_turning_angles):
			var angle = puzzle.edge_turning_angles[[v1, v2]][1 if projected_det > 0 else 0]
			# print('discourage ', angle, ' to minus ', projected_det / tan(angle / 2))
			projected_progress -= projected_det / tan(angle / 2 - EPS) * 0.5
	if (projected_progress <= 0.0):
		state_stack.pop_back()
		limit = 1.0 + EPS
		progress = 1.0 - EPS
		return 0.0
	return min(projected_progress, limit)


func try_continue_solution(puzzle: Puzzle, mouse_delta: Vector2):
	if (!started):
		return
	var delta = mouse_delta * Gameplay.mouse_speed
	if (delta.length() < EPS):
		return
	if (len(state_stack) == 1 or progress >= 1.0):
		__finish_solution(puzzle, delta)

	if (len(state_stack) <= 1):
		return

	var v1 = state_stack[-1].get_end_vertex(puzzle, Solution.MAIN_WAY)
	var v2 = state_stack[-2].get_end_vertex(puzzle, Solution.MAIN_WAY)
	var edge_vec = v1.pos - v2.pos

	var projected_progress = __calculate_new_progress(puzzle, delta, edge_vec, v1, v2)
	if (projected_progress <= 0.0):
		return

	var projected_position = v1.pos * projected_progress + v2.pos * (1 - projected_progress)
	for decorator in puzzle.decorators:
		if (decorator.rule == 'filament-start'):
			var filament_percentage = decorator.filament_solution.try_continue_solution(decorator.nails, projected_position - decorator.filament_solution.end_pos)
			projected_progress = (projected_progress - progress) * filament_percentage + progress
	progress = projected_progress


func save_to_string(puzzle: Puzzle) -> String:
	var state = state_stack[-1]
	var line_result = []
	for state_way in state.vertices:
		var way_result = []
		for v in state_way:
			way_result.append(str(v))
		line_result.append( ','.join(PackedStringArray(way_result)))
	var line_string = '|'.join(PackedStringArray(line_result))
	var event_property_result = []
	for i in range(len(puzzle.decorators)):
		event_property_result.append(puzzle.decorators[i].property_to_string(state.event_properties[i]))
	var event_string = '|'.join(PackedStringArray(event_property_result))
	return '$'.join(PackedStringArray([line_string, event_string]))

static func load_from_string(string: String, puzzle: Puzzle) -> SolutionLine:
	var state = DiscreteSolutionState.new()
	var line_string_event_string = string.split('$')
	var line_string = line_string_event_string[0]
	var event_string = ''
	if (len(line_string_event_string) > 1):
		event_string = line_string_event_string[1]
	state.vertices = []
	var line_result = line_string.split('|')
	for way_string in line_result:
		var way_vertices = []
		var way_result = way_string.split(',')
		for vertex_string in way_result:
			way_vertices.append(int(vertex_string))
		state.vertices.append(way_vertices)
	state.event_properties = []
	var event_result = event_string.split('|')
	for i in range(len(puzzle.decorators)):
		if i < event_result.size():
			state.event_properties.append(puzzle.decorators[i].string_to_property(event_result[i]))
	for decorator in puzzle.decorators:
		decorator.post_load_state(puzzle, state)

	var solution = SolutionLine.new()
	solution.started = true
	solution.validity = 1
	solution.state_stack = [state]
	solution.progress = 1.0

	return solution
