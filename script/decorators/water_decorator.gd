extends "../decorator.gd"

var rule = 'water'

const TEXTURE = preload("res://img/infinite_water.png")

func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var size = puzzle.start_size * 1.5
	canvas.add_texture(Vector2.ZERO, Vector2(size, size), TEXTURE, color)
