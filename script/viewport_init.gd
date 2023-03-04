class_name PuzzleViewport
extends SubViewport

var drawing_controls

func _ready():
	drawing_controls = get_children()

func update_all():
	for child in drawing_controls:
		child.update()

func draw_background():
	var vport = SubViewport.new()
	vport.size = self.size
	# vport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# vport.msaa = SubViewport.MSAA_4X # useless for 2D
	self.add_child(vport)

	var cvitem = Control.new()
	vport.add_child(cvitem)
	cvitem.custom_minimum_size = vport.size
	cvitem.set_script(load("res://script/puzzle_background_renderer.gd"))

	await RenderingServer.frame_post_draw

	var vport_img = vport.get_texture().get_data()
	vport_img.flip_y()
	remove_child(vport)
	vport.queue_free()

	var image_texture = ImageTexture.create_from_image(vport_img)
	Gameplay.background_texture = image_texture
	update_all()
