extends Node2D

@onready var view = $View
@onready var level_area_limit = $View/LevelAreaLimit
@onready var line_map = $View/LinesMap
@onready var view_position_start = view.position

const WINDOW_SIZE = Vector2(1024, 600)
const VIEW_ORIGIN = -WINDOW_SIZE / 2

var drag_start = null
var view_delta = Vector2(0, 0)
var view_scale = 1.0

func update_view():
	const EXTRA_MARGIN = Vector2(100, 100)
	var limit_pos = level_area_limit.global_position
	var limit_size = level_area_limit.size
	var min_pos = limit_pos - EXTRA_MARGIN
	var max_pos = limit_pos + limit_size + EXTRA_MARGIN

	view.position = (view_position_start + view_delta).clamp(min_pos, max_pos)
	view.scale = Vector2(view_scale, view_scale)

func _input(event):
	if not MenuData.can_drag_map:
		return

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				view_scale = max(view_scale * 0.8, 0.2097152)
			MOUSE_BUTTON_WHEEL_UP:
				view_scale = min(view_scale * 1.25, 3.0)
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					drag_start = event.position
					view_position_start = view.position
				else:
					view_delta = Vector2(0, 0)
					drag_start = null
	if event is InputEventMouseMotion and drag_start != null:
		view_delta = (event.position - drag_start) / view_scale
		update_view()
