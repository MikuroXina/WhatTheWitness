extends "../decorator.gd"

var rule = 'circle'

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var circle_radius = 0.35 * (1 - puzzle.line_width)
	canvas.add_circle(Vector2.ZERO, circle_radius, color)
