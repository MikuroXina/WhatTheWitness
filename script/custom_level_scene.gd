extends Node2D

@onready var info_text = $TextureRect/RichTextLabel2


func _on_files_dropped(files: PackedStringArray):
	if files.is_empty():
		return
	var file = files[0]
	if file.to_lower().ends_with('.wit'):
		info_text.text = '[center]Loading %s ...[/center]' % file
		Gameplay.load_custom_level(file)
	else:
		info_text.text = '[center]Please drag a file with extension *.wit![/center]'


func _on_back_button_pressed():
	get_tree().change_scene_to_packed(load("res://menu_main.tscn"))
