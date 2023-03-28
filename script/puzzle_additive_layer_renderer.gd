extends Control

func _draw():
	if Gameplay.background_texture == null:
		return

	Gameplay.draw_additive_layer(self)
