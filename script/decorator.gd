extends Node

var color = null
var angle: float = 0.0
var additional_scale: float = 1.0


func draw_foreground(_canvas, _owner, _owner_type: int, _puzzle: Graph.Puzzle):
	pass

func draw_below_solution(_canvas, _owner, _owner_type, _puzzle, _solution):
	pass

func draw_above_solution(_canvas, _owner, _owner_type, _puzzle, _solution):
	pass

func draw_additive_layer(_canvas, _owner, _owner_type, _puzzle, _solution):
	pass

func post_load_state(_puzzle, _solution_state):
	pass
