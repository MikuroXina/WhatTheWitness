extends Node2D

var mouse_start_position = null
var is_drawing_solution = false
@onready var drawing_target = $MarginContainer/PuzzleRegion/Viewport
var level_map = null
@onready var left_arrow_button = $LeftArrowButton
@onready var right_arrow_button = $RightArrowButton
var menu_bar_button = null
var puzzle_counter_text = null
@onready var back_button = $BackButton
@onready var viewport: PuzzleViewport = $MarginContainer/PuzzleRegion/Viewport
var loaded = false
var solver = null

func _ready():
	if (Gameplay.playing_custom_puzzle):
		load_puzzle(Gameplay.puzzle_path)

func load_puzzle(puzzle_path):
	if (!Gameplay.playing_custom_puzzle):
		level_map = $"/root/LevelMap"
		menu_bar_button = $"/root/LevelMap/SideMenu/MenuBarButton"
		puzzle_counter_text = $"/root/LevelMap/SideMenu/PuzzleCounter"
	Gameplay.background_texture = null
	Gameplay.puzzle_path = puzzle_path
	Gameplay.puzzle = Graph.load_from_xml(Gameplay.puzzle_path)
	if (!Gameplay.playing_custom_puzzle and Gameplay.puzzle_name in SaveData.saved_solutions):
		Gameplay.solution = SolutionLine.load_from_string(SaveData.saved_solutions[Gameplay.puzzle_name], Gameplay.puzzle)
		Gameplay.validator = Validation.Validator.new()
		if (Gameplay.validator.validate(Gameplay.puzzle, Gameplay.solution)):
			Gameplay.solution.validity = 1
			Gameplay.validation_elasped_time = 10.0 # skip animations
		else:
			Gameplay.solution.validity = -1 # maybe the problem is changed
		left_arrow_button.show()
		right_arrow_button.show()
	else:
		Gameplay.validator = null
		Gameplay.solution = SolutionLine.new()
		hide_left_arrow_button()
		hide_right_arrow_button()
	Gameplay.canvas = Visualizer.PuzzleCanvas.new()
	Gameplay.canvas.current_puzzle = Gameplay.puzzle
	Gameplay.canvas.normalize_view(viewport.size, 0.95, 0.8)
	var back_color = Gameplay.puzzle.background_color
	var front_color = Gameplay.puzzle.line_color
	$ColorRect.color = back_color
	left_arrow_button.modulate = Color(front_color.r, front_color.g, front_color.b, left_arrow_button.modulate.a)
	right_arrow_button.modulate = Color(front_color.r, front_color.g, front_color.b, right_arrow_button.modulate.a)
	viewport.draw_background()
	loaded = true
	back_button.modulate = front_color
	if (Gameplay.playing_custom_puzzle):
		hide_left_arrow_button()
		hide_right_arrow_button()
	else:
		menu_bar_button.modulate = Color(front_color.r, front_color.g, front_color.b, menu_bar_button.modulate.a)
		puzzle_counter_text.modulate = front_color
		# test if there are previous puzzles
		var puzzle_grid_pos = MenuData.puzzle_grid_pos[Gameplay.puzzle_name]
		if (MenuData.get_unlocked_puzzle_on_cell(puzzle_grid_pos - Vector2i(1, 0)) != null):
			left_arrow_button.show()
		if (MenuData.get_unlocked_puzzle_on_cell(puzzle_grid_pos + Vector2i(1, 0)) != null):
			right_arrow_button.show()

func _process(delta):
	if (loaded):
		if (Gameplay.validator != null):
			Gameplay.validation_elasped_time += delta
		viewport.update_all()

func resizable_wrap_mouse_position(pos):
	var current_window_size = get_window().size
	var additional_scale = current_window_size / Visualizer.initial_viewport_size
	additional_scale = min(additional_scale.x, additional_scale.y)
	var margin = (current_window_size - Visualizer.initial_viewport_size * additional_scale) / 2
	Input.warp_mouse(pos * additional_scale + margin)

