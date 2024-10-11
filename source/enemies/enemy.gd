extends CharacterBody2D

# Definir los tipos de movimiento
enum MoveType { STRAIGHT, # Implementado
				SINUSOIDAL, # Implementado
				OSCILLATE, # Implementado
				BREATH, # Implementado
				BLOCK, # Implementado
				CURVE, # Implementado
				CIRCULAR, # Implementado
				TOWARDS_PLAYER, # Implementado
				LEAVE, # Implementado
				LEAVE_SIDE, # Implementado
				STILL # Implementado
}

# Parámetros generales
@export var intensity = 1
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
@export_range(0, 90, 15) var deviationAngle: int = 90

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
var extraVel: Vector2 = Vector2.ZERO
var hSide
var currDir

# Configurar el movimiento inicial
func _ready():
	direction = DIRECTION_MAP.get(directionEnum)
	stageTimer = 0.0
	hSide = -1 if handedness == Handedness.RIGHT else 1
	currDir = direction

# Manejo del tiempo y cambios de fase
func _process(delta):
	stageTimer += delta
	velocity = SCROLL.get_scroll() + extraVel
	
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
	var frequency = 2.0  # Frecuencia de la oscilación
	var amplitude = 50.0  # Amplitud de la oscilación
	var offset = sin(frequency * stageTimer + PI / 2) * amplitude * intensity * hSide  # Desfase con hSide
	var perpendicular_dir = Vector2(-direction.y, direction.x)  # Perpendicular a la dirección actual
	
	# Ajusta la velocidad y dirección
	velocity = (direction * speed) + (perpendicular_dir * offset)
	move_and_slide()

func move_oscillate(delta):
	var frequency = 2.0  # Frecuencia de la oscilación
	var amplitude = 50.0  # Amplitud de la oscilación
	var offset = sign(sin(frequency * stageTimer + PI / 2)) * amplitude * intensity * hSide  # Picos en vez de curva
	var perpendicular_dir = Vector2(-direction.y, direction.x)  # Perpendicular a la dirección actual
	
	# Ajusta la velocidad y dirección
	velocity = (direction * speed) + (perpendicular_dir * offset)
	move_and_slide()

func move_breath(delta):
	var last_move_direction = 1  # Mantiene la última dirección para alternar
	var frequency = 1.0  # Frecuencia del movimiento
	var horizontal_amplitude = 10.0  # Reducir la amplitud horizontal
	var vertical_amplitude = 6.0  # Reducir la amplitud vertical

	# Movimiento en forma de ocho con alternancia suave
	var horizontal_offset = cos(frequency * stageTimer) * horizontal_amplitude * last_move_direction
	var vertical_offset = sin(frequency * stageTimer * 1.5) * vertical_amplitude  # Frecuencia ajustada para suavidad

	# Crear una dirección temporal combinando ambas
	var temp_direction = Vector2(horizontal_offset, vertical_offset) * intensity / 5  # Limitar el impacto de intensity

	# Alternar la dirección para suavidad continua
	if cos(frequency * stageTimer) > 0:
		last_move_direction = 1
	else:
		last_move_direction = -1

	# Aplicar la velocidad suavizada
	velocity = temp_direction
	move_and_slide()

func move_block(delta):
	var player_pos = GETPLAYER.get_player()  # Obtén la posición del jugador
	
	# Crear una dirección temporal para no afectar la dirección original
	var temp_direction = Vector2()

	if directionEnum == Direction.NORTH or directionEnum == Direction.SOUTH:
		# Movimiento horizontal (igualar en el eje X)
		var target_x = player_pos.x
		temp_direction.x = (target_x - global_position.x) * intensity * delta
		temp_direction.y = 0  # Mantener el movimiento solo en el eje X
	elif directionEnum == Direction.EAST or directionEnum == Direction.WEST:
		# Movimiento vertical (igualar en el eje Y)
		var target_y = player_pos.y
		temp_direction.y = (target_y - global_position.y) * intensity * delta
		temp_direction.x = 0  # Mantener el movimiento solo en el eje Y
	
	# Usar la dirección temporal para el movimiento
	extraVel = temp_direction * speed
	move_and_slide()

func move_curve(dur, delta):
	var rotationSpeed = deg_to_rad(deviationAngle) / dur
	if abs(direction.angle_to(currDir)) < deg_to_rad(deviationAngle):
		direction = direction.rotated(rotationSpeed * hSide * delta)
	extraVel = direction * speed
	move_and_slide()

func move_circular(dur, delta):
	direction = direction.rotated(deg_to_rad(deviationAngle) * hSide * delta)
	extraVel = direction * speed
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
	extraVel = Vector2.ZERO
	move_and_slide()
