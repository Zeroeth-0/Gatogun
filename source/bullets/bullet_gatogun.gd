# source/bullets/bullet_gatogun.gd
# Enemy bullet adjusted to Gatogun's mechanics
extends "res://source/bullets/bullet.gd"

# ==============================================================================
# EXPORTS
# ==============================================================================

@export var revenge: bool = false
@export var medal: PackedScene = preload("res://scenes/items/medal.tscn")

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var revHealth: int = 7

# ==============================================================================
# BPOOL HOOK
# ==============================================================================

func _on_acquired() -> void:
	super._on_acquired()
	revHealth = 7
	# Revenge bullets point at the player on spawn
	if revenge:
		direction = (GAME.get_player()- global_position).normalized()
		velocity = direction * speed

# ==============================================================================
# PUBLIC API
# ==============================================================================

## Spawns a medal on cancel, then returns to pool
func cancel() -> void:
	if isCancelled: return
	isCancelled = true
	var item := medal.instantiate()
	GLOBAL.add_to_game(item, true)
	item.position = global_position
	_do_release()

## Silent removal with no drop
func remove() -> void: _do_release()

# ==============================================================================
# COLLISION
# ==============================================================================

func _on_area_exited(area: Node) -> void:
	if area.is_in_group("Free"): _do_release()

func _on_area_entered(area: Node) -> void:
	if !area.is_in_group("Fire") or !revenge: return
	revHealth -= 1
	if revHealth > 0 or isCancelled: return
	isCancelled = true
	var player_pos := GAME.get_player()
	var near_player := position.distance_to(player_pos) < 150
	if near_player or SCORE.medalCountdown > 0: cancel()
	else: _do_release()
