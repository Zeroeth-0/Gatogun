extends Node

# === SOBRE EL JUEGO ===
const CENTER: Vector2 = Vector2(340, 365)
@onready var gameOver: PackedScene = preload("res://scenes/UI/game_over.tscn")  # Próxima escena
var directions = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]

# === ESCENAS DISPONIBLES ===
@onready var cat: PackedScene = preload("res://scenes/player/player.tscn")                          # Jugador
@onready var powerUp: PackedScene = preload("res://scenes/items/power_up.tscn")                     # Potenciador
@onready var maxPowerUp: PackedScene = preload("res://scenes/items/max_power_up.tscn")              # Potenciador máximo
@onready var uiContinue: PackedScene = preload("res://scenes/UI/continue.tscn")                     # Continuar

# === ESTADO GLOBAL DEL JUGADOR ===
var spawnPoint: Vector2 = Vector2(150, 830)
var goPoint: Vector2 = Vector2(150, 600)
var lives: float = 2
var innerMedalChain: int = 0
var medalLevel: int = 0
var bombCount: int = 3

var player: Node2D = null

var spawnPos: Vector2 = Vector2(0, 0)
var spawnContinued: bool = false
var playing: bool = false

func _process(_delta):
	if get_tree().get_nodes_in_group("Level").size() >= 1:
		var world = get_tree().get_first_node_in_group("Level");
		lives = world.lives
		playing = world.playing
	if get_tree().get_nodes_in_group("Player").size() <= 0 and playing: spawn()

func spawn() -> void:
	# Si ya hay un jugador en escena, no hacer nada
	if get_tree().get_nodes_in_group("Player").size() > 0: return
	
	# Solo se hace respawn si hay personaje seleccionado y vidas disponibles
	if cat and lives >= 0:
		# Instanciar potenciadores
		var totalItems = (WEAPON.burstLvl - 1) + WEAPON.optionCounter if !spawnContinued else 0
		for i in totalItems - get_tree().get_nodes_in_group("PowerUp").size():
			var item = powerUp.instantiate()
			item.position = spawnPos
			item.powerupDir = directions[i]
			get_tree().current_scene.call_deferred("add_child", item)
		
		# Resetear estado (armas + cadenas/combos)
		SCORE.reset()
		WEAPON.reset_lvl()
		
		# Instanciar jugador
		var instance = cat.instantiate()
		instance.position = spawnPoint
		if get_tree().current_scene: get_tree().current_scene.call_deferred("add_child", instance)
	elif cat and lives < 0:
		var uiCont = uiContinue.instantiate()
		uiCont.position = Vector2(0, 0)
		if get_tree().current_scene: get_tree().current_scene.call_deferred("add_child", uiCont)
	
	if spawnContinued:
		var item = maxPowerUp.instantiate()
		item.position = spawnPos
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

func store(pos = Vector2(0, 0), continued = false):
	spawnPos = pos;
	spawnContinued = continued

func game_over():
	get_tree().change_scene_to_packed(gameOver)
