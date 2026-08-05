# source/enemies/enemy_kill_handler.gd
# Name: KILLS
# Handles explosion VFX, score, drops, medal countdown, pulse bonuses.
extends Node

# ==============================================================================
# CONSTANTS
# ==============================================================================

const MEDAL_SCENE     := preload("res://scenes/items/medal.tscn")
const REVENGE_SCENE   := preload("res://scenes/bullets/revenge_bullet.tscn")
const SIDES_SCENE   := preload("res://scenes/items/sides_item.tscn")
const ORBIT_SCENE   := preload("res://scenes/items/orbit_item.tscn")
const FOLLOW_SCENE   := preload("res://scenes/items/follow_item.tscn")
const EXPLOSION_SCENE := preload("res://scenes/vfx/explosion.tscn")

const MEDAL_RANGE:  float = 250.0
const DROP_SPREAD:  float = 20.0

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	EVENTS.enemy_killed.connect(_on_enemy_killed)

# ==============================================================================
# KILL HANDLER
# ==============================================================================

func _on_enemy_killed(data: EnemyKillData) -> void:
	_spawn_explosion(data)
	_add_score(data)
	_handle_drops(data)
	_handle_medal_countdown(data)
	_handle_pulse_bonus(data)

# ==============================================================================
# VFX
# ==============================================================================

func _spawn_explosion(data: EnemyKillData) -> void:
	var expl := EXPLOSION_SCENE.instantiate()
	expl.global_position = data.position
	expl.scale          *= data.explosion_scale
	GLOBAL.add_to_game(expl)

# ==============================================================================
# SCORE
# ==============================================================================

func _add_score(data: EnemyKillData) -> void:
	# Minimum score per kill: 2000 * mult
	# If combo * mult exceeds 2000, score scales with combo
	var base := data.combo_at_death * data.mult_at_death
	SCORE.add_score(data.combo_at_death if base > 2000 else 2000)

# ==============================================================================
# DROPS
# ==============================================================================

func _handle_drops(data: EnemyKillData) -> void:
	var near_player  := data.position.distance_to(GAME.get_player()) < MEDAL_RANGE
	var medal_active := SCORE.medalCountdown > 0.0
	
	# Medals: not by bomb, player nearby OR medals active OR pulse
	if not data.by_bomb and (near_player or medal_active or data.by_charge):
		_spawn_items(data.score_drop_count, MEDAL_SCENE, data.position)
	
	# Revenge bullets
	if data.revenge:
		_spawn_items(data.score_drop_count, REVENGE_SCENE, data.position)
	
	# COME BACK LATER
	#if data.drops_powerup and GAME.DollStyle != GAME.DollEnum.STRONG:
	#	_spawn_items(1, POWERUP_SCENE, data.position, true)
	
	# ELITE: cancel all enemy bullets
	if data.enemy_type == &"ELITE":
		for bullet in get_tree().get_nodes_in_group("Enemy Bullet"):
			if bullet.has_method("cancel"):
				bullet.cancel()

func _spawn_items(count: int, scene: PackedScene,
		pos: Vector2, centered: bool = false) -> void:
	for i in count:
		var item := scene.instantiate()
		GLOBAL.add_to_game(item, true)
		if centered:
			item.position = pos
		else:
			item.position = pos + Vector2(
				DRNG.drandf_range(-DROP_SPREAD, DROP_SPREAD), 0.0)

# ==============================================================================
# MEDAL COUNTDOWN
# ==============================================================================

func _handle_medal_countdown(data: EnemyKillData) -> void:
	# Only burst kills with no charge and no fire-hold extend the chain.
	if not data.by_burst or data.by_charge or not data.not_hold: return
	if SCORE.medalCountdown <= 0.0: SCORE.medalCountdown = SCORE.MAX_MEDAL_COUNTDOWN
	else: SCORE.medalCountdown += 0.1

# ==============================================================================
# PULSE BONUS
# ==============================================================================

func _handle_pulse_bonus(data: EnemyKillData) -> void:
	if not data.by_charge: return
	SCORE.increase_hot(5)
	SCORE.increase_combo(100)
	if SCORE.hot < 50.0: SCORE.hot = 50.0
