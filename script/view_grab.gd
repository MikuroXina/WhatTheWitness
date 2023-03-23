extends Node2D

@onready var view = $View
@onready var level_area_limit = $View/LevelAreaLimit
@onready var line_map = $View/LinesMap
var drag_start = null
var window_size = Vector2(1024, 600)
var view_origin = -window_size / 2
var view_scale = 1.0


func update_view():
	const extra_margin = Vector2(100, 100)
	var limit_pos = level_area_limit.global_position
	var limit_size = level_area_limit.size
	var min = limit_pos - extra_margin
	var max = limit_pos + limit_size + extra_margin
	view_origin = view_origin.clamp(min, max)
	view.position = window_size / 2 + view_origin
	view.scale = Vector2(view_scale, view_scale)

func _input(event):
	if (!MenuData.can_drag_map):
		return

	var needsUpdate = false
	if (event is InputEventMouseButton):
		if (event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			view_scale = max(view_scale * 0.8, 0.2097152)
			needsUpdate = true
		elif (event.button_index == MOUSE_BUTTON_WHEEL_UP):
			view_scale = min(view_scale * 1.25, 3.0)
			needsUpdate = true
		elif (event.button_index == MOUSE_BUTTON_LEFT):
			if (event.pressed):
				drag_start = event.position
			else:
				drag_start = null
	elif (event is InputEventMouseMotion and drag_start != null):
		view_origin += (event.position - drag_start) / view_scale
		needsUpdate = true

	if (needsUpdate):
		update_view()
