# data/enemy_hit_data.gd

# Every enemy builds one on hit and issues it.
class_name EnemyHitData
extends RefCounted

var enemy_type: StringName
var position: Vector2
var damage: float
var by_charge: bool
var health: float

func _init(
	p_type: StringName,
	p_position: Vector2,
	p_damage: float,
	p_charge: bool,
	p_health: float
) -> void:
	enemy_type = p_type
	position = p_position
	damage = p_damage
	by_charge = p_charge
	health = p_health
