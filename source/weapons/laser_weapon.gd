extends Node2D
# === EXPORTS GENERALES ===
@export var bulletScene: PackedScene
@export var fireRate: float = 0.030
# === ESTADO INTERNO ===
var cooldown := 0.0
var canFire = true
var _laser_type_toggle := false   # false → type 3, true → type 2 (shader)

# === FLUJO DE COMPORTAMIENTO ===
func _process(delta: float) -> void:
	cooldown -= delta
	if INPUT.fireHold and cooldown <= 0.0:
		_fire_burst(Vector2.UP)

# === DISPARO ===
func _fire_burst(direction: Vector2) -> void:
	_fire_bullet(direction)
	SFX.play("burst", -24, 0, -0.1)
	cooldown = fireRate

func _fire_bullet(direction: Vector2) -> void:
	var bullet = bulletScene.instantiate()
	bullet.position = global_position
	bullet.set_dir(direction, 0)

	if bullet.BulletType == bullet.BulletEnum.LASER:
		bullet.shader_bullet_type = 2 if _laser_type_toggle else 3
		_laser_type_toggle = not _laser_type_toggle

	GLOBAL.add_to_game(bullet)
