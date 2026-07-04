extends "res://source/weapons/burst_weapon.gd"

# === TIPOS DE OPTION ===
enum OptionFormation { SIDES, FOLLOW }

@export var OptionType: OptionFormation = OptionFormation.SIDES
@export var targetPos: Vector2 = Vector2.ZERO
@export var targetNode: Node2D
@export_range(0, 20, 1) var followDelay: int = 15
@export var sideOffset: float = 30.0
@export_range(-1, 1, 1) var offSign: int
@export var oscSpeed: float = 150.0

# Variables para la órbita
@export var orbit_radius: float = 60.0
@export var orbit_angular_speed: float = 2.5
var orbit_angle: float = 0.0

# === ESTADO INTERNO ===
var prevParentPos: Vector2
var currLatOffset: float
var moveDir: int
var currentRotationAngle: float = 0.0

func _ready() -> void:
	baseLvl = 0.0
	prevParentPos = get_parent().global_position
	deviationAngle = 0
	currLatOffset = -offSign * sideOffset
	moveDir = 1 if offSign == 1 else -1
	orbit_angle = offSign * PI / 2.0

func _process(delta: float) -> void:
	super._process(delta)
	activeBullets = get_tree().get_nodes_in_group("BulletCount").size()
	
	var parent = get_parent()
	var parentDelta = parent.global_position - prevParentPos
	prevParentPos = parent.global_position
	
	var dir := Vector2.UP
	var OptStyle = GAME.OptionStyle
	var StyleEnum = GAME.OptionEnum
	
	if INPUT.fireHold:
		orbit_angle = offSign * PI / 2.0
		match OptStyle:
			StyleEnum.SIDES:  _sides_hold(parent, dir, delta)
			StyleEnum.ORBIT:  _orbit_hold(parent, dir, delta)
			StyleEnum.FOLLOW: _follow_hold(dir, delta)
	else:
		global_position -= parentDelta
		
		if OptStyle == StyleEnum.ORBIT:
			_damage_no_hold_orbit(parent, delta)
		else:
			match OptionType:
				OptionFormation.SIDES:
					followDelay = 15
					var effectiveTargetPos = targetPos
					var baseDeviation = 10 * offSign if OptStyle == StyleEnum.SIDES else 0
					
					if OptStyle == StyleEnum.SIDES:
						var maxRotationDegrees: float = 15.0
						var targetRotation = deg_to_rad(INPUT.xAxis * maxRotationDegrees)
						var rotationLerpSpeed: float = 4.0
						currentRotationAngle = lerp_angle(currentRotationAngle, targetRotation, rotationLerpSpeed * delta)
						effectiveTargetPos = targetPos.rotated(currentRotationAngle)
						deviationAngle = baseDeviation + rad_to_deg(currentRotationAngle)
					else:
						deviationAngle = baseDeviation
					
					position = position.lerp(effectiveTargetPos, followDelay * delta)
				
				OptionFormation.FOLLOW:
					followDelay = 5
					deviationAngle = 0
					if targetNode and is_instance_valid(targetNode) and (INPUT.xAxis != 0 or INPUT.yAxis != 0):
						global_position = global_position.lerp(targetNode.global_position, followDelay * delta)

func _damage_no_hold_orbit(parent: Node2D, delta: float) -> void:
	followDelay = 10
	orbit_angle -= orbit_angular_speed * delta
	var offset = Vector2(cos(orbit_angle) * orbit_radius, sin(orbit_angle) * orbit_radius)
	var target_global = parent.global_position + offset
	global_position = global_position.lerp(target_global, followDelay * delta)
	deviationAngle = 0

func _sides_hold(parent: Node2D, dir: Vector2, delta: float) -> void:
	var enemy = _get_closest_enemy()
	dir = (enemy.global_position - parent.global_position).normalized() if enemy else Vector2.UP
	var distance := 50.0
	deviationAngle = 0
	var targetPosition = parent.global_position + dir * distance
	var offsetDir := dir.orthogonal().normalized()
	targetPosition += offsetDir * -offSign * sideOffset
	global_position = global_position.lerp(targetPosition, followDelay * delta)
	followDelay = 15
	if canFire and activeBullets < maxBullets:
		await _fire_burst(dir, bulletScene)

func _orbit_hold(parent: Node2D, dir: Vector2, delta: float) -> void:
	var distance := 75.0
	var nSideOffset = sideOffset * 1.5
	var ratio = abs(currLatOffset) / nSideOffset
	var minSpeedFactor: float = 0.3
	var effectiveSpeed = oscSpeed * (minSpeedFactor + (1 - minSpeedFactor) * ratio)
	currLatOffset += moveDir * effectiveSpeed * delta
	var jumped: bool = false
	if currLatOffset >= nSideOffset:
		currLatOffset = -nSideOffset + 10
		jumped = true
	elif currLatOffset <= -nSideOffset:
		currLatOffset = nSideOffset - 10
		jumped = true
	var targetPosition = parent.global_position + dir * distance
	var offsetDir := dir.orthogonal().normalized()
	targetPosition += offsetDir * currLatOffset
	if jumped: global_position = targetPosition
	else: global_position = global_position.lerp(targetPosition, followDelay * delta)
	followDelay = 15
	if canFire and activeBullets < maxBullets:
		await _fire_burst(dir, bulletScene)

func _follow_hold(dir: Vector2, delta: float) -> void:
	followDelay = 5
	deviationAngle = 0
	if targetNode and is_instance_valid(targetNode):
		targetPos = targetNode.global_position
		var toTarget = targetPos - global_position
		var distance = toTarget.length()
		var desiredDistance: float = 80.0
		var speedFactor: float = 6.0
		var idealPos: Vector2
		if distance > 0.1:
			var directionAway = -toTarget.normalized()
			idealPos = targetPos + directionAway * desiredDistance
		else:
			var backDir = -targetNode.lastMoveDirection.normalized()
			idealPos = targetPos + backDir * desiredDistance
		global_position = global_position.lerp(idealPos, speedFactor * delta)
	if canFire and activeBullets < maxBullets:
		await _fire_burst(dir, bulletScene)

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
