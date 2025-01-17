extends "../decorator.gd"

var rule = 'all-error'

const END_DIRECTIONS = [
	Vector2(0.0, -1.0),
	Vector2(-0.8660254, 0.5),
	Vector2(0.8660254, 0.5),
]

const CURVE_POINTS_TEMPLATE = [
	Vector2(-0.046, -0.176),
	Vector2(0.046, -0.176),
	Vector2(0.046, -0.0264),
	Vector2(0.18456, 0.0536),
	Vector2(0.13856, 0.13312),
	Vector2(0.0, 0.05312),
	Vector2(-0.13856, 0.13312),
	Vector2(-0.18456, 0.0536),
	Vector2(-0.046, -0.0264),
]

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, _puzzle: Graph.Puzzle):
	canvas.add_polygon(CURVE_POINTS_TEMPLATE, color)

func draw_above_solution(canvas, _owner, _owner_type, _puzzle, solution):
	if solution == null or solution.validity == 0:
		canvas.add_polygon(CURVE_POINTS_TEMPLATE, color)
