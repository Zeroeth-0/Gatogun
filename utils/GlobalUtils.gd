extends Node

@onready var game_viewport = get_tree().root.get_node("Game/GameViewportContainer/GameViewport")

# Funciones para instanciar
func add_to_game(node: Node, deferred: bool = false):
	if deferred: game_viewport.get_child(0).call_deferred("add_child", node)
	else: game_viewport.get_child(0).add_child(node)

func get_subtree():
	return game_viewport.get_child(0)

# Pausar / reanudar el juego
func pause_game() -> void:
	game_viewport.get_child(0).process_mode = Node.PROCESS_MODE_DISABLED

func resume_game() -> void:
	game_viewport.get_child(0).process_mode = Node.PROCESS_MODE_INHERIT

# Cambiar escena dentro del SubViewport
func change_scene(packed_scene: PackedScene) -> void:
	if game_viewport.get_child(0) == null: return
	
	# 1. Eliminar hijos actuales
	for child in game_viewport.get_children():  child.queue_free()
	# 2. Instanciar la nueva escena
	var new_scene = packed_scene.instantiate()
	# 3. Añadirla al contenedor
	game_viewport.add_child(new_scene)
