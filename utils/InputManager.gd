extends Node

# Movement
var xAxis: float
var yAxis: float

# Firing
var fireHold: bool = false
var buttonStates: Dictionary = {
	"A": false,
	"B": false,
	"Y": false,
	"X": false
}
enum Buttons { NONE, A, B, Y, X }
var buttonActive: Buttons = Buttons.NONE
var firing: bool = false
var fireDir: Vector2 = Vector2.UP

# Timer
var holdTimer: float = 0.0
var holdLimit: float = 0.3

# List of pressed buttons in order
var buttonOrder: Array = []

func _process(delta):
	d_pad()
	action_input(delta)

# D-Pad Movement
func d_pad():
	xAxis = Input.get_axis("LEFT", "RIGHT")
	yAxis = Input.get_axis("UP", "DOWN")

# Action Input and Button Checks
func action_input(delta):
	# Check button states
	for button in buttonStates.keys():
		buttonStates[button] = Input.is_action_pressed(button)

		# Add to list if just pressed
		if Input.is_action_just_pressed(button):
			if button not in buttonOrder:
				buttonOrder.append(button)

		# Remove from list if just released
		if Input.is_action_just_released(button):
			if button in buttonOrder:
				buttonOrder.erase(button)

	# Update buttonActive to the last pressed button, or NONE if the list is empty
	buttonActive = Buttons[buttonOrder[-1]] if buttonOrder.size() > 0 else Buttons.NONE

	# Update fireDir based on buttonActive
	match buttonActive:
		Buttons.A: fireDir = Vector2.RIGHT
		Buttons.B: fireDir = Vector2.DOWN
		Buttons.Y: fireDir = Vector2.LEFT
		Buttons.X: fireDir = Vector2.UP

	# Firing logic
	if buttonActive != Buttons.NONE:
		holdTimer += delta
		fireHold = holdTimer >= holdLimit
	else:
		holdTimer = 0.0
		fireHold = false
	
	firing = buttonActive != Buttons.NONE
