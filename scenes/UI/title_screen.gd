extends Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("C"):
		get_tree().change_scene_to_file("res://scenes/levels/world.tscn")
