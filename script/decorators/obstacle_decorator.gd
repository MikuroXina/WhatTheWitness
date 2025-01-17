extends "../decorator.gd"

var rule = 'obstacle'

var center : Vector2
var radius : int
var size : float
var render_angle: float
var target_angle: float

const TEXTURE = preload("res://img/obstacle.png")

func collide_test(target_pos, solution_length):
	var obstacle_position = get_position(solution_length)
	return (target_pos - obstacle_position).length() <= size / 4

func get_position(solution_length):
	var length = round(solution_length)
	return center + Vector2.from_angle(length * PI / 2) * radius

func draw_above_solution(canvas, _owner, _owner_type, _puzzle, solution):
	var length = round(solution.get_total_length())
	target_angle = length * PI / 2
	render_angle = render_angle * 0.9 + target_angle * 0.1
	var current_position = center + Vector2.from_angle(render_angle) * radius
	canvas.add_texture(current_position, Vector2(size, size), TEXTURE)
