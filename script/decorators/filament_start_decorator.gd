extends "../decorator.gd"

var rule = 'filament-start'

var nails: Array

var filament_solution = null
var circle_radius = 0.08

const FilamentSolution = Filament.FilamentSolution

func draw_above_solution(canvas: PuzzleCanvas, _owner, _owner_type, puzzle, _solution):
	if filament_solution == null:
		return

	var filament_solution_length = len(filament_solution.path_points)
	for i in range(filament_solution_length):
		var end_pos = (
			filament_solution.end_pos
			if i + 1 == filament_solution_length
			else filament_solution.path_points[i + 1][0]
		)
		canvas.add_line(
			filament_solution.path_points[i][0],
			end_pos,
			puzzle.line_width / 4,
			Color.WHITE)
		canvas.add_circle(end_pos, puzzle.line_width / 8, Color.WHITE)
	canvas.add_circle(filament_solution.start_pos, circle_radius, Color.BLACK)

func add_pillar(pos: Vector2):
	for i in range(8):
		nails.append(pos + Vector2.from_angle(i * PI / 4) * circle_radius)

func init_property(_puzzle, _solution_state, start_vertex):
	filament_solution = FilamentSolution.new()
	filament_solution.try_start_solution_at(start_vertex.pos, circle_radius)
	return filament_solution

func vector_to_string(vec: Vector2) -> String:
	return '%.2f/%.2f' % [vec.x, vec.y]

func string_to_vector(string: String) -> Vector2:
	var split_string = string.split('/')
	if len(split_string) == 2:
		return Vector2(float(split_string[0]), float(split_string[1]))
	return Vector2.ZERO

func property_to_string(property) -> String:
	var point_result = PackedStringArray()
	if property != null:
		for pos in property.path_points:
			point_result.append(vector_to_string(pos[0]))
		point_result.append(vector_to_string(property.end_pos))
	return ','.join(point_result)

func string_to_property(string: String) -> FilamentSolution:
	filament_solution = FilamentSolution.new()
	var point_result = string.split(',')
	if len(point_result) > 1:
		filament_solution.started = true
		for point in point_result:
			filament_solution.path_points.append([string_to_vector(point), -1])
		filament_solution.end_pos = filament_solution.path_points[-1][0]
		filament_solution.path_points.pop_back()
		filament_solution.start_pos = filament_solution.path_points[0][0]
	return filament_solution
