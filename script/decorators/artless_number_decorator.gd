extends "../decorator.gd"

var rule = 'artless-number'

var count: int = 0

func draw_foreground(canvas: PuzzleCanvas, _owner, _owner_type: int, puzzle: Graph.Puzzle):
	var length = 0.175 * (1 - puzzle.line_width)
	var distance = 0.04 * (1 - puzzle.line_width)
	var height = 0.15 * (1 - puzzle.line_width)
	var count_per_line = (
		2
		if count == 4
		else (
			3
			if count <= 9
			else 4
		)
	)
	var levels = floor((count - 1) / float(count_per_line)) + 1;
	var numbers_per_level = []
	var left = count
	for i in range(levels):
		numbers_per_level.push_back(left if left <= count_per_line else count_per_line)
		left -= numbers_per_level[i]

	var total_height = height * levels + distance * (levels - 1)
	var current_height = total_height / 2
	for level in range(levels):
		var total_width = length * numbers_per_level[level] + distance * (numbers_per_level[level] - 1)
		var p1 = Vector2(-total_width / 2, current_height)
		var p2 = Vector2(-total_width / 2 + length / 2, current_height - height)
		var p3 = Vector2(-total_width / 2 + length, current_height)
		for i in range(numbers_per_level[level]):
			canvas.add_circle(
				(p1 + p2 + p3) / 3, length / 2, color)
			p1 += Vector2(length + distance, 0)
			p2 += Vector2(length + distance, 0)
			p3 += Vector2(length + distance, 0)
		current_height -= height + distance

