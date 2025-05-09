extends Node2D

# === EXPORT CONFIG ===
@export var bulletScene: PackedScene
@export var fireRate: float = 0.05
@export_range(-20, 20, 5) var deviationAngle: float = 0.0
@export var MAX_BULLETS: int = 3
@export_range(0, 3, 1) var baseLvl: int = 1

@export var targetPos: Vector2 = Vector2.ZERO
@export_range(0, 20, 1) var followDelay: int = 15
@export var focusTarget: Vector2 = Vector2.ZERO

@export var isOption: bool = false
@export var sideOffset: float = 30.0
@export_range(-1, 1, 1) var offSign: int

# === INTERNAL STATE ===
var canFire := true
var prevParentPos: Vector2
var activeBullets := 0
var maxBullets := 0
var realAngle := deviationAngle

# === READY ===
func _ready() -> void:
	prevParentPos = get_parent().global_position

# === PROCESS LOOP ===
func _process(delta: float) -> void:
	activeBullets = get_tree().get_nodes_in_group("BulletCount").size()
	maxBullets = MAX_BULLETS * get_parent().get_child_count()

	if INPUT.firing and canFire and activeBullets < maxBullets and not INPUT.fireHold:
		await _fire_burst(INPUT.fireDir, bulletScene)

	if isOption and followDelay > 0:
		_process_option_behavior(delta)

# === OPTION FOLLOWING LOGIC ===
func _process_option_behavior(delta: float) -> void:
	var parent = get_parent()
	var parentDelta = parent.global_position - prevParentPos
	global_position -= parentDelta
	prevParentPos = parent.global_position

	var dir := Vector2.ZERO
	realAngle = 0 if INPUT.fireHold else deviationAngle

	if INPUT.fireHold:
		var enemy = _get_closest_enemy()
		dir = (enemy.global_position - parent.global_position).normalized() if enemy else Vector2.UP

		var distance := 50.0

		# === Posición visual desplazada lateralmente (solo visual, no para el disparo)
		var targetPosition = parent.global_position + dir * distance
		var offsetDir := dir.orthogonal().normalized()
		targetPosition += offsetDir * offSign * sideOffset

		global_position = global_position.lerp(targetPosition, followDelay * delta)

		if canFire and activeBullets < maxBullets:
			await _fire_burst(dir, bulletScene)
	else:
		position = position.lerp(targetPos, followDelay * delta)

# === BULLET BURST LOGIC ===
func _fire_burst(direction: Vector2, scene: PackedScene) -> void:
	canFire = false

	for i in MAX_BULLETS:
		await get_tree().create_timer(0.05).timeout
		_fire_bullet(direction, scene)

	await get_tree().create_timer(fireRate if direction == INPUT.fireDir else 0.0).timeout
	canFire = true

# === BULLET FIRING ===
func _fire_bullet(direction: Vector2, scene: PackedScene) -> void:
	var orthogonal = direction.orthogonal().normalized()
	var spacing = 30
	var totalLvl = baseLvl + int(GAME.weaponLvl)

	for i in totalLvl:
		var offset = (i - (totalLvl - 1) / 2.0) * spacing
		var bullet = scene.instantiate()
		bullet.position = global_position + orthogonal * offset
		bullet.set_dir(direction, realAngle)
		get_tree().current_scene.add_child(bullet)

# === UTILS ===
func _get_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var closest: Node2D = null
	var minDist := INF

	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < minDist:
			minDist = dist
			closest = enemy

	return closest
