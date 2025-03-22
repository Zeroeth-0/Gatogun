extends Node

@onready var wide_cat: PackedScene = preload("res://scenes/player/wide_cat.tscn")
@onready var linear_cat: PackedScene = preload("res://scenes/player/linear_cat.tscn")

var spawnPoint: Vector2 = Vector2(150, 830)
var goPoint: Vector2 = Vector2(150, 600)
var lives: float = 3

var characters_scenes: Array[PackedScene] = []
var selected_character: PackedScene = null  # Guardará el personaje seleccionado

func _ready():
	# Almacenar las escenas en el array
	characters_scenes = [wide_cat, linear_cat]

func spawn():
	if selected_character and lives >= 0:
		var player_instance = selected_character.instantiate()
		player_instance.position = spawnPoint  # Asigna la posición de spawn
		get_tree().current_scene.add_child.call_deferred(player_instance)  # Agrega el personaje a la escena
