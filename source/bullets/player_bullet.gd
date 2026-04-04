# source/bullets/player_bullet.gd
# All player-fired bullet types in a single class
extends BaseBullet

# ==============================================================================
# ENUMS
# ==============================================================================

enum BulletEnum { BOMB, LASER, FOLLOW, BURST, CHARGE }

# ==============================================================================
# EXPORTS
# ==============================================================================

@export var BulletType: BulletEnum = BulletEnum.BURST

# ==============================================================================
# PUBLIC STATE - Set externally after acquire()
# ==============================================================================

## Set by laser_weapon.gd to alternate visual variants
var shader_bullet_type: int = -1

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var _life_remaining: float = 0.0
var _deviation_radians: float = 0.0

# ==============================================================================
# BPOOL HOOKS
# ==============================================================================

func _on_acquired() -> void:
	_life_remaining = _lifetime_for_type()
	damage = _damage_for_type()
	speed = _speed_for_type()
	_setup_type_groups()
	
	if BulletType == BulletEnum.LASER:
		var lvl := clampi(WEAPON.laserLvl, 1, 4)
		scale = Vector2.ONE * (0.5 + lvl * 0.3)

func _on_released() -> void:
	shader_bullet_type = -1
	# Remove from all groups so pooled bullets don't interfere with calls
	for g: StringName in [&"BulletCount", &"Fire", &"Charge", &"Bomb"]:
		if is_in_group(g): remove_from_group(g)

# ==============================================================================
# PUBLIC API
# ==============================================================================

func set_dir(newDir: Vector2, devAngle: float) -> void:
	_deviation_radians = deg_to_rad(devAngle)
	direction = newDir.rotated(_deviation_radians)
	velocity = direction * speed
	rotation = direction.angle()

# ==============================================================================
# UPDATE HOOKS
# ==============================================================================

func _update(delta: float) -> void:
	if BulletType == BulletEnum.FOLLOW: _update_follow(delta)
	
	# Lifetime - all times tick down
	_life_remaining -= delta
	if _life_remaining <= 0.0:
		isCancelled = true
		return
	
	# BOMB continuously clears bullets while alive
	if BulletType == BulletEnum.BOMB:
		for bullet in get_tree().get_nodes_in_group("Enemy Bullet"):
			if bullet.has_method("remove"): bullet.remove()

func _get_velocity(_delta: float) -> Vector2:
	# CHARGE sits in place - damage is applied by enemy via overlap check
	if BulletType == BulletEnum.CHARGE: return Vector2.ZERO
	return velocity

# ==============================================================================
# FOLLOW LOGIC
# ==============================================================================

func _update_follow(delta: float) -> void:
	var target := _closest_enemy()
	if target == null: return
	var to_target := (target.global_position - global_position).normalized()
	direction = direction.lerp(to_target, 10.0 * delta).normalized()
	velocity = direction * speed
	rotation = direction.angle()

func _closest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("Enemy")
	var closest: Node2D = null
	var min_dist := INF
	for enemy in enemies:
		var dist := global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest  = enemy
	return closest

# ==============================================================================
# COLLISION
# ==============================================================================

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("Enemy"):
		if BulletType != BulletEnum.BOMB and BulletType != BulletEnum.CHARGE:
			EVENTS.player_hit.emit(
				BulletType, damage, INPUT.fireHold, global_position)
			_do_release()

func _on_area_exited(area: Node) -> void:
	if area.is_in_group("Free"): _do_release()

# ==============================================================================
# HELPERS
# ==============================================================================

func _lifetime_for_type() -> float:
	match BulletType:
		BulletEnum.BOMB:  return 3.0
		BulletEnum.LASER: return 0.2
	return 1.5  # BURST, FOLLOW, CHARGE

func _damage_for_type() -> int:
	match BulletType:
		BulletEnum.BOMB:   return 200
		BulletEnum.CHARGE: return 75
	return 1  # BURST, LASER, FOLLOW

func _setup_type_groups() -> void:
	match BulletType:
		BulletEnum.BURST:
			add_to_group("BulletCount")
			add_to_group("Fire")
		BulletEnum.LASER:
			add_to_group("Fire")
		BulletEnum.CHARGE:
			add_to_group("Charge")
		BulletEnum.BOMB:
			add_to_group("Bomb")

func _setup_laser_shader() -> void:
	if shader_bullet_type == -1:
		return
	var sprite := get_node_or_null("Sprite2D")
	if sprite == null or sprite.material == null:
		return
	var mat: ShaderMaterial = sprite.material.duplicate()
	sprite.material = mat
	mat.set_shader_parameter("bullet_type", shader_bullet_type)

func _speed_for_type() -> float:
	match BulletType:
		BulletEnum.BOMB: return 800.0
		BulletEnum.CHARGE: return 0.0
		BulletEnum.FOLLOW: return 600.0
	return 2500.0 # BURST, LASER

func _ready():
	super._ready()
	_setup_laser_shader()
