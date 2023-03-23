extends Node2D

@onready var view = $View
@onready var level_area_limit = $View/LevelAreaLimit
@onready var line_map = $View/LinesMap

const window_size = Vector2(1024, 600)
const view_origin = -window_size / 2

var drag_start = null
var view_position_start = null
var view_delta = Vector2(0, 0)
var view_scale = 1.0

func _ready():
	view_position_start = view.position


func update_view():
	const extra_margin = Vector2(100, 100)
	var limit_pos = level_area_limit.global_position
	var limit_size = level_area_limit.size
	var min = limit_pos - extra_margin
	var max = limit_pos + limit_size + extra_margin

	view.position = (view_position_start + view_delta).clamp(min, max)
	view.scale = Vector2(view_scale, view_scale)

func _input(event):
	if (!MenuData.can_drag_map):
		return

	if (event is InputEventMouseButton):
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				view_scale = max(view_scale * 0.8, 0.2097152)
			MOUSE_BUTTON_WHEEL_UP:
				view_scale = min(view_scale * 1.25, 3.0)
			MOUSE_BUTTON_LEFT:
				if (event.pressed):
					drag_start = event.position
					view_position_start = view.position
				else:
					view_delta = Vector2(0, 0)
					drag_start = null
					view_position_start = null
					return
	elif (event is InputEventMouseMotion and drag_start != null):
		view_delta = (event.position - drag_start) / view_scale

	update_view()
