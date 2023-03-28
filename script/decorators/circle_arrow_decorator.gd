extends "../decorator.gd"

var rule = 'circle-arrow'

var is_clockwise: bool = false

func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var circle_radius = 0.32 * (1 - puzzle.line_width)
	var inner_radius = 0.25 * (1 - puzzle.line_width)
	var arrow_size = 0.1 * (1 - puzzle.line_width)
	const NB_POINTS = 32
	var points_arc = PackedVector2Array()
	var angle_point = 0.0
	var dir = 1 if is_clockwise else -1
	var dir_vec = Vector2(dir, 1)
	for i in range(NB_POINTS - 5):
		angle_point = 2 * i * PI / NB_POINTS
		points_arc.push_back(Vector2.from_angle(angle_point) * dir_vec * circle_radius)
	points_arc.push_back(Vector2.from_angle(angle_point) * dir_vec * (arrow_size + circle_radius))
	points_arc.push_back(Vector2.from_angle(angle_point + PI / 6) * dir_vec * (inner_radius + circle_radius) / 2)
	points_arc.push_back(Vector2.from_angle(angle_point) * dir_vec * (inner_radius - arrow_size))

	for i in range(NB_POINTS - 6, -1, -1):
		angle_point = 2 * i * PI / NB_POINTS
		points_arc.push_back(Vector2.from_angle(angle_point) * dir_vec * inner_radius)
	canvas.add_polygon(points_arc, color)
