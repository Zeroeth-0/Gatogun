extends Node

# === SOBRE EL JUEGO ===
const CENTER: Vector2 = Vector2(340, 365)
@export var gameOver: PackedScene = preload("res://scenes/UI/game_over.tscn")   # Próxima escena
var directions = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]

# === ESCENAS DISPONIBLES ===
@onready var wideCat: PackedScene = preload("res://scenes/player/wide_cat.tscn")                    # Disparo ancho
@onready var linearCat: PackedScene = preload("res://scenes/player/linear_cat.tscn")                # Disparo lineal
@onready var powerUp: PackedScene = preload("res://scenes/items/power_up.tscn")                     # Potenciador
@onready var maxPowerUp: PackedScene = preload("res://scenes/items/max_power_up.tscn")              # Potenciador máximo
@onready var uiContinue: PackedScene = preload("res://scenes/UI/continue.tscn")                     # Continuar

# === ESTADO GLOBAL DEL JUGADOR ===
var spawnPoint: Vector2 = Vector2(150, 830)
var goPoint: Vector2 = Vector2(150, 600)
var lives: float = 2
var weaponLvl: float = 1.0
var rOptActive: bool = false
var lOptActive: bool = false
var optionCounter: float = 0.0
var innerMedalChain: int = 0
var medalLevel: int = 0
var bombCount: int = 3

var player: Node2D = null
var characterScenes: Array[PackedScene] = []
var selectedCharacter: PackedScene = null

func _ready() -> void:
	# Guardamos los personajes jugables en el array
	characterScenes = [wideCat, linearCat]

func spawn(pos = Vector2(0, 0), continued = false) -> void:
	directions.shuffle() # Mezcla el array
	
	# Solo se hace respawn si hay personaje seleccionado y vidas disponibles
	if selectedCharacter and lives > 0:
		# Instanciar potenciadores
		var totalItems = (weaponLvl - 1) + optionCounter if !continued else 0
		for i in totalItems:
			var item = powerUp.instantiate()
			item.position = pos
			item.powerupDir = directions[i]
			get_tree().current_scene.call_deferred("add_child", item)
		
		# Resetear estado (armas + cadenas/combos)
		SCORE.reset()
		weaponLvl = 1.0
		rOptActive = false
		lOptActive = false
		optionCounter = 0
		
		# Instanciar jugador
		var instance = selectedCharacter.instantiate()
		instance.position = spawnPoint
		get_tree().current_scene.call_deferred("add_child", instance)
	elif selectedCharacter and lives < 0:
		var uiCont = uiContinue.instantiate()
		uiCont.position = Vector2(0, 0)
		get_tree().current_scene.call_deferred("add_child", uiCont)
	
	if continued:
		print("hey")
		var item = maxPowerUp.instantiate()
		item.position = pos
		item.powerupDir = directions[0]
		get_tree().current_scene.call_deferred("add_child", item)

func get_player() -> Vector2:
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		player = null
		return spawnPoint
	else:
		player = players[0]
		return player.global_position

func game_over():
	get_tree().change_scene_to_packed(gameOver)
