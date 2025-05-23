extends Control

@export var nextScene: PackedScene                                              # Próxima escena

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A"):
		get_tree().change_scene_to_packed(nextScene)
