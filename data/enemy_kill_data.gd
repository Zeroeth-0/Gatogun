# data/enemy_kill_data.gd

# Every enemy builds one on death and issues it.
# Consumed without touching the enemy
class_name EnemyKillData
extends RefCounted

# === Identity ===
var enemy_type: StringName
var position: Vector2
var explosion_scale: float = 1.5

# === Death state ===
var combo_at_death: int
var mult_at_death: int
var score_drop_count: int
var by_charge: bool
var by_bomb: bool
var by_burst: bool
var not_hold: bool
var revenge: bool
var drops_powerup: bool

func _init(
	p_type: StringName,
	p_position: Vector2,
	p_explosion_scale: float,
	p_combo: int,
	p_mult: int,
	p_score_drops: int,
	p_charge: bool,
	p_bomb: bool,
	p_burst: bool,
	p_not_hold: bool,
	p_revenge: bool,
	p_powerup: bool
) -> void:
	enemy_type = p_type
	position = p_position
	explosion_scale = p_explosion_scale
	combo_at_death = p_combo
	mult_at_death = p_mult
	score_drop_count = p_score_drops
	by_charge = p_charge
	by_bomb = p_bomb
	by_burst = p_burst
	not_hold = p_not_hold
	revenge = p_revenge
	drops_powerup = p_powerup
