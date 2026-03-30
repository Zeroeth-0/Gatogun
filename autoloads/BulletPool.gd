# autoloads/BulletPool.gd
# Name: BPOOL

# Object pool for bullet nodes.
# Bullets are never destroyed.

# PROTOCOL:
#	on_acquired() -> get object from pool.
#	on_released() -> return object to pool.

# USE:
#	var bullet := BPOOL.acquire(bullet_scene)
#	BPOOL.release(bullet)
extends Node

# ==============================================================================
# CONSTANTS
# ==============================================================================

## Max node count per scene
const MAX_PER_POOL: int = 1024

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var _pools: Dictionary = {}

# ==============================================================================
# AUTOLOAD LIFECYCLE
# ==============================================================================

func _ready() -> void:
	EVENTS.scene_change_start.connect(_on_scene_change_start)

func _on_scene_change_start(_target: StringName) -> void:
	for scene in _pools:
		for node: Node in _pools[scene]:
			if !node.get_meta("bpool_in_tree", false): node.free()
	_pools.clear()

# ==============================================================================
# PUBLIC API
# ==============================================================================

## Gets a node from the pool
func acquire(scene: PackedScene) -> Node:
	if scene == null:
		push_error("BPOOL.acquire(): scene is null")
		return null
	
	_ensure_pool(scene)
	
	for node: Node in _pools[scene]:
		if !node.get_meta("bpool_active", false):
			_activate(node)
			return node
	
	if _pools[scene].size() < MAX_PER_POOL:
		var node := _create_node(scene)
		_activate(node)
		return node
	
	push_warning("BPOOL: limit met. Increase MAX_PER_POOl")
	
	var overflow := _create_node(scene)
	_activate(overflow)
	return overflow

## Returns a node to the pool
func release(node: Node) -> void:
	if !is_instance_valid(node): return
	
	if !node.has_meta("bpool_active"):
		node.queue_free()
		return
	
	if !node.get_meta("bpool_active", false): return
	
	_deactivate(node)

## Prewarms pool
func prewarm(scene: PackedScene, count: int) -> void:
	if scene == null:
		push_error("BPOOL.prewarm(): scene is null")
		return
	
	_ensure_pool(scene)
	var pool: Array = _pools[scene]
	var to_create: int = min(count, MAX_PER_POOL) - pool.size()
	
	for i in max(to_create, 0):
		var node := scene.instantiate()
		node.set_meta("bpool_active", false)
		node.set_meta("bpool_in_tree", false)
		pool.append(node)

## Current active nodes in certain scene
func active_count(scene: PackedScene) -> int:
	if !_pools.has(scene): return 0
	var count := 0
	for node: Node in _pools[scene]:
		if node.get_meta("bpool_active", false): count += 1
	return count

## Total pool size
func pool_size(scene: PackedScene) -> int:
	if !_pools.has(scene): return 0
	return _pools[scene].size()

## Returns every active node in certain scene
func get_active(scene: PackedScene) -> Array[Node]:
	var result: Array[Node] = []
	if !_pools.has(scene): return result
	for node: Node in _pools[scene]:
		if node.get_meta("bpool_active", false): result.append(node)
	return result

# ==============================================================================
# INTERNAL
# ==============================================================================

func _ensure_pool(scene: PackedScene) -> void:
	if !_pools.has(scene): _pools[scene] = []

func _create_node(scene: PackedScene) -> Node:
	var node := scene.instantiate()
	node.set_meta("bpool_active", false)
	node.set_meta("bpool_in_tree", false)
	_pools[scene].append(node)
	return node

func _activate(node: Node) -> void:
	if !node.get_meta("bpool_in_tree", false):
		var subtree := GLOBAL.get_subtree()
		if subtree == null:
			push_error("BPOOL._activate() get_subtree() returned null")
			return
		subtree.add_child(node)
		node.set_meta("bpool_in_tree", true)
	
	node.set_meta("bpool_active", true)
	node.visible = true
	node.set_process(true)
	node.set_physics_process(true)
	node.set_process_input(false)
	
	if node.has_method("on_acquired"): node.on_acquired()

func _deactivate(node: Node) -> void:
	if node.has_method("on_released"): node.on_released()
	
	node.set_meta("bpool_active", false)
	node.visible = false
	node.set_process(false)
	node.set_physics_process(false)
