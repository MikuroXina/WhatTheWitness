extends Node2D

@onready var save_text = $TextEdit

func _ready():
	if not FileAccess.file_exists(SaveData.SAVE_PATH):
		save_text.text = '(no save found!)'
		return

	var save_game = FileAccess.open(SaveData.SAVE_PATH, FileAccess.READ)
	var line = save_game.get_line()
	save_text.text = line
	save_game.close()


func _on_back_button_pressed():
	get_tree().change_scene_to_packed(preload("res://setting_scene.tscn"))
