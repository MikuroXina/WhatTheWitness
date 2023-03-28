extends Node2D

@onready var clear_save_button = $MarginContainer/VBoxContainer/ClearProgressButton
@onready var mouse_speed_text = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/MouseSpeedText
@onready var mouse_speed_slider = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/MouseSpeedSlider


func _ready():
	var setting = SaveData.get_setting()
	if ('mouse_speed' in setting):
		mouse_speed_slider.value = setting['mouse_speed']


func _on_BackButton_pressed():
	get_tree().change_scene_to_packed(load("res://menu_main.tscn"))


func _on_ImportSaveButton_pressed():
	get_tree().change_scene_to_packed(preload("res://import_save_scene.tscn"))


func _on_ExportSaveButton_pressed():
	get_tree().change_scene_to_packed(preload("res://export_save_scene.tscn"))


func _on_ClearProgressButton_pressed():
	if clear_save_button.text != 'Are you sure?':
		clear_save_button.text = 'Are you sure?'
		return

	SaveData.clear()
	clear_save_button.text = 'Save cleared.'
	if MenuData.puzzle_preview_panels == null:
		return
	for puzzle_name in MenuData.puzzle_preview_panels:
		if MenuData.puzzle_preview_panels[puzzle_name] != null:
			MenuData.puzzle_preview_panels[puzzle_name].update_puzzle(false)


func _on_MouseSpeedSlider_value_changed(value):
	var new_speed = exp(mouse_speed_slider.value)
	mouse_speed_text.text = '[center]%.2f[/center]' % new_speed
	var setting = SaveData.get_setting()
	setting['mouse_speed'] = mouse_speed_slider.value
	SaveData.save_setting(setting)

