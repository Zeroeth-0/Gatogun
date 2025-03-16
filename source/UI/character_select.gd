extends Control

@export var character_sprite: TextureRect
@export var character_label: Label
@export var next_scene: PackedScene  # La escena a la que cambiará

var selected_index: int = 0
var character_names: Array[String] = ["Wide Cat", "Linear Cat"]

func _ready():
	update_selection()

func _input(event):
	if Input.is_action_pressed("RIGHT"):
		selected_index = (selected_index + 1) % character_names.size()
		update_selection()
	elif Input.is_action_pressed("LEFT"):
		selected_index = (selected_index - 1 + character_names.size()) % character_names.size()
		update_selection()
	elif Input.is_action_just_pressed("C"):  # "C" asignado en Input Map
		start_game()

func update_selection():
	character_label.text = character_names[selected_index]

func start_game():
	GAME.selected_character = GAME.characters_scenes[selected_index]  # Guarda selección
	get_tree().change_scene_to_packed(next_scene)  # Cambia de escena
