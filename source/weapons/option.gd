extends "res://source/weapons/burst_weapon.gd"

# === TIPOS DE OPTION ===
enum OptionEnum { SIDES, FOLLOW }

# === EXPORTS GENERALES ===
@export var OptionType: OptionEnum = OptionEnum.SIDES                           # Tipo de option
@export var targetPos: Vector2 = Vector2.ZERO
@export var targetNode: Node2D
@export_range(0, 20, 1) var followDelay: int = 15
@export var focusTarget: Vector2 = Vector2.ZERO
@export var sideOffset: float = 30.0
@export_range(-1, 1, 1) var offSign: int
@export var oscSpeed: float = 150.0

# === ESTADO INTERNO ===
var prevParentPos: Vector2
var currLatOffset: float
var moveDir: int
var lastMoveDirection: Vector2 = Vector2.DOWN
var currentRotationAngle: float = 0.0   # Ángulo actual suavizado para la rotación en RANGE sin hold

# === FLUJO DE COMPORTAMIENTO ===
func _ready() -> void:
	baseLvl = 0.0
	prevParentPos = get_parent().global_position
	deviationAngle = 0
	currLatOffset = -offSign * sideOffset
	moveDir = 1 if offSign == 1 else -1

func _process(delta: float) -> void:
	super._process(delta)
	activeBullets = get_tree().get_nodes_in_group("BulletCount").size()
	_process_option_behavior(delta)

# === OPTIONS ===
func _process_option_behavior(delta: float) -> void:
	var parent = get_parent()
	var parentDelta = parent.global_position - prevParentPos
	prevParentPos = parent.global_position
	
	var dir := Vector2.UP
	var GatoStyle = parent.GatoStyle
	var StyleEnum = parent.StyleEnum

	if INPUT.fireHold:
		match GatoStyle:
			StyleEnum.RANGE: _range_hold(parent, dir, delta)
			StyleEnum.DAMAGE: _damage_hold(parent, dir, delta)
			StyleEnum.CLASSIC: _classic_hold(dir, delta)
	else:
		global_position -= parentDelta
		match OptionType:
			OptionEnum.SIDES:
				followDelay = 15
				
				var effectiveTargetPos = targetPos
				var baseDeviation = 10 * offSign if GatoStyle == StyleEnum.RANGE else 0
				
				if GatoStyle == StyleEnum.RANGE:
					var maxRotationDegrees: float = 15.0
					var targetRotation = deg_to_rad(INPUT.xAxis * maxRotationDegrees)
					
					# Suavizamos el ángulo hacia el objetivo
					var rotationLerpSpeed: float = 4.0   # ajusta para más/menos inercia
					currentRotationAngle = lerp_angle(currentRotationAngle, targetRotation, rotationLerpSpeed * delta)
					
					effectiveTargetPos = targetPos.rotated(currentRotationAngle)
					
					# deviationAngle combina el valor base + el ángulo de rotación actual (en grados)
					# Si las balas se desvían al revés → cámbialo a: baseDeviation - rad_to_deg(currentRotationAngle)
					deviationAngle = baseDeviation + rad_to_deg(currentRotationAngle)
				
				else:
					deviationAngle = baseDeviation
				
				position = position.lerp(effectiveTargetPos, followDelay * delta)
			OptionEnum.FOLLOW:
				followDelay = 5
				deviationAngle = 0
				if targetNode and is_instance_valid(targetNode) and (INPUT.xAxis != 0 or INPUT.yAxis != 0):
					global_position = global_position.lerp(targetNode.global_position, followDelay * delta)

# === ESTILOS ===
func _range_hold(parent: Node2D, dir: Vector2, delta: float) -> void:
	var enemy = _get_closest_enemy()
	dir = (enemy.global_position - parent.global_position).normalized() if enemy else Vector2.UP
	var distance := 50.0
	deviationAngle = 0
	
	# === Posición visual desplazada lateralmente
	var targetPosition = parent.global_position + dir * distance
	var offsetDir := dir.orthogonal().normalized()
	targetPosition += offsetDir * -offSign * sideOffset
	
	global_position = global_position.lerp(targetPosition, followDelay * delta)
	followDelay = 15
	
	if canFire and activeBullets < maxBullets:
		await _fire_burst(dir, bulletScene)

func _damage_hold(parent: Node2D, dir: Vector2, delta: float) -> void:
	var distance := 75.0
	var nSideOffset = sideOffset * 1.5
	
	# Calculamos la velocidad efectiva: lenta cerca del centro (currLatOffset ~ 0), rápida en extremos
	var ratio = abs(currLatOffset) / nSideOffset
	var minSpeedFactor: float = 0.3   # 0.3 = 30% de oscSpeed en centro (ajusta para más/menos pausa)
	var effectiveSpeed = oscSpeed * (minSpeedFactor + (1 - minSpeedFactor) * ratio)
	
	# Actualizar el offset lateral de manera cíclica con velocidad variable
	currLatOffset += moveDir * effectiveSpeed * delta
	
	if currLatOffset >= nSideOffset:
		currLatOffset = nSideOffset
		moveDir = -1
	elif currLatOffset <= -nSideOffset:
		currLatOffset = -nSideOffset
		moveDir = 1
	
	# === Posición visual desplazada lateralmente
	var targetPosition = parent.global_position + dir * distance
	var offsetDir := dir.orthogonal().normalized()
	targetPosition += offsetDir * currLatOffset
	
	global_position = global_position.lerp(targetPosition, followDelay * delta)
	followDelay = 15
	
	if canFire and activeBullets < maxBullets:
		await _fire_burst(dir, bulletScene)

func _classic_hold(dir: Vector2, delta: float) -> void:
	followDelay = 5
	deviationAngle = 0
	
	if targetNode and is_instance_valid(targetNode):
		var targetPos = targetNode.global_position
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
		
		# movemos suavemente hacia la posición ideal
		global_position = global_position.lerp(idealPos, speedFactor * delta)
	
	if canFire and activeBullets < maxBullets:
		await _fire_burst(dir, bulletScene)

# === AUXILIAR ===
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
