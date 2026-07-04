# autoloads/Events.gd
# Name: EVENTS

# Centralized signal bus.
# RULE: NEVER cast methods from external systems.
extends Node

# ==============================================================================
# PLAYER
# ==============================================================================

## Issued by GameManager
signal player_died(position: Vector2)
signal player_spawned(player: CharacterBody2D)
signal lives_flow(new_lives: int)
signal bombs_flow(current: int, maximum: int)

## Issued by player.gd
signal bomb_used(position: Vector2, bombs_remaining: int)
signal shield_active(active: bool, duration: float)

# ==============================================================================
# ENEMIES
# ==============================================================================

## Issued by EnemyGatogun
## All data included, no enemy reference needed
signal enemy_killed(data: EnemyKillData)
signal enemy_hit(enemy_type: StringName, position: Vector2, damage: float,
				 pulse_marked: bool)
signal enemy_enters_game(enemy: Node)
signal enemies_cleared()

# ==============================================================================
# BULLETS
# ==============================================================================

## Issued by PlayerBullet
signal player_hit(bullet_type: int, damage: int, was_hold: bool,
						 position: Vector2)
signal bullet_cancelled(position: Vector2)
signal bomb_cleared_bullets(count: int)

# ==============================================================================
# SCORE
# ==============================================================================

## Issued by ScoreManager
signal score_flow(new_score: int, delta: int)
signal combo_flow(new_combo: int)
signal mult_flow(new_mult: int)
signal hot_flow(new_hot: float, is_keeping: bool)
signal medal_countdown_flow(new_value: float)
signal score_reset()

# ==============================================================================
# ITEMS
# ==============================================================================

## Issued by ItemGatogun
signal item_collected(item_type: int, position: Vector2)
signal medal_collected(position: Vector2, new_mult: int)
signal powerup_collected(new_style: int)
signal oneup_collected(new_lives: int)

# ==============================================================================
# WEAPONS
# ==============================================================================

## Issued by WeaponManager
signal weapon_lvl_flow(weapon_id: StringName, new_level: int)
signal option_flow(r_active: bool, l_active: bool)
signal weapon_reset()

# ==============================================================================
# FLOW
# ==============================================================================

## Issued by FlowManager
signal phase_flow(new_phase: int, phase_name: StringName)
signal boss_died(boss_type: StringName)
signal parser_pause()
signal parser_resume()
signal time_up()
signal bonus_completed(medal_count: int, no_miss: bool)

## Issued by LevelParser
signal wave_marker_reached(marker_name: StringName)

## Issued on player miss
signal missed()

# ==============================================================================
# UI
# ==============================================================================

## Issued by any UI bit when its cycle ends
signal ui_dismissed(ui_id: StringName)

## Issued by ScoreManager
signal hot_bar_pulse()
signal hot_bar_keep()
signal combo_label_in()
signal combo_label_out()

## Issued on pause or resume
signal pause_flow(is_paused: bool)

# ==============================================================================
# SCENES
# ==============================================================================

## Issued by SceneManager
signal scene_change_start(target_scene: StringName)
signal scene_change_done(scene_name: StringName)
