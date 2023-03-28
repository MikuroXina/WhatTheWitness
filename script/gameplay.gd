extends Node

const PUZZLE_FOLDER = 'res://puzzles/'
const ALLOW_CUSTOM_LEVELS = true

var puzzle_name = ""
var playing_custom_puzzle: bool
var puzzle_path: String
var puzzle: Graph.Puzzle
var solution: SolutionLine
var __canvas: Visualizer.PuzzleCanvas
var validator: Validation.Validator
var validation_elasped_time: float
var background_texture: Texture2D = null
var loaded_from_command_line: bool
var mouse_speed = 1.0

func get_absolute_puzzle_path() -> String:
	return PUZZLE_FOLDER + puzzle_name


func load_custom_level(level_path):
	if ALLOW_CUSTOM_LEVELS:
		get_tree().change_scene_to_packed(load("res://main.tscn"))
		puzzle_path = level_path
		playing_custom_puzzle = true
		update_mouse_speed()


func drag_custom_levels(files):
	if len(files) == 0:
		return
	var file = files[0]
	if file.to_lower().ends_with('.wit'):
		Gameplay.load_custom_level(file)


func update_mouse_speed():
	var setting = SaveData.get_setting()
	if 'mouse_speed' in setting:
		mouse_speed = exp(setting['mouse_speed'])
	else:
		mouse_speed = 1.0


func init_canvas(canvas: Visualizer.PuzzleCanvas, viewport_size: Vector2):
	__canvas = canvas
	__canvas.current_puzzle = puzzle
	__canvas.normalize_view(viewport_size)


func draw_solution(target: Control):
	if __canvas == null:
		return
	__canvas.draw_solution(target, solution, validator, validation_elasped_time)


func draw_validation(target: Control):
	if __canvas == null:
		return null
	return __canvas.draw_validation(target, puzzle, validator, validation_elasped_time)


func draw_additive_layer(target: Control):
	if __canvas == null:
		return null
	__canvas.draw_additive_layer(target, solution)


func screen_to_world(screen_position: Vector2) -> Vector2:
	return __canvas.screen_to_world(screen_position)


func try_continue_solution(motion: Vector2):
	solution.try_continue_solution(puzzle, motion / __canvas.view_scale)
