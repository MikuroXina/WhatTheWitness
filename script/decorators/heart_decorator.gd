extends "../decorator.gd"

var rule = 'heart'

func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var radius = 0.1 * (1 - puzzle.line_width)
	const NB_POINTS = 32
	var points_arc = PackedVector2Array()
	for i in range(NB_POINTS + 1):
		var t = 2 * i * PI / NB_POINTS
		var sin_t = sin(t)
		var r = sin_t * sqrt(abs(cos(t))) / (sin_t + 1.4) - 2 * sin_t + 2
		points_arc.push_back(Vector2.from_angle(-t) * r * radius - Vector2(0, 1.5 * radius))

	canvas.add_polygon(points_arc, color)
