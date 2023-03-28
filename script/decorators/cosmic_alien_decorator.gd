extends "../decorator.gd"

var rule = 'cosmic-alien'
const ANGER_TEXTURE = preload("res://img/hand_drawing/anger.png")

func draw_alien(canvas, puzzle, pos, poly_color):
	var circle_radius = 0.2 * (1 - puzzle.line_width)
	var inner_radius = 0.1 * (1 - puzzle.line_width)
	const NB_POINTS = 32
	var points_arc = PackedVector2Array()
	points_arc.push_back(pos + Vector2(1, 0) * circle_radius)
	for i in range(NB_POINTS):
		var angle_point = 2 * i * PI / NB_POINTS
		points_arc.push_back(pos + (Vector2.from_angle(angle_point) - Vector2(0, 0.6 * sign(2 * i - NB_POINTS))) * circle_radius)
	for d in [-1.2, 0.8]:
		var base_point = pos + Vector2(circle_radius, d * inner_radius)
		points_arc.push_back(base_point)
		for i in range(floor(NB_POINTS / 2.0), NB_POINTS):
			var angle_point = -2 * i * PI / NB_POINTS
			points_arc.push_back(pos + (Vector2.from_angle(angle_point) + Vector2(0, d)) * inner_radius)
	canvas.add_polygon(points_arc, poly_color)

func draw_anger(canvas, puzzle, pos, poly_color):
	var anger_size = 0.4 * (1 - puzzle.line_width)
	var anger_position = 0.25 * (1 - puzzle.line_width)
	canvas.add_texture(
		pos + Vector2(anger_position, -anger_position),
		Vector2(anger_size, anger_size),
		ANGER_TEXTURE,
		poly_color,
	)


func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	draw_alien(canvas, puzzle, Vector2.ZERO, color)