func _input(event):
	if (not loaded):
		return
	if (event is InputEventMouseButton and event.is_pressed()):
		var panel_start_pos = drawing_target.get_global_rect().position
		var screen_position = event.position - panel_start_pos
		if (is_drawing_solution):
			if (Gameplay.solution.is_completed(Gameplay.puzzle)):
				Gameplay.solution.progress = 1.0
				Gameplay.validator = Validation.Validator.new()
				if (Gameplay.validator.validate(Gameplay.puzzle, Gameplay.solution)):
					Gameplay.solution.validity = 1
					if (!Gameplay.playing_custom_puzzle):
						SaveData.update(Gameplay.puzzle_name, Gameplay.solution.save_to_string(Gameplay.puzzle))
						if (Gameplay.puzzle_name in MenuData.puzzle_preview_panels):
							MenuData.puzzle_preview_panels[Gameplay.puzzle_name].update_puzzle()
						level_map.update_counter()
					right_arrow_button.show()
					left_arrow_button.show()
				else:
					Gameplay.solution.validity = -1
				Gameplay.validation_elasped_time = 0.0
			is_drawing_solution = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			if (mouse_start_position != null):
				resizable_wrap_mouse_position(mouse_start_position + panel_start_pos)
				mouse_start_position = null
			if (len(Gameplay.solution.state_stack) == 1):
				Gameplay.solution.started = false
		elif (Gameplay.solution.try_start_solution_at(Gameplay.puzzle, Gameplay.canvas.screen_to_world(screen_position))):
			Gameplay.validator = null
			mouse_start_position = screen_position
			is_drawing_solution = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if (event is InputEventMouseMotion):
		if (is_drawing_solution):
			var split = 5
			for i in range(split):
				Gameplay.solution.try_continue_solution(Gameplay.puzzle,
				event.relative * Visualizer.UPSAMPLING_FACTOR / Gameplay.canvas.view_scale / split)
	if (event is InputEventKey):
		if (not event.pressed):
			return
		if (event.keycode == KEY_ESCAPE):
			back_to_menu()
		elif (event.keycode == KEY_LEFT and left_arrow_button.visible):
			_on_left_arrow_button_pressed()
		elif (event.keycode == KEY_RIGHT and right_arrow_button.visible):
			_on_right_arrow_button_pressed()


func back_to_menu():
	if (!Gameplay.playing_custom_puzzle):
		is_drawing_solution = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		loaded = false
		level_map.update_light()
		$"/root/LevelMap/Menu".show()
		hide()
		MenuData.can_drag_map = true
		menu_bar_button.modulate = Color.WHITE
		puzzle_counter_text.modulate = Color.WHITE
	else:
		get_tree().change_scene_to_packed(load("res://custom_level_scene.tscn"))

func switch_puzzle(delta_pos: Vector2i):
	if (Gameplay.playing_custom_puzzle):
		back_to_menu()
		return
	var puzzle_grid_pos = MenuData.puzzle_grid_pos[Gameplay.puzzle_name]
	var new_puzzle_name = MenuData.get_puzzle_on_cell(puzzle_grid_pos + delta_pos)
	if (new_puzzle_name != null):
		is_drawing_solution = false
		Gameplay.puzzle_name = new_puzzle_name
		Gameplay.playing_custom_puzzle = false
		load_puzzle(Gameplay.PUZZLE_FOLDER + Gameplay.puzzle_name)
	else:
		back_to_menu()

func _on_back_button_pressed():
	back_to_menu()

func _on_right_arrow_button_mouse_entered():
	right_arrow_button.modulate = Color(right_arrow_button.modulate.r, right_arrow_button.modulate.g, right_arrow_button.modulate.b, 0.5)

func _on_right_arrow_button_mouse_exited():
	right_arrow_button.modulate = Color(right_arrow_button.modulate.r, right_arrow_button.modulate.g, right_arrow_button.modulate.b, 1.0)

func _on_left_arrow_button_mouse_entered():
	left_arrow_button.modulate = Color(left_arrow_button.modulate.r, left_arrow_button.modulate.g, left_arrow_button.modulate.b, 0.5)

func _on_left_arrow_button_mouse_exited():
	left_arrow_button.modulate = Color(left_arrow_button.modulate.r, left_arrow_button.modulate.g, left_arrow_button.modulate.b, 1.0)

func _on_right_arrow_button_pressed():
	switch_puzzle(Vector2i(1, 0))

func _on_left_arrow_button_pressed():
	switch_puzzle(Vector2i(-1, 0))

func hide_right_arrow_button():
	_on_right_arrow_button_mouse_exited()
	right_arrow_button.hide()

func hide_left_arrow_button():
	_on_left_arrow_button_mouse_exited()
	left_arrow_button.hide()

func _on_back_button_mouse_entered():
	back_button.modulate = Color(back_button.modulate.r, back_button.modulate.g, back_button.modulate.b, 0.5)

func _on_back_button_mouse_exited():
	back_button.modulate = Color(back_button.modulate.r, back_button.modulate.g, back_button.modulate.b, 1.0)
