extends "../decorator.gd"

var rule = 'square'

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var circle_radius = 0.191 * (1 - puzzle.line_width)
	var distance = 0.067 * (1 - puzzle.line_width)
	const NB_POINTS = 32
	var points_arc = PackedVector2Array()
	for i in range(NB_POINTS):
		var angle_point = 2 * (i + 0.5) * PI / NB_POINTS
		var rotated = Vector2.from_angle(angle_point)
		points_arc.push_back(rotated * circle_radius + Vector2(sign(rotated.x), sign(rotated.y)) * distance)
	canvas.add_polygon(points_arc, color)
