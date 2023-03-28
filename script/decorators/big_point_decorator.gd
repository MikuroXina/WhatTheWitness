extends "../decorator.gd"

var rule = 'big-point'

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var radius = 0.85 * puzzle.line_width
	var points = []
	for i in range(6):
		points.append(Vector2.from_angle(PI / 3 * i) * radius)
	canvas.add_polygon(points, color)

func draw_below_solution(canvas, id, owner_type, puzzle, _solution):
	return draw_foreground(canvas, id, owner_type, puzzle)
