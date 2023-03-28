extends "../decorator.gd"

var rule = 'collapse'
var passed = false

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var line_width = 0.05 * (1 - puzzle.line_width)
	var circle_radius = 0.35 * (1 - puzzle.line_width)
	var inner_radius = 0.3 * (1 - puzzle.line_width)
	const NB_POINTS = 32
	var points_arc = PackedVector2Array()
	var angle_point = 0.0
	for i in range(NB_POINTS):
		angle_point = 2 * i * PI / NB_POINTS
		points_arc.push_back(Vector2.from_angle(angle_point) * circle_radius)
	for i in range(NB_POINTS):
		angle_point = -2 * i * PI / NB_POINTS
		points_arc.push_back(Vector2.from_angle(angle_point) * inner_radius)
	canvas.add_polygon(points_arc, color)
	var line_end = inner_radius * sqrt(0.5)
	canvas.add_line(Vector2(line_end, line_end), Vector2(-line_end, -line_end), line_width, color)
	canvas.add_line(Vector2(line_end, -line_end), Vector2(-line_end, line_end), line_width, color)
