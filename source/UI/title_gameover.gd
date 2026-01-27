extends Control

var first_frame: bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !first_frame:
		if Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A"):
			GLOBAL.change_scene("MENU")
	else: first_frame = false
