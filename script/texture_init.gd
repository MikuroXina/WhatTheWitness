extends TextureRect


func _ready() -> void:
	self.texture = $"../SubViewport".get_texture()
