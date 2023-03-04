extends Control

func _draw():
	if (Gameplay.background_texture == null):
		return
	if (Gameplay.canvas == null):
		return

	Gameplay.canvas.draw_additive_layer(self, Gameplay.solution)
