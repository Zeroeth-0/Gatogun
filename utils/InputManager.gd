extends Node

# === MOVIMIENTO (D-PAD) ===
var xAxis: float = 0.0
var yAxis: float = 0.0

# === DISPARO Y BOMBA ===
var fireHold: bool = false
var firing: bool = false
var fireDir: Vector2 = Vector2.UP

# === TIMERS ===
var holdTimer: float = 0.0
var holdLimit: float = 0.3
var buffTimer: float = 0.0
var buffActive: bool = false

func _process(delta: float) -> void:
	_handle_dpad()
	_handle_actions(delta)
	
	if get_tree().get_nodes_in_group("Player").size() > 3: get_tree().get_nodes_in_group("Player")[3].queue_free()

# === MOVIMIENTO ANALÓGICO O DIGITAL ===
func _handle_dpad() -> void:
	xAxis = Input.get_axis("LEFT", "RIGHT")
	yAxis = Input.get_axis("UP", "DOWN")

# === DISPARO, HOLD Y BUFF ===
func _handle_actions(delta: float) -> void:
	if Input.is_action_just_pressed("C"):
		fireDir = Vector2.UP
		buffActive = true
		buffTimer = 0.5
	
	if Input.is_action_pressed("C"):
		holdTimer += delta
		fireHold = holdTimer >= holdLimit
	else:
		holdTimer = 0.0
		fireHold = false

	# Control del mini-buff para fuego instantáneo al presionar
	if buffTimer > 0.0: buffTimer -= delta
	else:
		buffActive = false
		buffTimer = 0.0

	# Firing activo si hay buff o se mantiene presionado A
	firing = buffActive or Input.is_action_pressed("A")
