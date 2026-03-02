extends Area2D
enum BulletEnum { BOMB, LASER, FOLLOW, BURST, CHARGE }
@export var BulletType: BulletEnum = BulletEnum.BURST
@export var speed: float = 2500.0
@export var damage: int = 1
@export var lifeTime: float = 1.5
var direction: Vector2 = Vector2.UP
var deviationAngle: float = 0.0
var deviationRadians: float = 0.0
var shader_bullet_type: int = -1

func _ready() -> void:
	match BulletType:
		BulletEnum.LASER:
			var lvl := clampi(WEAPON.laserLvl, 1, 4)
			scale = Vector2.ONE * (0.5 + lvl * 0.3)
			lifeTime = 0.15
		BulletEnum.BOMB:
			lifeTime = 3.0
			damage = 200
		BulletEnum.CHARGE:
			lifeTime = 1.5
			damage = 75
		BulletEnum.BURST:
			lifeTime = 1.5

	if shader_bullet_type != -1:
		var sprite := get_node_or_null("Sprite2D")
		if sprite and sprite.material:
			sprite.material = sprite.material.duplicate()
			sprite.material.set_shader_parameter("bullet_type", shader_bullet_type)

func _process(delta: float) -> void:
	if BulletType == BulletEnum.FOLLOW:
		_update_follow_direction(delta)
	if BulletType != BulletEnum.CHARGE:
		position += direction * speed * delta
	lifeTime -= delta
	if lifeTime <= 0:
		queue_free()
		return
	if BulletType == BulletEnum.BOMB:
		for bullet in get_tree().get_nodes_in_group("Enemy Bullet"):
			if bullet.has_method("remove"):
				bullet.remove()

func set_dir(newDir: Vector2, devAngle: float) -> void:
	deviationAngle = devAngle
	deviationRadians = deg_to_rad(deviationAngle)
	direction = newDir.rotated(deviationRadians)
	rotation = direction.angle()

func _update_follow_direction(delta: float) -> void:
	var target = _get_closest_enemy()
	if target == null:
		return
	var to_target = (target.global_position - global_position).normalized()
	direction = direction.lerp(to_target, 10.0 * delta).normalized()
	rotation = direction.angle()

func _get_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var closest: Node2D
	var min_dist := INF
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = enemy
	return closest

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("Enemy") and BulletType != BulletEnum.BOMB and BulletType != BulletEnum.CHARGE:
		SCORE.increase_combo(damage)
		if INPUT.fireHold:
			SCORE.keep_hot()
		else:
			SCORE.increase_hot(damage)
		queue_free()

func _on_area_exited(area: Node) -> void:
	if area.is_in_group("Free"):
		queue_free()

func _enter_tree():
	CAMERA.tracked_nodes.append(self)

func _exit_tree():
	CAMERA.tracked_nodes.erase(self)
