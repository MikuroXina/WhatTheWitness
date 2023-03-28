class_name DecoratorResponse
extends Object

const Decorator = preload("decorator.gd")

enum State {
	NORMAL = 0,
	ERROR = 1,
	ELIMINATED = 2,
	CONVERTED = 3,
	NO_ELIMINATION_CHANGES = -1,
}

var decorator: Decorator
var rule: String
var color = null
var pos: Vector2
var vertex_index: int
var state: State
var state_before_elimination: State
var clone_source_decorator: Decorator
var index: int

func is_error() -> bool:
	return state == State.ERROR

func is_eliminated() -> bool:
	return state == State.ELIMINATED

func is_error_before_elimination() -> bool:
	return state_before_elimination == State.ERROR

func has_no_elimination_changes() -> bool:
	return state_before_elimination == State.NO_ELIMINATION_CHANGES

func eliminate():
	state_before_elimination = state
	state = State.NORMAL

func mark_as_eliminated():
	state = State.ELIMINATED

func mark_as_error():
	state = State.ERROR

func mark_as_error_before_elimination():
	state_before_elimination = State.ERROR
