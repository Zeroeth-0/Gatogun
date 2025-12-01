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

# === ESTADO INTERNO ===
var prevParentPos: Vector2

# === FLUJO DE COMPORTAMIENTO ===
func _ready() -> void:
	baseLvl = 0.0
	prevParentPos = get_parent().global_position

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
			StyleEnum.CLASSIC: _classic_hold(dir)
	else:
		global_position -= parentDelta
		match OptionType:
			OptionEnum.SIDES:
				followDelay = 15
				if GatoStyle == StyleEnum.RANGE: deviationAngle = 10 * offSign
				else: deviationAngle = 0
				position = position.lerp(targetPos, followDelay * delta)
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
	var distance := 50.0
	
	# === Posición visual desplazada lateralmente
	var targetPosition = parent.global_position + dir * distance
	var offsetDir := dir.orthogonal().normalized()
	targetPosition += offsetDir * -offSign * sideOffset
	
	global_position = global_position.lerp(targetPosition, followDelay * delta)
	followDelay = 15
	
	if canFire and activeBullets < maxBullets:
		await _fire_burst(dir, bulletScene)

func _classic_hold(dir: Vector2) -> void:
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
