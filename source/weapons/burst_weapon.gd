extends Node2D

# === EXPORTS GENERALES ===
@export var bulletScene: PackedScene
@export var fireRate: float = 0.05
@export var MAX_BULLETS: int = 4
@export_range(-20, 20, 5) var deviationAngle: float = 0.0

# === ESTADO INTERNO ===
var baseLvl := 1.0
var canFire := true
var activeBullets := 0
var maxBullets := 0
var realAngle := deviationAngle

# === FLUJO DE COMPORTAMIENTO ===
func _process(delta: float) -> void:
	activeBullets = get_tree().get_nodes_in_group("BulletCount").size()
	maxBullets = MAX_BULLETS
	if INPUT.firing and canFire and activeBullets < maxBullets and not INPUT.fireHold:
		await _fire_burst(INPUT.fireDir, bulletScene)

# === DISPARO ===
func _fire_burst(direction: Vector2, scene: PackedScene) -> void:
	canFire = false
	for i in MAX_BULLETS:
		await get_tree().create_timer(0.05, false).timeout
		_fire_bullet(direction, scene)

	await get_tree().create_timer(fireRate if direction == INPUT.fireDir else 0.0, false).timeout
	canFire = true

func _fire_bullet(direction: Vector2, scene: PackedScene) -> void:
	var orthogonal = direction.orthogonal().normalized()
	var spacing = 30
	var totalLvl = baseLvl + int(WEAPON.burstLvl)

	for i in totalLvl:
		var offset = (i - (totalLvl - 1) / 2.0) * spacing
		var bullet = scene.instantiate()
		bullet.position = global_position + orthogonal * offset
		bullet.set_dir(direction, realAngle)
		get_tree().current_scene.add_child(bullet)
