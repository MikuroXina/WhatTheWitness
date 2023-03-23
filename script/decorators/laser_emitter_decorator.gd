extends "../decorator.gd"

var rule = 'laser-emitter'

func draw_shape(canvas, _puzzle, poly_color):
	var innerRadius = 0.05
	var nb_points = 32
	var points_arc = []
	for i in range(nb_points + 1):
		var angle_point = 2 * i * PI / nb_points
		points_arc.push_back(Vector2.from_angle(angle_point) * innerRadius)
	canvas.add_polygon(points_arc, poly_color)
	points_arc = [
		Vector2(-0.07, 0.04),
		Vector2(-0.09, 0.06),
		Vector2(0, 0.15),
		Vector2(0.09, 0.06),
		Vector2(0.07, 0.04),
		Vector2(0, 0.11),
	]
	canvas.add_polygon(points_arc, poly_color)

func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	draw_shape(canvas, puzzle, color)

func draw_above_solution(canvas, _owner, _owner_type, puzzle, _solution):
	draw_shape(canvas, puzzle, color)

