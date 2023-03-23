extends "../decorator.gd"

var rule = 'circle'

func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var circleRadius = 0.35 * (1 - puzzle.line_width)
	canvas.add_circle(Vector2.ZERO, circleRadius, color)


