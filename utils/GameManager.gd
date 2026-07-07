extends Node

# === SOBRE EL JUEGO ===
const CENTER: Vector2 = Vector2(340, 365)
var directions = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
var liveCount: int = 2
var inGame: bool = false

# === ESCENAS DISPONIBLES ===
@onready var cat: PackedScene = preload("res://scenes/player/player.tscn")
@onready var sidesItem: PackedScene = preload("res://scenes/items/sides_item.tscn")
@onready var orbitItem: PackedScene = preload("res://scenes/items/orbit_item.tscn")
@onready var followItem: PackedScene = preload("res://scenes/items/follow_item.tscn")
@onready var uiContinue: PackedScene = preload("res://scenes/UI/continue.tscn")
@onready var uiPause: PackedScene = preload("res://scenes/UI/pause.tscn")

# === ESTILOS ===
enum OptionEnum { SIDES, ORBIT, FOLLOW }
enum DollEnum { SPEED, STRONG, NEWBIE, CARAVAN }
var OptionStyle: OptionEnum = OptionEnum.SIDES
var DollStyle: DollEnum = DollEnum.SPEED

# === ESTADO GLOBAL DEL JUGADOR ===
var spawnPoint: Vector2 = Vector2(340, 830)
var goPoint: Vector2 = Vector2(340, 600)
var lives: float = 2
var medalLevel: int = 0
var maxBombs: int = 4
var bombCount: int = 2

var player: Node2D = null
var spawnPos: Vector2 = Vector2(0, 0)
var spawnContinued: bool = false
var playing: bool = false
var dead: bool = false

func _process(_delta: float) -> void:
	var is_caravan = FLOW.isCaravan or DollStyle == DollEnum.CARAVAN
	if is_caravan: 
		lives = 0
	
	var world_playing = false
	var levels = get_tree().get_nodes_in_group("Level")
	if levels.size() > 0:
		var world = levels[0]
		if "playing" in world:
			world_playing = world.playing
		else:
			world_playing = true
	
	playing = world_playing

	var auto_spawn = false
	if is_caravan and world_playing:
		auto_spawn = true
	elif playing and inGame:
		auto_spawn = true

	var players = get_tree().get_nodes_in_group("Player")
	if players.size() == 0 and auto_spawn:
		spawn()
	elif players.size() > 0:
		player = players[0]
		maxBombs = player.maxBombs
		bombCount = player.bombCount
	
	if players.size() > 3:
		players[3].queue_free()
	
	if DollStyle == DollEnum.STRONG or is_caravan:
		remove_power_ups()

func spawn() -> void:
	if get_tree().get_nodes_in_group("Player").size() > 0: return
	if not cat: return

	var is_caravan = FLOW.isCaravan or DollStyle == DollEnum.CARAVAN
	if lives >= 0 or is_caravan: 
		_respawn_player()
	else:
		_show_continue()

func _respawn_player() -> void:
	dead = false
	SCORE.reset()
	WEAPON.reset_lvl()
	
	var instance = cat.instantiate()
	# Añadimos al grupo de inmediato para prevenir bugs de spawn múltiple
	instance.add_to_group("Player") 
	instance.position = spawnPoint
	GLOBAL.add_to_game(instance, true)

	if spawnContinued: lives = liveCount

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
	SCORE.reset()
	WEAPON.reset_lvl()
	GLOBAL.change_scene("OVER")

func _input(event: InputEvent) -> void:
	if get_tree().paused or GLOBAL.is_transitioning: return
	
	if event.is_action_pressed("Start") and GLOBAL.get_subtree().is_in_group("Level"):
		GLOBAL.pause_game()
		var pause_menu = uiPause.instantiate()
		GLOBAL.add_to_game(pause_menu)
		get_viewport().set_input_as_handled()

func set_option_style(style: String):
	match style:
		"SIDES": OptionStyle = OptionEnum.SIDES
		"ORBIT": OptionStyle = OptionEnum.ORBIT
		"FOLLOW": OptionStyle = OptionEnum.FOLLOW
		_: OptionStyle = OptionEnum.SIDES

func set_doll(style: String):
	match style:
		"SPEED": DollStyle = DollEnum.SPEED
		"STRONG": DollStyle = DollEnum.STRONG
		"NEWBIE": DollStyle = DollEnum.NEWBIE
		"CARAVAN": DollStyle = DollEnum.CARAVAN
		_: DollStyle = DollEnum.SPEED

func set_lives():
	lives = liveCount

func remove_power_ups():
	var power_ups = get_tree().get_nodes_in_group("PowerUp")
	if power_ups.size() > 0:
		for pw in power_ups: 
			pw.queue_free()
