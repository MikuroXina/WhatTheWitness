extends Node2D

@onready var puzzle_placeholders = $Menu/View/PuzzlePlaceHolders
@onready var extra_menu = $SideMenu/Extra
@onready var view = $Menu/View
@onready var clear_save_button = $SideMenu/Extra/ClearSaveButton
@onready var line_map = $Menu/View/LinesMap
@onready var puzzle_counter_text = $SideMenu/PuzzleCounter
@onready var menu_bar_button = $SideMenu/MenuBarButton
@onready var loading_cover = $LoadingCover

enum LAYER {
	LINE,
	LIGHT,
	GADGET
}

enum SOURCE {
	LINE,
	LIGHT,
	AND_GATE,
	OR_GATE,
	EMITTER
}

const PUZZLE_DIR = "res://puzzles"

const UNLOCK_ALL_PUZZLES = false
const LOADING_BATCH_SIZE = 10

const DIR_X = [-1, 0, 1, 0]
const DIR_Y = [0, -1, 0, 1]

func list_files(path: String) -> Dictionary:
	var files = {}
	var dir = DirAccess.open(path)
	if not dir:
		print("failed to access to %s" % path)
		return files
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file.is_empty():
			break
		if file in ['.', '..']:
			continue
		files[file] = true
	return files

func _ready():
	loading_cover.visible = true
	# puzzle_placeholders.hide()
	SaveData.load_all()

	var files = list_files(PUZZLE_DIR)
	var placeholders = puzzle_placeholders.get_children()
	MenuData.puzzle_grid_pos.clear()
	MenuData.grid_pos_puzzle.clear()
	var pos_points = {}
	for placeholder in placeholders:
		if placeholder.text.begins_with('$'):
			var cell_pos = Vector2i((placeholder.get_position() / 96).round())
			var int_cell_pos = [cell_pos.x, cell_pos.y - 1]
			pos_points[int_cell_pos] = int(placeholder.text.substr(1))
			placeholder.get_parent().remove_child(placeholder)
		elif placeholder.text.begins_with('#'):
			var cell_pos = Vector2i((placeholder.get_position() / 96).round())
			var int_cell_pos = [cell_pos.x, cell_pos.y]
			var prefix = placeholder.text.substr(1)
			var child_pos = placeholder.get_position()
			for puzzle_file in files:
				if puzzle_file.begins_with(prefix):
					var node = placeholder.duplicate()
					node.text = puzzle_file.substr(0, len(puzzle_file) - 4)
					node.set_position(child_pos)
					placeholder.get_parent().add_child(node)
					var pts_text = puzzle_file.substr(puzzle_file.find('(') + 1)
					pos_points[int_cell_pos] = int(pts_text.substr(0, pts_text.find(')')))
					child_pos += Vector2(96, 0)
					int_cell_pos = [int_cell_pos[0] + 1, int_cell_pos[1]]
			placeholder.get_parent().remove_child(placeholder)
	placeholders = puzzle_placeholders.get_children()
	var processed_placeholder_count = 0
	var total_placeholder_count = 0
	for placeholder in placeholders:
		var puzzle_file = placeholder.text + '.wit'
		if not placeholder.text.begins_with('$') and puzzle_file in files:
			total_placeholder_count += 1
	for placeholder in placeholders:
		var puzzle_file = placeholder.text + '.wit'
		if placeholder.text.begins_with('$') or puzzle_file not in files:
			continue

		var target = MenuData.PUZZLE_PREVIEW_PREFAB.instantiate()
		MenuData.puzzle_preview_panels[puzzle_file] = target
		view.add_child(target)
		target.set_position(placeholder.get_position())

		var cell_pos: Vector2i = Vector2i((target.global_position / 96).round())
		if puzzle_file in MenuData.puzzle_grid_pos:
			print('[Warning] Duplicated puzzle %s on' % puzzle_file, cell_pos)
		MenuData.puzzle_grid_pos[puzzle_file] = cell_pos

		var int_cell_pos = [cell_pos.x, cell_pos.y]
		if int_cell_pos in MenuData.grid_pos_puzzle:
			print('[Warning] Multiple puzzles (%s and %s) on the same grid position (%d, %d)' % [MenuData.grid_pos_puzzle[int_cell_pos], puzzle_file, cell_pos.x, cell_pos.y])
		MenuData.grid_pos_puzzle[int_cell_pos] = puzzle_file

		MenuData.puzzle_points[puzzle_file] = 0
		if int_cell_pos in pos_points:
			MenuData.puzzle_points[puzzle_file] = pos_points[int_cell_pos]
		target.points = MenuData.puzzle_points[puzzle_file]

		target.show_puzzle(puzzle_file, get_light_state(cell_pos))
		placeholder.get_parent().remove_child(placeholder)

		if processed_placeholder_count % LOADING_BATCH_SIZE == 0:
			puzzle_counter_text.text = '[right]loading puzzle: %d / %d[/right] ' % [processed_placeholder_count, total_placeholder_count]
			await RenderingServer.frame_post_draw

		processed_placeholder_count += 1
	update_light(true)
	Gameplay.update_mouse_speed()

