extends Node

# === SOBRE EL JUEGO ===
const CENTER: Vector2 = Vector2(340, 365)
@onready var gameOver: PackedScene = preload("res://scenes/UI/game_over.tscn")
var directions = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
var liveCount: int = 2

# === ESCENAS DISPONIBLES ===
@onready var cat: PackedScene = preload("res://scenes/player/player.tscn")
@onready var powerUp: PackedScene = preload("res://scenes/items/power_up.tscn")
@onready var maxPowerUp: PackedScene = preload("res://scenes/items/max_power_up.tscn")
@onready var uiContinue: PackedScene = preload("res://scenes/UI/continue.tscn")
@onready var uiPause: PackedScene = preload("res://scenes/UI/pause.tscn")

# === ESTADO GLOBAL DEL JUGADOR ===
var spawnPoint: Vector2 = Vector2(150, 830)
var goPoint: Vector2 = Vector2(150, 600)
var lives: float = 2
var innerMedalChain: int = 0
var medalLevel: int = 0
var maxBombs: int = 4
var bombCount: int = 2

var player: Node2D = null
var spawnPos: Vector2 = Vector2(0, 0)
var spawnContinued: bool = false
var playing: bool = false
var dead: bool = false

func _process(_delta: float) -> void:
	if get_tree().get_nodes_in_group("Level").size() >= 1:
		var world = get_tree().get_first_node_in_group("Level")
		lives = world.lives
		playing = world.playing
	
	# Respawn automático si no hay jugador y el juego está activo
	if get_tree().get_nodes_in_group("Player").size() <= 0 and playing:
		spawn()
	
	# Actualizar referencias al jugador
	if get_tree().get_nodes_in_group("Player").size() > 0:
		player = get_tree().get_first_node_in_group("Player")
		maxBombs = player.maxBombs
		bombCount = player.bombCount
	
	# Limpieza opcional (puedes mantenerla o moverla a otro sitio)
	if get_tree().get_nodes_in_group("Player").size() > 3:
		get_tree().get_nodes_in_group("Player")[3].queue_free()

func spawn() -> void:
	if get_tree().get_nodes_in_group("Player").size() > 0: return
	
	if not cat: return
	
	if lives >= 0: _respawn_player()
	else: _show_continue()

func _respawn_player() -> void:
	dead = false
	_spawn_missing_powerups()
	_reset_game_state()
	_instance_player()
	
	if spawnContinued:
		var world = get_tree().get_first_node_in_group("Level")
		world.lives = liveCount
		_spawn_powerup(maxPowerUp)

func _spawn_missing_powerups() -> void:
	if spawnContinued:
		return
	
	var totalBurst = WEAPON.burstLvl - 1
	var totalLaser = WEAPON.laserLvl - 1
	
	for i in totalBurst:
		_spawn_powerup(powerUp)
	
	for i in totalLaser:
		_spawn_powerup(powerUp)

func _spawn_powerup(node: PackedScene) -> void:
	var item = node.instantiate()
	GLOBAL.add_to_game(item, true)
	var spawnOffset = Vector2(randf_range(-128, 128), 0)
	item.position = spawnPos + spawnOffset

func _reset_game_state() -> void:
	SCORE.reset()
	WEAPON.reset_lvl()

func _instance_player() -> void:
	var instance = cat.instantiate()
	instance.position = spawnPoint
	GLOBAL.add_to_game(instance, true)

func _show_continue() -> void:
	if dead: return
	
	dead = true
	var uiCont = uiContinue.instantiate()
	uiCont.position = Vector2(0, 0)
	GLOBAL.add_to_game(uiCont, true)

func get_player() -> Vector2:
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		player = null
		return spawnPoint
	else:
		player = players[0]
		return player.global_position

func store(pos: Vector2 = Vector2(0, 0), continued: bool = false) -> void:
	spawnPos = pos
	spawnContinued = continued

func game_over() -> void:
	_reset_game_state()
	get_tree().change_scene_to_packed(gameOver)

# Apertura del menú de pausa
func _input(event: InputEvent) -> void:
	if get_tree().paused: return
	
	# Solo permitir pausa en escenas de nivel jugable
	if event.is_action_pressed("Start") and GLOBAL.get_subtree().is_in_group("Level"):
		GLOBAL.pause_game()
		var pause_menu = uiPause.instantiate()
		GLOBAL.add_to_game(pause_menu)
		get_viewport().set_input_as_handled()
