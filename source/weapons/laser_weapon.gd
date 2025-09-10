extends Node2D

# === EXPORTS GENERALES ===
@export var bulletScene: PackedScene                                            # Tipo de bala
@export var fireRate: float = 0.015                                             # Cadencia de tiro

# === ESTADO INTERNO ===
var cooldown := 0.0
var canFire = true

# === FLUJO DE COMPORTAMIENTO ===
func _process(delta: float) -> void:
	cooldown -= delta
	if INPUT.fireHold and cooldown <= 0.0:
		_fire_burst(Vector2.UP)

# === DISPARO ===
func _fire_burst(direction: Vector2) -> void:
	_fire_bullet(direction)
	cooldown = fireRate

func _fire_bullet(direction: Vector2) -> void:
	var bullet = bulletScene.instantiate()
	bullet.position = global_position
	bullet.set_dir(direction, 0)  # Sin desviación
	get_tree().current_scene.add_child(bullet)
