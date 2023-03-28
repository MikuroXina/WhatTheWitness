class_name TetrisDecorator
extends "../decorator.gd"

var rule = 'tetris'

var shapes: Array
var is_hollow: bool
var margin_size: float
var border_size: float
var covering: Array
var is_multi: bool
var is_weak: bool

const ROTATION_ANGLES = [0, PI / 3, 2 * PI / 3, PI / 2, PI, 3 * PI / 2, 4 * PI / 3, 5 * PI / 3]

func angle_equal_zero(to_compare: float, eps=1e-3) -> bool:
	var d = round(to_compare / (2 * PI))
	return abs(to_compare - (2 * d * PI)) < eps

func calculate_covering(puzzle: Graph.Puzzle):
	var rotatable = true
	# test if the tetris is skewed
	# in the level editor we usually use 15 degrees or -15 degrees of angle
	# to represent that a tetris is skewed
	for std_angle in ROTATION_ANGLES:
		if angle_equal_zero(angle - std_angle):
			rotatable = false
			break
	var test_angles = ROTATION_ANGLES if rotatable else [angle]
	var shape_centers = []
	for shape in shapes:
		var center = Vector2(0, 0)
		for pos in shape:
			center += pos
		shape_centers.append(center / len(shape))
	covering = []
	var covering_dict = {}
	for rotate_to in test_angles:
		var transform = Transform2D().rotated(rotate_to)
		for i in range(len(puzzle.facets)):
			var ok = true
			var facet_center = puzzle.facets[i].center
			# align the facet center with the shape center
			var relative_pos = facet_center - transform * shape_centers[0]
			transform[2] += relative_pos
			# check if all centers aligned
			var alignment = []
			for k in range(len(shape_centers)):
				var shape_center = shape_centers[k]
				var edge_count = len(shapes[k])
				var transformed_center = transform * shape_center
				var found_alignment = false
				for j in range(len(puzzle.facets)):
					if (len(puzzle.facets[j].vertices) == edge_count and
						puzzle.facets[j].center.distance_squared_to(transformed_center) < 1e-4):
						alignment.append(j)
						found_alignment = true
						break
				if !found_alignment:
					ok = false
					break
			# todo: check if all vertices are aligned
			if !ok:
				continue
			alignment.sort()
			if alignment in covering_dict:
				continue
			covering_dict[alignment] = true
			covering.append(alignment)
	# print('Covering of %d:' % len(shapes), covering)

func __shrink_corner(p0: Vector2, p1: Vector2, p2: Vector2, depth: float) -> Vector2:
	var e1 = (p0 - p1).normalized()
	var e2 = (p2 - p1).normalized()
	var cross = abs(e1.x * e2.y - e2.x * e1.y)
	if cross < 1e-6:
		return p1 + Vector2(-e2.y, e2.x) * depth
	return p1 + (e1 + e2) * depth / cross

func __shrink_shape(shape: PackedVector2Array, depth: float, scale: float) -> PackedVector2Array:
	var result = PackedVector2Array()
	for i in range(shape.size()):
		var p0 = shape[i - 1] if i >= 1 else shape[len(shape) - 1]
		var p1 = shape[i]
		var p2 = shape[i + 1] if i + 1 < len(shape) else shape[0]
		result.append(__shrink_corner(p0, p1, p2, depth) * scale)
	return result

func draw_foreground(canvas: Visualizer.PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var scale = 0.2 * (1 - puzzle.line_width)
	if is_hollow:
		for shape in shapes:
			var hollow_shape = __shrink_shape(shape, margin_size, scale)
			if !hollow_shape.is_empty():
				hollow_shape.append(hollow_shape[0])
			var inner_shape = __shrink_shape(shape, border_size, scale)
			if !inner_shape.is_empty():
				inner_shape.append(inner_shape[0])
			inner_shape.reverse()
			canvas.add_polygon(hollow_shape + inner_shape, color)
	else:
		for shape in shapes:
			canvas.add_polygon(__shrink_shape(shape, margin_size, scale), color)
	if is_multi:
		var plus_size = 0.08 * (1 - puzzle.line_width)
		var plus_position = 0.35 * (1 - puzzle.line_width)
		canvas.add_line(
			Vector2(-plus_size + plus_position, -plus_position).rotated(-angle),
			Vector2(plus_size + plus_position, -plus_position).rotated(-angle),
			plus_size * 0.65, color)
		canvas.add_line(
			Vector2(plus_position, -plus_size - plus_position).rotated(-angle),
			Vector2(plus_position, plus_size - plus_position).rotated(-angle),
			plus_size * 0.65, color)
	if is_weak:
		var circleRadius = 0.08 * (1 - puzzle.line_width)
		var innerRadius = 0.05 * (1 - puzzle.line_width)
		var plus_position = 0.35 * (1 - puzzle.line_width)
		const NB_POINTS = 32
		var points_arc = PackedVector2Array()
		var rel_pos = Vector2(plus_position, -plus_position)
		for i in range(NB_POINTS + 1):
			var angle_point = 2 * i * PI / NB_POINTS
			points_arc.push_back(Vector2.from_angle(angle_point) * circleRadius + rel_pos)
		for i in range(NB_POINTS + 1):
			var angle_point = -2 * i * PI / NB_POINTS
			points_arc.push_back(Vector2.from_angle(angle_point) * innerRadius + rel_pos)
		canvas.add_polygon(points_arc, color)
