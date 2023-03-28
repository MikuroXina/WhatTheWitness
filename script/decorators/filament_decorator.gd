extends "../decorator.gd"

var rule = 'filament-pillar'
var circle_radius = 0.08
var center: Vector2

var filament_start_decorator
var valid: bool = false

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, _puzzle: Graph.Puzzle):
	canvas.add_circle(Vector2.ZERO, circle_radius, color)

func calculate_validity():
	valid = false
	var filament_solution = filament_start_decorator.filament_solution
	if (filament_solution == null):
		return

	var filament_solution_length = len(filament_solution.path_points)
	for i in range(filament_solution_length):
		var end_pos = (
			filament_solution.end_pos
			if i + 1 == filament_solution_length
			else filament_solution.path_points[i + 1][0]
		)
		var start_pos = filament_solution.path_points[i][0]
		if 0 <= Geometry2D.segment_intersects_circle(start_pos, end_pos, center, circle_radius + 1e-2):
			valid = true
			break
