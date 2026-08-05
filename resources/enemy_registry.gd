# resources/enemy_registry.gd
class_name EnemyRegistry
extends Resource

## List of id → scene pairs. Add entries in the inspector.
@export var entries: Array[EnemyRegistryEntry] = []

func get_scene(enemy_id: StringName) -> PackedScene:
	for entry in entries:
		if entry != null and entry.enemy_id == enemy_id: return entry.scene
	push_error("EnemyRegistry: unknown enemy id '%s'" % enemy_id)
	return null

func register(enemy_id: StringName, scene: PackedScene) -> void:
	if scene == null:
		push_error("EnemyRegistry.register(): null scene for '%s'" % enemy_id)
		return
	# Update existing entry if id already exists
	for entry in entries:
		if entry != null and entry.enemy_id == enemy_id:
			entry.scene = scene
			return
	# Add new entry
	var e := EnemyRegistryEntry.new()
	e.enemy_id = enemy_id
	e.scene    = scene
	entries.append(e)

func has_enemy(enemy_id: StringName) -> bool:
	for entry in entries:
		if entry != null and entry.enemy_id == enemy_id: return true
	return false
