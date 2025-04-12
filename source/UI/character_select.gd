extends Control

@export var character_sprite: TextureRect                                       # Aspecto de personaje a elegir
@export var character_label: Label                                              # Nombre de personaje a elegir
@export var next_scene: PackedScene                                             # Próxima escena

var selected_index: int = 0
var character_names: Array[String] = ["Wide Cat", "Linear Cat"]

func _ready():
	update_selection()

func _input(_event):
	if Input.is_action_pressed("RIGHT"):
		selected_index = (selected_index + 1) % character_names.size()
		update_selection()
	elif Input.is_action_pressed("LEFT"):
		selected_index = (selected_index - 1 + character_names.size()) % character_names.size()
		update_selection()
	
	# Seleccionar personaje e iniciar juego
	if Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A"): start_game()

func update_selection():
	character_label.text = character_names[selected_index]

func start_game():
	GAME.selectedCharacter = GAME.characterScenes[selected_index]  # Guarda selecciónc
	get_tree().change_scene_to_packed(next_scene)  # Cambia de escena
