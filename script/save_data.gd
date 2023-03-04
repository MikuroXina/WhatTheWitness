extends Node

var saved_solutions = {}
const SAVE_PATH = "user://savegame.save"
const LEGACY_SAVE_PATH = "/Godot/app_userdata/WitCup10/savegame.save"

func puzzle_solved(puzzle_name):
	return puzzle_name in saved_solutions

func update(puzzle_name: String, solution_string: String):
	saved_solutions[puzzle_name] = solution_string
	if !(('$' + puzzle_name) in saved_solutions):
		var time = Time.get_datetime_dict_from_system()
		saved_solutions['$' + puzzle_name] = '%04d%02d%02d.%02d:%02d:%02d' % [
			time.year, time.month, time.day, time.hour, time.minute, time.second]
	save_all()

func save_all():
	var save_game = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if ('&checksum' in saved_solutions):
		saved_solutions.erase('&checksum')
	var line = JSON.stringify(saved_solutions)
	# var checksum = (line + 'ArZgL!.zVx-.').md5_text()
	# line = ('{"&checksum":"%s",' % checksum) + line.substr(1)
	save_game.store_line(line)
	save_game.close()

func load_all():
	if not FileAccess.file_exists(SAVE_PATH):
		saved_solutions = {}
	else:
		var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var line = save_file.get_line()
		if (line != ''):
			var test_json_conv = JSON.new()
			test_json_conv.parse(line)
			saved_solutions = test_json_conv.get_data()
		save_file = null
	# load legacy save
	var appdata = OS.get_environment('appdata')
	if (appdata != ''):
		var old_save_path = appdata.replace('\\', '/') + LEGACY_SAVE_PATH
		var old_save_file = FileAccess.open(old_save_path, FileAccess.READ)
		if old_save_file == null:
			return
		var line = old_save_file.get_line()
		if (line != ''):
			var test_json_conv = JSON.new()
			test_json_conv.parse(line)
			var saved_solutions2 = test_json_conv.get_data()
			for solution in saved_solutions2:
				var key = solution
				if ('(' in solution and ')' in solution):  # legacy name fixes.
					key = solution.split('(')[0] + solution.split(')')[1]
				if not (key in saved_solutions):
					saved_solutions[key] = saved_solutions2[solution]
		save_all()
		old_save_file = null
		DirAccess.open(old_save_path).remove(old_save_path)

		var save_file = FileAccess.open(old_save_path + '.bak', FileAccess.WRITE)
		save_file.store_string(line)
		save_file = null

func clear():
	var save_file = DirAccess.open(SAVE_PATH)
	if save_file != null:
		save_file.remove(SAVE_PATH)
	saved_solutions = {}

func get_setting():
	load_all()
	var setting = {}
	if ('&setting' in saved_solutions):
		setting = saved_solutions['&setting']
	return setting

func save_setting(setting):
	saved_solutions['&setting'] = setting
	save_all()
