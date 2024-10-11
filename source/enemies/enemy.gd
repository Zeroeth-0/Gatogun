extends CharacterBody2D

# Definir los tipos de movimiento
enum MoveType { STRAIGHT, # Implementado
				SINUSOIDAL,
				OSCILLATE,
				BREATH,
				BLOCK,
				CURVE, # Implementado
				CIRCULAR, # Implementado
				TOWARDS_PLAYER, # Implementado
				LEAVE, # Implementado
				LEAVE_SIDE, # Implementado
				STILL # Implementado
}

# Parámetros generales
@export var intensity = 10
enum Direction { NORTH, WEST, SOUTH, EAST }
@export var directionEnum: Direction = Direction.SOUTH # Implementado
var DIRECTION_MAP = {
	Direction.NORTH: Vector2(0, -1).normalized(),
	Direction.SOUTH: Vector2(0, 1).normalized(),
	Direction.WEST: Vector2(-1, 0).normalized(),
	Direction.EAST: Vector2(1, 0).normalized()
}
var direction: Vector2 = Vector2(0, 1)
enum Handedness { LEFT, RIGHT }
@export var handedness = Handedness.RIGHT
@export_range(0, 90, 15) var deviationAngle: int = 45

@export_category("CHILDHOOD")
@export var childHood : MoveType = MoveType.STRAIGHT
@export var childDur = 1.0
@export var childSpeed = 100
@export var adultInv: bool = false

@export_category("ADULTHOOD")
@export var adultHood : MoveType = MoveType.STRAIGHT
@export var adultDur = 1.0
@export var adultSpeed = 100
@export var oldInv: bool = false

@export_category("OLD AGE")
@export var oldAge : MoveType = MoveType.STRAIGHT
@export var oldSpeed = 100

# Etapa actual
var currentStage = "childhood"
var stageTimer = 0.0
var speed = 200
var hSide
var currDir

# Configurar el movimiento inicial
func _ready():
	direction = DIRECTION_MAP.get(directionEnum)
	stageTimer = 0.0
	hSide = 1 if handedness == Handedness.RIGHT else -1
	currDir = direction

# Manejo del tiempo y cambios de fase
func _process(delta):
	stageTimer += delta
	
	match currentStage:
		"childhood":
			if stageTimer > childDur:
				currDir = direction
				if adultInv: hSide *= -1
				enter_next_stage("adulthood")
			else:
				speed = childSpeed
				apply_movement(childHood, childDur, delta)
		"adulthood":
			if stageTimer > adultDur:
				currDir = direction
				if oldInv: hSide *= -1
				enter_next_stage("old_age")
			else:
				speed = adultSpeed
				apply_movement(adultHood, adultDur, delta)
		"old_age":
			speed = oldSpeed
			apply_movement(oldAge, adultDur, delta)

# Selección de comportamiento según el tipo de movimiento
func apply_movement(moveType, dur, delta):
	match moveType:
		MoveType.STRAIGHT: move_straight()
		MoveType.SINUSOIDAL: move_sinusoidal(delta)
		MoveType.OSCILLATE: move_oscillate(delta)
		MoveType.BREATH: move_breath(delta)
		MoveType.BLOCK: move_block(delta)
		MoveType.CURVE: move_curve(dur, delta)
		MoveType.CIRCULAR: move_circular(dur, delta)
		MoveType.TOWARDS_PLAYER: move_towards_player()
		MoveType.LEAVE: move_leave()
		MoveType.LEAVE_SIDE: move_leave_side(delta)
		MoveType.STILL: move_still()

# Cambiar a la siguiente fase de comportamiento
func enter_next_stage(nextStage):
	currentStage = nextStage
	stageTimer = 0.0

# Behaviors

func move_straight():
	velocity = direction * speed
	move_and_slide()

func move_sinusoidal(delta):
	pass
	move_and_slide()

func move_oscillate(delta):
	pass
	move_and_slide()

func move_breath(delta):
	pass
	move_and_slide()

func move_block(delta):
	pass
	move_and_slide()

func move_curve(dur, delta):
	var rotationSpeed = deg_to_rad(deviationAngle) / dur
	if abs(direction.angle_to(currDir)) < deg_to_rad(deviationAngle):
		direction = direction.rotated(rotationSpeed * hSide * delta)
	velocity = direction * speed
	move_and_slide()

func move_circular(dur, delta):
	direction = direction.rotated(deg_to_rad(deviationAngle) * hSide * delta)
	velocity = direction * speed
	move_and_slide()

func move_towards_player():
	var playerPos = GETPLAYER.get_player()
	direction = (playerPos - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func move_leave():
	velocity = -direction * speed
	move_and_slide()

func move_leave_side(delta):
	var newDir = Vector2 (0, 0)
	match directionEnum:
		Direction.NORTH: newDir = Vector2(-hSide, 1)
		Direction.SOUTH: newDir = Vector2(-hSide, -1)
		Direction.WEST: newDir = Vector2(1, -hSide)
		Direction.EAST: newDir = Vector2(-1, -hSide)
	velocity = newDir * speed
	move_and_slide()

func move_still():
	velocity = SCROLL.get_scroll()
	move_and_slide()
