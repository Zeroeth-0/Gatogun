extends Node

# Movement
var xAxis: float
var yAxis: float
var bigMode: bool = false

# Firing
var fireHold: bool = false
var firing: bool = false
var fireDir: Vector2 = Vector2.UP

# Timer
var holdTimer: float = 0.0
var holdLimit: float = 0.3
var buffTimer: float = 0.0
var buffYes: bool = false

func _process(delta):
	d_pad()
	if !bigMode: action_input(delta)
	else: for bullet in get_tree().get_nodes_in_group("Fire"): bullet.queue_free()
	
	if Input.is_action_just_pressed("B") && SCORE.isFever:
		buffYes = false
		firing = false
		fireHold = false
		bigMode = true
	if !SCORE.isFever: bigMode = false

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
	
	if Input.is_action_just_pressed("C"):
		buffYes = true
		buffTimer = 0.1
	
	if buffTimer > 0: buffTimer -= delta
	else:
		buffYes = false
		buffTimer = 0.0
	
	firing = buffYes or Input.is_action_pressed("A")
	
