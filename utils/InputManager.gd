extends Node

# Axis for movement
var xAxis: float
var yAxis: float

# Axis for firing
var fire_xAxis: float = 0
var fire_yAxis: float = 0

# Press (track the action buttons)
var aPress: bool = false
var bPress: bool = false
var yPress: bool = false
var xPress: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	d_pad()
	action()

# Movement control (D-pad)
func d_pad():
	xAxis = Input.get_axis("LEFT", "RIGHT")
	yAxis = Input.get_axis("UP", "DOWN")

# Action buttons control (A, B, Y, X for shooting)
func action():
	pass
