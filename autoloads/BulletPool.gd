# autoloads/BulletPool.gd
extends Node

const MAX_PER_POOL: int = 1024

var _pools: Dictionary = {}

func _ready() -> void:
	print("BPOOL: Autoload cargado correctamente")

# ==============================================================================
func acquire(scene: PackedScene) -> Node:
	if scene == null:
		push_error("BPOOL.acquire(): scene is null")
		return null

	_ensure_pool(scene)
	var pool: Array = _pools[scene]

	# Limpieza muy agresiva
	for i in range(pool.size() - 1, -1, -1):
		var node = pool[i]
		if !is_instance_valid(node):
			pool.remove_at(i)
			continue
		
		if !node.get_meta("bpool_active", false):
			_activate(node)
			return node

	# Crear nueva bala
	if pool.size() < MAX_PER_POOL:
		var node := _create_node(scene)
		_activate(node)
		return node

	push_warning("BPOOL: Límite alcanzado")
	var node := _create_node(scene)
	_activate(node)
	return node


func release(node: Node) -> void:
	if !is_instance_valid(node):
		return
	
	_deactivate(node)   # siempre llamamos a deactivate


# ==============================================================================
func _ensure_pool(scene: PackedScene) -> void:
	if !_pools.has(scene):
		_pools[scene] = []


func _create_node(scene: PackedScene) -> Node:
	var node := scene.instantiate()
	node.set_meta("bpool_active", false)
	node.set_meta("bpool_in_tree", false)
	_pools[scene].append(node)
	return node


func _activate(node: Node) -> void:
	if !is_instance_valid(node):
		return

	var subtree := GLOBAL.get_subtree()
	if subtree == null:
		push_error("BPOOL: GLOBAL.get_subtree() == null")
		return

	if not node.get_meta("bpool_in_tree", false) or node.get_parent() == null:
		subtree.add_child.call_deferred(node)
		node.set_meta("bpool_in_tree", true)

	node.set_meta("bpool_active", true)
	node.visible = true
	node.set_process(true)
	node.set_physics_process(true)
	node.set_process_input(false)

	if node.has_method("on_acquired"):
		node.on_acquired()


func _deactivate(node: Node) -> void:
	if !is_instance_valid(node):
		return

	if node.has_method("on_released"):
		node.on_released()

	node.set_meta("bpool_active", false)
	node.visible = false
	node.set_process(false)
	node.set_physics_process(false)

	# Limpieza ultra segura con call_deferred
	if node.get_parent() != null:
		node.get_parent().remove_child.call_deferred(node)
	
	node.set_meta("bpool_in_tree", false)
