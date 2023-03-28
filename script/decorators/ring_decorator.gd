extends "../decorator.gd"

var rule = 'ring'

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var circle_radius = 0.35 * (1 - puzzle.line_width)
	var inner_radius = 0.25 * (1 - puzzle.line_width)
	const NB_POINTS = 32
	var points_arc = PackedVector2Array()
	for i in range(NB_POINTS):
		var angle_point = 2 * i * PI / NB_POINTS
		points_arc.push_back(Vector2.from_angle(angle_point) * circle_radius)
	for i in range(NB_POINTS):
		var angle_point = -2 * i * PI / NB_POINTS
		points_arc.push_back(Vector2.from_angle(angle_point) * inner_radius)
	canvas.add_polygon(points_arc, color)
