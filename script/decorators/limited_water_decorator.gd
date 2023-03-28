extends "../decorator.gd"

var rule = 'limited_water'

const WATER_TEXTURE = preload("res://img/infinite_water.png")

func draw_above_solution(canvas, _owner, _owner_type, puzzle, _solution):
	var size = puzzle.start_size * 1.5
	canvas.add_texture(Vector2.ZERO, Vector2(size, size), WATER_TEXTURE, color)
