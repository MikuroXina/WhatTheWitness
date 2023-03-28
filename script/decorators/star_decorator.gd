extends "../decorator.gd"

var rule = 'star'

func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var distances = [
		0.2743 * (1 - puzzle.line_width),
		0.21 * (1 - puzzle.line_width),
	]
	const NB_POINTS = 16
	var points_arc = PackedVector2Array()
	for i in range(NB_POINTS):
		var angle_point = 2 * i * PI / NB_POINTS
		points_arc.push_back(Vector2.from_angle(angle_point) * distances[i % 2])
	canvas.add_polygon(points_arc, color)
