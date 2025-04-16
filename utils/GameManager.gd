extends Node

# === ESCENAS DISPONIBLES ===
@onready var wideCat: PackedScene = preload("res://scenes/player/wide_cat.tscn")                    # Disparo ancho
@onready var linearCat: PackedScene = preload("res://scenes/player/linear_cat.tscn")                # Disparo lineal

# === ESTADO GLOBAL DEL JUGADOR ===
var spawnPoint: Vector2 = Vector2(150, 830)
var goPoint: Vector2 = Vector2(150, 600)
var lives: float = 2

var player: Node2D = null
var characterScenes: Array[PackedScene] = []
var selectedCharacter: PackedScene = null

func _ready() -> void:
	# Guardamos los personajes jugables en el array
	characterScenes = [wideCat, linearCat]

func spawn() -> void:
	# Solo se hace respawn si hay personaje seleccionado y vidas disponibles
	if selectedCharacter and lives > 0:
		var instance = selectedCharacter.instantiate()
		instance.position = spawnPoint
		get_tree().current_scene.call_deferred("add_child", instance)

func get_player() -> Vector2:
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		player = null
		return spawnPoint
	else:
		player = players[0]
		return player.global_position
