extends "../decorator.gd"

var rule = 'self-intersection'
var color1: Color
var color2: Color

func draw_shape(canvas, puzzle, _color):
	var radius = 0.45 * puzzle.line_width
	const SPACE = 0.02
	var dirs = [
		Vector2(1, 0),
		Vector2.from_angle(PI / 3),
		Vector2.from_angle(2 * PI / 3),
	]
	canvas.add_polygon(PackedVector2Array([
		radius * dirs[1] - SPACE * dirs[0],
		radius * dirs[2],
		-radius * dirs[0],
		-radius * dirs[1] + SPACE * dirs[2]
	]), color1)
	canvas.add_polygon(PackedVector2Array([
		-radius * dirs[1] + SPACE * dirs[0],
		-radius * dirs[2],
		radius * dirs[0],
		radius * dirs[1] - SPACE * dirs[2]
	]), color2)

func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	draw_shape(canvas, puzzle, color)

func draw_above_solution(canvas, _owner, _owner_type, puzzle, _solution):
	draw_shape(canvas, puzzle, color)
