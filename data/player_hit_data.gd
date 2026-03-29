# data/player_hit_data.gd

# Built and issued every time the player lands a hit
class_name PlayerHitData
extends RefCounted

var bullet_type: int
var damage: int
var was_hold: bool
var position: Vector2

func _init(
	p_type: int,
	p_damage: int,
	p_hold: bool,
	p_position: Vector2
) -> void:
	bullet_type = p_type
	damage = p_damage
	was_hold = p_hold
	position = p_position
