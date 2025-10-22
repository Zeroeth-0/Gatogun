extends "res://source/weapons/burst_weapon.gd"

# === TIPOS DE OPTION ===
enum OptionEnum { SIDES, FOLLOW }

# === EXPORTS GENERALES ===
@export var OptionType: OptionEnum = OptionEnum.SIDES                           # Tipo de option
@export var targetPos: Vector2 = Vector2.ZERO
@export var targetNode: Node2D
@export_range(0, 20, 1) var followDelay: int = 15
@export var focusTarget: Vector2 = Vector2.ZERO
@export var isLinear: bool = false
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
	if followDelay > 0:
		_process_option_behavior(delta)

# === OPTIONS ===
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
		
		# === Posición visual desplazada lateralmente
		var targetPosition = parent.global_position + dir * distance
		var offsetDir := dir.orthogonal().normalized()
		targetPosition += offsetDir * -offSign * sideOffset
		
		global_position = global_position.lerp(targetPosition, followDelay * delta)
		followDelay = 15
		
		if canFire and activeBullets < maxBullets:
			await _fire_burst(dir, bulletScene)
	else:
		match OptionType:
			OptionEnum.SIDES:
				followDelay = 15
				if !isLinear: deviationAngle = 10 * offSign
				else: deviationAngle = 0
				position = position.lerp(targetPos, followDelay * delta)
			OptionEnum.FOLLOW:
				followDelay = 5
				deviationAngle = 0
				if targetNode and is_instance_valid(targetNode):
					global_position = global_position.lerp(targetNode.global_position, followDelay * delta)

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
