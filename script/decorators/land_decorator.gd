extends "../decorator.gd"

var rule = 'land'

const LAND_TEXTURE = preload("res://img/land.png")

func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var size = 1.0 * (1 - puzzle.line_width)
	canvas.add_texture(Vector2.ZERO, Vector2(size, size), LAND_TEXTURE, color)
