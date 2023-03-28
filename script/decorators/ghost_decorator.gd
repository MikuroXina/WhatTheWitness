extends "../decorator.gd"

var rule = 'ghost'
var pattern: int

func draw_shape(canvas, puzzle, poly_color):
	var multiplier = 1 if pattern == 0 else -1
	var radius = 0.425 * puzzle.line_width
	var tail_height = 0.5 * radius
	var points_arc = PackedVector2Array()
	const NB_POINTS = 16
	for i in range(NB_POINTS + 1):
		var angle_point = i * PI / NB_POINTS
		points_arc.push_back(Vector2.from_angle(angle_point) * radius * multiplier)
	for j in range(7):
		var x = (j / 3.0 - 1) * radius
		var y = -radius + j % 2 * tail_height
		points_arc.push_back(Vector2(x, y) * multiplier)
	canvas.add_polygon(points_arc, poly_color)

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	draw_shape(canvas, puzzle, color)

func draw_above_solution(canvas, _owner, _owner_type, puzzle, _solution):
	draw_shape(canvas, puzzle, color)
