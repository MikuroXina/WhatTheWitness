extends Node2D

@onready var checkbox = $MarginContainer/VBoxContainer/CheckBox
@onready var mapScene = load("res://level_map.tscn")

func _ready():
	SaveData.load_all()
	var setting = SaveData.get_setting()
	if 'skip_spoiler' in setting:
		get_tree().change_scene_to_packed(mapScene)


func _on_RichTextLabel2_meta_clicked(meta):
	OS.shell_open(meta)


func _on_ContinueButton_pressed():
	if checkbox.is_pressed():
		var setting = SaveData.get_setting()
		setting['skip_spoiler'] = 1
		SaveData.save_setting(setting)
	get_tree().change_scene_to_packed(mapScene)


func _on_ExitButton_pressed():
	get_tree().change_scene_to_packed(load("res://menu_main.tscn"))
