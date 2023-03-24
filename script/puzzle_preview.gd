extends Node2D

var enabled = false
@onready var frame = $PuzzlePreview
@onready var visualizer = $PuzzlePreview/PuzzleVisualizer
@onready var parent = $".."
@onready var puzzle_credit_text = $"../../../SideMenu/PuzzleCredits"
@onready var points_label = $PuzzlePreview/PointsLabel
@onready var delete_bar = $PuzzlePreview/PointsLabel/ColorRect

@export var puzzle_name: String = ""
@export var puzzle_unlocked: bool = false
@export var points: int = 0

func show_puzzle(load_puzzle_name, unlocked=true):
	puzzle_name = load_puzzle_name
	puzzle_unlocked = unlocked
	if (unlocked):
		var vport = SubViewport.new()
		vport.size = Vector2(256, 256)
		vport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		# vport.msaa = SubViewport.MSAA_4X # useless for 2D
		self.add_child(vport)
		var cvitem = Control.new()
		vport.add_child(cvitem)
		cvitem.custom_minimum_size = Vector2(256, 256)
		cvitem.name = puzzle_name.replace('.', '|')
		cvitem.set_script(load("res://script/puzzle_renderer.gd"))
		await RenderingServer.frame_post_draw
		var vport_img = vport.get_texture().get_image()
		# vport_img.save_png("res://img/render/%s.png" % cvitem.name.replace('|', '.'))
		remove_child(vport)
		# will the texture be freed?
		vport.queue_free()
		var image_texture = ImageTexture.create_from_image(vport_img)
		visualizer.texture = image_texture
	points_label.text = '[center]%s[/center]' % (
		'' if points == 0 else '1 pt' if points == 1 else '%d pts' % points
	)
	if (SaveData.puzzle_solved(puzzle_name) and points != 0):
		points_label.modulate = Color(1.0, 1.0, 1.0, 0.5)
		delete_bar.visible = true
	else:
		points_label.modulate = Color.WHITE
		delete_bar.visible = false

func update_puzzle(unlocked=true):
	show_puzzle(puzzle_name, unlocked)

func _on_Button_pressed():
	if (not puzzle_unlocked):
		return
	_on_Button_mouse_exited()
	Gameplay.puzzle_name = puzzle_name
	Gameplay.playing_custom_puzzle = false
	$"/root/LevelMap/PuzzleUI".load_puzzle(Gameplay.PUZZLE_FOLDER + puzzle_name)
	$"/root/LevelMap/PuzzleUI".show()
	$"/root/LevelMap/Menu".hide()
	MenuData.can_drag_map = false
	puzzle_credit_text.text = ''

func _on_Button_mouse_entered():
	if (not puzzle_unlocked):
		return
	parent.move_child(self, parent.get_child_count() - 1)
	frame.scale = Vector2(1.2, 1.2)
	MenuData.can_drag_map = false
	puzzle_credit_text.text = '[right] %s [/right]' % Credits.get_full_credit(puzzle_name)


func _on_Button_mouse_exited():
	frame.scale = Vector2(1.0, 1.0)
	MenuData.can_drag_map = true
	puzzle_credit_text.text = ''
