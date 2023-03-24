extends Node2D

@onready var custom_level_button = $CenterContainer/MarginContainer/VBoxContainer/CustomLevelButton

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://warning_scene.tscn")


func _ready():
	if (!Gameplay.loaded_from_command_line):
		var args = OS.get_cmdline_args()
		Gameplay.drag_custom_levels(args)
		Gameplay.loaded_from_command_line = true
	if (!Gameplay.ALLOW_CUSTOM_LEVELS):
		custom_level_button.visible = false

func _enter_tree():
	if (Gameplay.ALLOW_CUSTOM_LEVELS):
		get_viewport().files_dropped.connect(Gameplay.drag_custom_levels)

func _exit_tree():
	if (Gameplay.ALLOW_CUSTOM_LEVELS):
		get_viewport().files_dropped.disconnect(Gameplay.drag_custom_levels)


func _on_custom_level_button_pressed():
	get_tree().change_scene_to_file("res://custom_level_scene.tscn")


func _on_CreditsButton_pressed():
	get_tree().change_scene_to_file("res://credit_scene.tscn")


func _on_SettingButton_pressed():
	get_tree().change_scene_to_file("res://setting_scene.tscn")
