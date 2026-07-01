# source/UI/menu_navigator.gd
class_name MenuNavigator
extends Node

signal selection_changed(new_index: int)
signal confirmed(index: int)
signal cancelled()
signal start_pressed()

@export var option_count: int = 0
@export var is_horizontal: bool = false
@export var init_delay: float = 0.20
@export var rep_delay: float = 0.10
@export var deadzone: float = 0.12

var selected: int = 0
var can_interact: bool = false

var _rep_timer: float = 0.0
var _last_dir: int = 0
var _first_frame: bool = true

func _process(delta: float) -> void:
	if not can_interact: return
	if _first_frame:
		_first_frame = false
		return
	_handle_movement(delta)
	_handle_actions()

func _handle_movement(delta: float) -> void:
	var axis_val := INPUT.xAxis if is_horizontal else INPUT.yAxis
	var direction: int = 0

	if axis_val > deadzone: direction = 1
	elif axis_val < -deadzone: direction = -1

	if direction != _last_dir:
		if direction != 0:
			_move_selection(direction)
			_rep_timer = init_delay
		else: _rep_timer = 0.0
		_last_dir = direction

	if direction != 0 and _rep_timer > 0.0:
		_rep_timer -= delta
		if _rep_timer <= 0.0:
			_move_selection(direction)
			_rep_timer = rep_delay

func _handle_actions() -> void:
	if Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A"):
		confirmed.emit(selected)
	elif Input.is_action_just_pressed("B"):
		cancelled.emit()
	elif Input.is_action_just_pressed("Start"):
		start_pressed.emit()

func _move_selection(dir: int) -> void:
	if option_count <= 0: return
	if dir > 0: selected = (selected + 1) % option_count
	else: selected = (selected - 1 + option_count) % option_count
	selection_changed.emit(selected)
