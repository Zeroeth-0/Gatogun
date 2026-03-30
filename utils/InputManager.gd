# utils/InputManager.gd
# Name: INPUT
extends Node

# === MOVEMENT ===
var xAxis: float = 0.0
var yAxis: float = 0.0

# === SHOOTING ===
var fireHold: bool = false
var firing: bool = false
var fireDir: Vector2 = Vector2.UP

# === TIMERS ===
var holdTimer: float = 0.0
const HOLD_LIMIT: float = 0.3

var buffTimer: float = 0.0
var buffActive: bool = false
const BUFF_DURATION: float = 0.5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	xAxis = Input.get_axis("LEFT", "RIGHT")
	yAxis = Input.get_axis("UP", "DOWN")
	_handle_actions(delta)

func _handle_actions(delta: float) -> void:
	if Input.is_action_just_pressed("C"):
		fireDir = Vector2.UP
		buffActive = true
		buffTimer = BUFF_DURATION
	
	if Input.is_action_pressed("C"):
		holdTimer += delta
		fireHold = holdTimer >= HOLD_LIMIT
	else:
		holdTimer = 0.0
		fireHold = false
	
	if buffTimer > 0.0: buffTimer -= delta
	else:
		buffActive = false
		buffTimer = 0.0
	
	firing = buffActive or Input.is_action_pressed("A")
