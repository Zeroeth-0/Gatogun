extends Node

@onready var game_viewport = get_tree().root.get_node("Game/GameViewportContainer/GameViewport")

# Referencia al ColorRect que tiene el ShaderMaterial con el shader de puntos
@onready var curtain_colorrect: ColorRect = game_viewport.get_node_or_null("Curtain/ColorRect")
@onready var transition_material: ShaderMaterial = null

var is_transitioning := false

# === ESCENAS DEL JUEGO ===
@onready var gameOver: PackedScene = preload("res://scenes/game/game_over.tscn")
@onready var menuScene: PackedScene = preload("res://scenes/game/menu.tscn")
@onready var titleScene: PackedScene = preload("res://scenes/game/title_screen.tscn")
@onready var lvlOneScene: PackedScene = preload("res://scenes/game/level_one.tscn")
@onready var modeScene: PackedScene = preload("res://scenes/game/difficulty_select.tscn")
@onready var gatoScene: PackedScene = preload("res://scenes/game/gato_select.tscn")
@onready var dollScene: PackedScene = preload("res://scenes/game/doll_select.tscn")
@export var caravanScene: PackedScene = preload("res://scenes/game/caravan.tscn")
@export var practScene: PackedScene
@export var leaderScene: PackedScene
@export var galleryScene: PackedScene
@export var settScene: PackedScene

func _ready() -> void:
	if curtain_colorrect:
		transition_material = curtain_colorrect.material as ShaderMaterial
		if transition_material:
			curtain_colorrect.visible = false
			_update_resolution()
	
	# Actualizar resolución si cambia el tamaño del viewport
	game_viewport.size_changed.connect(_update_resolution)

func _update_resolution() -> void:
	if transition_material:
		# transition_material.set_shader_parameter("node_resolution", game_viewport.size)
		pass

# Transición principal
func change_scene(packedScene: String, duration: float = 0.8) -> void:
	if is_transitioning or not transition_material: return
	
	is_transitioning = true
	curtain_colorrect.visible = true
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 1. FADE OUT: aparecen los puntos → cubre la escena actual
	tween.tween_property(
		transition_material, 
		"shader_parameter/animation_progress", 
		1.0, 
		duration * 0.5
	)
	
	# 2. Cambiar la escena (la nueva aparece debajo de los puntos)
	tween.tween_callback(func():
		_change_subtree(packedScene)
	)
	
	# 3. FADE IN: desaparecen los puntos → revela la nueva escena
	tween.tween_property(
		transition_material, 
		"shader_parameter/animation_progress", 
		0.0, 
		duration * 0.5
	)
	
	# 4. Finalizar
	tween.tween_callback(func():
		curtain_colorrect.visible = false
		is_transitioning = false
	)

# Cambia la escena sin transición (función original mejorada)
func raw_change_scene(packedScene: String) -> void:
	_change_subtree(packedScene)

# Auxiliar: instancia y reemplaza el contenido del viewport
func _change_subtree(packedScene: String) -> void:
	var new_scene = _instantiate_scene(packedScene)
	if not new_scene:
		return
	
	# Quitar la escena antigua (child 1 = Subtree)
	game_viewport.get_child(1).queue_free()
	
	# Añadir la nueva
	game_viewport.add_child(new_scene)

# Instanciador con match (mejorado con to_upper por seguridad)
func _instantiate_scene(scene_id: String) -> Node:
	scene_id = scene_id.to_upper()
	match scene_id:
		"LEVEL_1": GAME.inGame = true
		_: GAME.inGame = false
	match scene_id:
		"OVER":        return gameOver.instantiate()
		"MENU":        return menuScene.instantiate()
		"TITLE":       return titleScene.instantiate()
		"LEVEL_1":     return lvlOneScene.instantiate()
		"MODE":        return modeScene.instantiate()
		"GATO":        return gatoScene.instantiate()
		"DOLL":        return dollScene.instantiate()
		"CARAVAN":     return caravanScene.instantiate()
		"PRACTICE":    return null #practScene.instantiate()
		"LEADERBOARDS": return null #leaderScene.instantiate()
		"GALLERY":     return null #galleryScene.instantiate()
		"SETTINGS":    return null #settScene.instantiate()
	push_error("Escena desconocida: " + scene_id)
	return null

# Funciones auxiliares sin cambios
func add_to_game(node: Node, deferred: bool = false) -> void:
	var target = game_viewport.get_child(1)
	if deferred:
		target.call_deferred("add_child", node)
	else:
		target.add_child(node)

func get_subtree() -> Node:
	return game_viewport.get_child(1)

func pause_game() -> void:
	get_tree().paused = true

func resume_game() -> void:
	get_tree().paused = false

func is_paused() -> bool:
	return get_tree().paused
