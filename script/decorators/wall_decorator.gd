extends "../decorator.gd"

var rule = 'wall'

const TEXTURE = preload("res://img/obstacle.png")

func draw_foreground(canvas: Visualizer.PuzzleCanvas, owner, owner_type: int, puzzle: Graph.Puzzle):
	const CIRCLE_RADIUS = 0.35
	canvas.add_texture(Vector2.ZERO, Vector2(CIRCLE_RADIUS, CIRCLE_RADIUS) * 2, TEXTURE, color)
