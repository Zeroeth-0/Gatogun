extends Node

# Movement
var xAxis: float
var yAxis: float

# Firing
var fireX: float
var fireY: float
var fireHold: bool = false

# Timer
var holdTimer: float = 0.0
var holdLimit: float = 0.1

func _physics_process(delta):
	d_pad()
	action(delta)
	print(fireHold)
	print(fireX, fireY)

# D-Pad Movement
func d_pad():
	xAxis = Input.get_axis("LEFT", "RIGHT")
	yAxis = Input.get_axis("UP", "DOWN")

# Action Firing
func action(delta):
	fireX = Input.get_axis("Y", "A")
	fireY = Input.get_axis("X", "B")
	
	if Input.is_action_pressed("A") or Input.is_action_pressed("B") or Input.is_action_pressed("Y") or Input.is_action_pressed("X"):
		holdTimer += delta
		fireHold = holdTimer >= holdLimit
	else:
		holdTimer = 0.0
		fireHold = false