func get_light_state(pos: Vector2i) -> bool:
	return line_map.get_cell_source_id(LAYER.LIGHT, pos) > 0

func update_counter():
	var puzzle_count = 0
	var solved_count = 0
	var score = 0
	var total_score = 0
	for puzzle_file in MenuData.puzzle_grid_pos:
		if SaveData.puzzle_solved(puzzle_file):
			solved_count += 1
			score += MenuData.puzzle_points[puzzle_file]
		puzzle_count += 1
		total_score += MenuData.puzzle_points[puzzle_file]
	if total_score > 0:
		puzzle_counter_text.text = '[right]%d / %d (%d / %d pts)[/right] ' % [solved_count, puzzle_count, score, total_score]
	else:
		puzzle_counter_text.text = '[right]%d / %d[/right] ' % [solved_count, puzzle_count]
func get_gadget_direction(tile_map: TileMap, pos: Vector2i) -> Vector2i:
	var tile_data = tile_map.get_cell_tile_data(LAYER.GADGET, pos)
	if tile_data.transpose:
		return Vector2i(0, -1) if tile_data.flip_v else Vector2i(0, 1)

	return Vector2i(-1, 0) if tile_data.flip_h else Vector2i(1, 0)

func update_light(first_time=false):
	var stack = []
	for puzzle_file in MenuData.puzzle_grid_pos:
		var pos = MenuData.puzzle_grid_pos[puzzle_file]
		if(SaveData.puzzle_solved(puzzle_file)):
			stack.append(pos)
			var atlas = line_map.get_cell_atlas_coords(LAYER.LINE, pos)
			line_map.set_cell(LAYER.LIGHT, pos, SOURCE.LIGHT, atlas)

	while not stack.is_empty():
		var pos = stack.pop_back()
		# print('Visiting ', pos)
		var deltas = []
		for dir in range(4):
			var delta = Vector2i(DIR_X[dir], DIR_Y[dir])
			var new_pos = pos + delta
			if line_map.get_cell_source_id(LAYER.LINE, new_pos) == -1:
				continue
			deltas.append(delta)
			if line_map.get_cell_source_id(LAYER.GADGET, new_pos) == SOURCE.OR_GATE:
				deltas.append(delta + get_gadget_direction(line_map, new_pos))
			if line_map.get_cell_source_id(LAYER.GADGET, new_pos) == SOURCE.AND_GATE:
				var non_activated_neighbor = 0
				for dir2 in range(4):
					var new_pos2 = new_pos + Vector2i(DIR_X[dir2], DIR_Y[dir2])
					if (line_map.get_cell_source_id(LAYER.LINE, new_pos2) != -1 and not get_light_state(new_pos2)):
						non_activated_neighbor += 1
				if non_activated_neighbor == 1:
					deltas.append(delta + get_gadget_direction(line_map, new_pos))
		for delta in deltas:
			var new_pos = pos + delta
			if get_light_state(new_pos):
				continue
			var atlas = line_map.get_cell_atlas_coords(LAYER.LINE, new_pos)
			line_map.set_cell(LAYER.LIGHT, new_pos, SOURCE.LIGHT, atlas)
			if (
				line_map.get_cell_source_id(LAYER.GADGET, new_pos) == -1 and
				MenuData.get_puzzle_on_cell(new_pos) == null
			):
				stack.append(new_pos)
	var puzzles_to_unlock = []
	for puzzle_file in MenuData.puzzle_grid_pos:
		var pos = MenuData.puzzle_grid_pos[puzzle_file]
		if (UNLOCK_ALL_PUZZLES or get_light_state(pos)) and not MenuData.puzzle_preview_panels[puzzle_file].puzzle_unlocked:
			puzzles_to_unlock.append(puzzle_file)
	var processed_rendering_count = 0
	for puzzle_file in puzzles_to_unlock:
		MenuData.puzzle_preview_panels[puzzle_file].update_puzzle(true)
		if first_time and processed_rendering_count % LOADING_BATCH_SIZE == 0:
			puzzle_counter_text.text = '[right]rendering puzzle: %d / %d[/right] ' % [processed_rendering_count, len(puzzles_to_unlock)]
			await RenderingServer.frame_post_draw
		processed_rendering_count += 1
	if first_time:
		loading_cover.visible = false
		MenuData.can_drag_map = true
		update_counter()

func _on_clear_save_button_pressed():
	if clear_save_button.text != 'Are you sure?':
		clear_save_button.text = 'Are you sure?'
		return

	SaveData.clear()
	clear_save_button.text = 'Clear Save'
	for puzzle_name in MenuData.puzzle_preview_panels:
		MenuData.puzzle_preview_panels[puzzle_name].update_puzzle(false)
	update_light()


func _on_menu_bar_button_mouse_entered():
	menu_bar_button.modulate = Color(menu_bar_button.modulate, 0.5)

func _on_menu_bar_button_mouse_exited():
	menu_bar_button.modulate = Color(menu_bar_button.modulate, 1.0)

func _on_menu_bar_button_pressed():
	get_tree().change_scene_to_packed(load("res://menu_main.tscn"))
