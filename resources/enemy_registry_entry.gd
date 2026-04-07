# resources/enemy_registry_entry.gd
# One entry in the EnemyRegistry
class_name EnemyRegistryEntry
extends Resource

@export var enemy_id: StringName = &""
@export var scene: PackedScene = null
