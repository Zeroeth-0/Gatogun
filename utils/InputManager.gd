extends Node

# Movement
var xAxis: float
var yAxis: float

# Firing
var fireHold: bool = false
var firing: bool = false
var fireDir: Vector2 = Vector2.UP

# Timer
var holdTimer: float = 0.0
var holdLimit: float = 0.3

func _process(delta):
	d_pad()
	action_input(delta)

# D-Pad Movement
func d_pad():
	xAxis = Input.get_axis("LEFT", "RIGHT")
	yAxis = Input.get_axis("UP", "DOWN")

# Action Input and Button Checks
func action_input(delta):
	# Update fireDir based on buttonActive
	if Input.is_action_just_pressed("C"): fireDir = Vector2.UP

	# Firing logic
	if Input.is_action_pressed("C"):
		holdTimer += delta
		fireHold = holdTimer >= holdLimit
	else:
		holdTimer = 0.0
		fireHold = false
	
	firing = Input.is_action_just_pressed("C") or Input.is_action_pressed("A")
