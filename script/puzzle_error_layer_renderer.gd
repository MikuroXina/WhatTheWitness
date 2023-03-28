extends Control

func _draw():
	if Gameplay.background_texture == null:
		return

	var error_transparency = Gameplay.draw_validation(self)
	if error_transparency != null:
		self.modulate = Color(1.0, 1.0, 1.0, error_transparency)
