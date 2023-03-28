extends "../decorator.gd"

var rule = 'laser-emitter'

func draw_shape(canvas, _puzzle, poly_color):
	const INNER_RADIUS = 0.05
	const NB_POINTS = 32
	var points_arc = PackedVector2Array()
	for i in range(NB_POINTS):
		var angle_point = 2 * i * PI / NB_POINTS
		points_arc.push_back(Vector2.from_angle(angle_point) * INNER_RADIUS)
	points_arc.push_back(points_arc[0])
	canvas.add_polygon(points_arc, poly_color)
	points_arc = PackedVector2Array([
		Vector2(-0.07, 0.04),
		Vector2(-0.09, 0.06),
		Vector2(0, 0.15),
		Vector2(0.09, 0.06),
		Vector2(0.07, 0.04),
		Vector2(0, 0.11),
	])
	canvas.add_polygon(points_arc, poly_color)

func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	draw_shape(canvas, puzzle, color)

func draw_above_solution(canvas, _owner, _owner_type, puzzle, _solution):
	draw_shape(canvas, puzzle, color)
