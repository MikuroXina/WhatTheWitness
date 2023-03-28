extends "../decorator.gd"

var rule = 'minesweeper'

var count: int = 0

const TEXTURES = [
	preload("res://img/minesweeper/0.png"),
	preload("res://img/minesweeper/1.png"),
	preload("res://img/minesweeper/2.png"),
	preload("res://img/minesweeper/3.png"),
	preload("res://img/minesweeper/4.png"),
	preload("res://img/minesweeper/5.png"),
	preload("res://img/minesweeper/6.png"),
	preload("res://img/minesweeper/7.png"),
]

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, _puzzle: Graph.Puzzle):
	const CIRCLE_RADIUS = 0.35
	canvas.add_texture(Vector2.ZERO, Vector2(CIRCLE_RADIUS * 2, CIRCLE_RADIUS * 2), TEXTURES[count], color)
