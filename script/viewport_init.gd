class_name PuzzleViewport
extends TextureRect

var drawing_controls

func _ready():
	drawing_controls = get_children()

func update_all():
	for child in drawing_controls:
		child.update()

func draw_background():
	var cvitem = Control.new()
	self.add_child(cvitem)
	cvitem.custom_minimum_size = self.size
	cvitem.set_script(load("res://script/puzzle_background_renderer.gd"))

	await RenderingServer.frame_post_draw

	Gameplay.background_texture = self
	update_all()
