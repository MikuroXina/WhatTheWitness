extends Control

func _draw():
	if Gameplay.background_texture == null:
		return

	draw_texture(Gameplay.background_texture, Vector2(0, 0))

	Gameplay.draw_solution(self)
	Gameplay.draw_validation(self)
