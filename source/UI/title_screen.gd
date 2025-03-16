extends Control

@export var nextScene: PackedScene
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("C"):
		get_tree().change_scene_to_packed(nextScene)
