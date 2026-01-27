extends Node

@onready var game_viewport = get_tree().root.get_node("Game/GameViewportContainer/GameViewport")

# === ESCENAS DEL JUEGO ===
@onready var gameOver: PackedScene = preload("res://scenes/game/game_over.tscn")
@onready var menuScene: PackedScene = preload("res://scenes/game/menu.tscn")
@onready var titleScene: PackedScene = preload("res://scenes/game/title_screen.tscn")
@onready var gameScene: PackedScene = preload("res://scenes/game/world.tscn")
@onready var gatoScene: PackedScene = preload("res://scenes/game/gato_select.tscn")
@onready var dollScene: PackedScene = preload("res://scenes/game/doll_select.tscn")
@export var caravanScene: PackedScene                                           # Escena Caravan
@export var practScene: PackedScene                                             # Escena Practice
@export var leaderScene: PackedScene                                            # Escena Leaderboards
@export var galleryScene: PackedScene                                           # Escena Gallery
@export var settScene: PackedScene                                              # Escena Settings

# Funciones para instanciar
func add_to_game(node: Node, deferred: bool = false):
	if deferred: game_viewport.get_child(0).call_deferred("add_child", node)
	else: game_viewport.get_child(0).add_child(node)

func get_subtree():
	return game_viewport.get_child(0)

# Pausar / reanudar el juego (sistema nativo)
func pause_game() -> void:
	get_tree().paused = true

func resume_game() -> void:
	get_tree().paused = false

func is_paused() -> bool:
	return get_tree().paused

# Cambiar escena dentro del SubViewport
func change_scene(packedScene: String) -> void:
	if game_viewport.get_child(0) == null: return
	
	# 1. Instanciar la nueva escena
	var newScene
	match packedScene:
		"OVER": newScene = gameOver.instantiate()
		"MENU": newScene = menuScene.instantiate()
		"TITLE": newScene = titleScene.instantiate()
		"GAME": newScene = gameScene.instantiate()
		"GATO": newScene = gatoScene.instantiate()
		"DOLL": newScene = dollScene.instantiate()
		"CARAVAN": return # newScene = caravanScene.instantiate()
		"PRACTICE": return # newScene = practScene.instantiate()
		"LEADERBOARDS": return # newScene = leaderScene.instantiate()
		"GALLERY": return # newScene = galleryScene.instantiate()
		"SETTINGS": return # newScene = settScene.instantiate()
	# 2. Eliminar hijos actuales
	for child in game_viewport.get_children(): child.queue_free()
	# 3. Añadir la nueva escena al contenedor
	game_viewport.add_child(newScene)
