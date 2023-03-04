extends Node2D
@onready var save_text = $TextEdit
@onready var label = $RichTextLabel
@onready var mergeCheckBox = $MergeCheckBox
func _ready():
	save_text.text = ''


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://setting_scene.tscn")


func _on_import_button_pressed():
	if (save_text.text != ''):
		var save_game = File.new()
		save_game.open(SaveData.SAVE_PATH, File.WRITE)
		if (mergeCheckBox.pressed):
			SaveData.load_all()
			var test_json_conv = JSON.new()
			test_json_conv.parse(save_text.text)
			var saved_solutions = test_json_conv.get_data()
			for solution in saved_solutions:
				SaveData.saved_solutions[solution] = saved_solutions[solution]
			SaveData.save_all()
		else:
			save_game.store_line(save_text.text)
		save_game.close()
		save_text.text = ''
		label.text = 'Save file imported!'

