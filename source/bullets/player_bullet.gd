extends Area2D

# === TIPOS DE BALA ===
enum BulletEnum { BOMB, LASER, FOLLOW, BURST, CHARGE }

# === CONFIGURACIÓN EXPORTADA ===
@export var BulletType: BulletEnum = BulletEnum.BURST
@export var speed: float = 2500.0
@export var damage: float = 1.0
@export var lifeTime: float = 1.5

# === ESTADO INTERNO ===
var direction: Vector2 = Vector2.UP
var deviationAngle: float = 0.0
var deviationRadians: float = 0.0

# === CICLO DE VIDA ===
func _ready() -> void:
	match BulletType:
		BulletEnum.LASER:
			var full_scale := 0.5 + (WEAPON.laserLvl * 0.25)
			damage = WEAPON.laserLvl + 1.0
			scale = Vector2(full_scale, full_scale)
			lifeTime = 0.3
		BulletEnum.BOMB: lifeTime = 3.0
		BulletEnum.CHARGE: lifeTime = 1.5
		BulletEnum.BURST: lifeTime = 1.5

func _process(delta: float) -> void:
	if BulletType == BulletEnum.FOLLOW: _update_follow_direction(delta)
	if BulletType != BulletEnum.CHARGE: position += direction * speed * delta
	
	lifeTime -= delta
	if lifeTime <= 0:
		queue_free()
		return
	
	if BulletType == BulletEnum.BOMB:
		for bullet in get_tree().get_nodes_in_group("Enemy Bullet"):
			if bullet.has_method("remove"):
				bullet.remove()

# === CONFIGURAR DIRECCIÓN INICIAL ===
func set_dir(newDir: Vector2, devAngle: float) -> void:
	deviationAngle = devAngle
	deviationRadians = deg_to_rad(deviationAngle)
	direction = newDir.rotated(deviationRadians)
	rotation = direction.angle()

# === COMPORTAMIENTO FOLLOW ===
func _update_follow_direction(delta: float) -> void:
	var target = _get_closest_enemy()
	if target == null: return
	
	var to_target = (target.global_position - global_position).normalized()
	var turn_rate = 10.0
	direction = direction.lerp(to_target, turn_rate * delta).normalized()
	rotation = direction.angle()

# === AUXILIAR ===
func _get_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var closest
	var min_dist := INF
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = enemy
	return closest

# === COLISIONES ===
func _on_area_entered(area: Node) -> void:
	if area.is_in_group("Enemy") and BulletType != BulletEnum.BOMB and BulletType != BulletEnum.CHARGE:
		SCORE.increase_combo(damage)
		queue_free()

func _on_area_exited(area: Node) -> void:
	if area.is_in_group("Free"):
		queue_free()
