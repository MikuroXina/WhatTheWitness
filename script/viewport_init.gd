class_name PuzzleViewport
extends TextureRect

var drawing_controls

func _ready():
	drawing_controls = get_children()

func update_all():
	for child in drawing_controls:
		child.queue_redraw()

func draw_background():
	var vport = SubViewport.new()
	vport.size = self.size
	self.add_child(vport)
	var cvitem = Control.new()
	vport.add_child(cvitem)
	cvitem.custom_minimum_size = vport.size
	cvitem.set_script(preload("res://script/puzzle_background_renderer.gd"))

	await RenderingServer.frame_post_draw

	var vport_img = vport.get_texture().get_image()
	vport_img.flip_y()
	remove_child(vport)
	vport.queue_free()
	var image_texture = ImageTexture.create_from_image(vport_img)
	Gameplay.background_texture = image_texture
	self.texture = image_texture
	update_all()
