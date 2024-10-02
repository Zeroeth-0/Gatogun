extends Node

# Axis
var xAxis
var yAxis

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	d_pad()

func d_pad():
	xAxis = Input.get_axis("LEFT", "RIGHT")
	yAxis = Input.get_axis("UP", "DOWN")
