extends "../decorator.gd"

var rule = 'triangle'

var count: int = 0

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var length = 0.2 * (1 - puzzle.line_width)
	var distance = 0.05 * (1 - puzzle.line_width)
	var height = 0.175 * (1 - puzzle.line_width)
	var levels = floor((count - 1) / 3.0) + 1;
	var numbers_per_level = []
	var left = count
	for i in range(levels):
		numbers_per_level.push_back(left if left <= 3 else 2 if left == 4 else 3)
		left -= numbers_per_level[i]

	var total_height = height * levels + distance * (levels - 1)
	var current_height = total_height / 2
	for numbers in numbers_per_level:
		var total_width = length * numbers + distance * (numbers - 1)
		var p1 = Vector2(-total_width / 2, current_height)
		var p2 = Vector2(-total_width / 2 + length / 2, current_height - height)
		var p3 = Vector2(-total_width / 2 + length, current_height)
		for i in range(numbers):
			canvas.add_polygon(PackedVector2Array([
				p1,
				p2,
				p3,
			]), color)
			p1 += Vector2(length + distance, 0)
			p2 += Vector2(length + distance, 0)
			p3 += Vector2(length + distance, 0)
		current_height -= height + distance;

