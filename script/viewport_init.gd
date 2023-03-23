class_name PuzzleViewport
extends SubViewport

var drawing_controls

func _ready():
	drawing_controls = get_children()

func update_all():
	for child in drawing_controls:
		child.queue_redraw()

func draw_background():
	var cvitem = Control.new()
	self.add_child(cvitem)
	cvitem.custom_minimum_size = self.size
	cvitem.set_script(preload("res://script/puzzle_background_renderer.gd"))

	await RenderingServer.frame_post_draw

	var vport_img = self.get_texture().get_image()
	vport_img.flip_y()
	var image_texture = ImageTexture.create_from_image(vport_img)
	Gameplay.background_texture = image_texture
	update_all()
