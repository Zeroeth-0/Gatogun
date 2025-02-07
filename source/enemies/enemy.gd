extends CharacterBody2D

# Definir los tipos de movimiento
enum MoveType { STRAIGHT,
				SINUSOIDAL,
				OSCILLATE,
				BREATH,
				BLOCK,
				CENTER,
				CURVE,
				CIRCULAR,
				TOWARDS_PLAYER,
				LEAVE,
				LEAVE_SIDE,
				DIAGONAL,
				STILL
}

# Parámetros generales
@export var intensity = 1
enum Direction { NORTH, WEST, SOUTH, EAST }
@export var directionEnum: Direction = Direction.SOUTH
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
@export var scrollFollow: bool = false
@export var isGround: bool = false
@export var health: int
var canDie: bool = false
var canShoot: bool = true

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
var rng = RandomNumberGenerator.new()
var rand_side = 1 if rng.randf() < 0.5 else -1

var cantShoot: bool = false

# Configurar el movimiento inicial
func _ready():
	direction = DIRECTION_MAP.get(directionEnum)
	stageTimer = 0.0
	hSide = -1 if handedness == Handedness.RIGHT else 1
	currDir = direction
	if isGround: $Hurtbox.add_to_group("Ground")
	else: $Hitbox.add_to_group("Damage")

# Manejo del tiempo y cambios de fase
func _process(delta):
	die()
	stageTimer += delta
	if scrollFollow: velocity = SCROLL.get_scroll() + extraVel
	else: velocity = extraVel
	
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
		MoveType.STRAIGHT: move_straight(delta)
		MoveType.SINUSOIDAL: move_sinusoidal(delta)
		MoveType.OSCILLATE: move_oscillate(delta)
		MoveType.BREATH: move_breath(delta)
		MoveType.BLOCK: move_block(delta)
		MoveType.CENTER: move_center(delta)
		MoveType.CURVE: move_curve(dur, delta)
		MoveType.CIRCULAR: move_circular(dur, delta)
		MoveType.TOWARDS_PLAYER: move_towards_player()
		MoveType.LEAVE: move_leave()
		MoveType.LEAVE_SIDE: move_leave_side(delta)
		MoveType.DIAGONAL: move_diagonal()
		MoveType.STILL: move_still()

# Cambiar a la siguiente fase de comportamiento
func enter_next_stage(nextStage):
	currentStage = nextStage
	stageTimer = 0.0

func die():
	if health <= 0: queue_free()

# Behaviors

func move_straight(delta):
	extraVel = direction * speed
	move_and_slide()

func move_sinusoidal(delta):
	var frequency = 2.0  # Frecuencia de la oscilación
	var amplitude = 50.0  # Amplitud de la oscilación
	var offset = sin(frequency * stageTimer + PI / 2) * amplitude * intensity * hSide  # Desfase con hSide
	var perpendicular_dir = Vector2(-direction.y, direction.x)  # Perpendicular a la dirección actual
	
	# Ajusta la velocidad y dirección
	extraVel = (direction * speed) + (perpendicular_dir * offset)
	move_and_slide()

func move_oscillate(delta):
	var frequency = 2.0  # Frecuencia de la oscilación
	var amplitude = 50.0  # Amplitud de la oscilación
	var offset = sign(sin(frequency * stageTimer + PI / 2)) * amplitude * intensity * hSide  # Picos en vez de curva
	var perpendicular_dir = Vector2(-direction.y, direction.x)  # Perpendicular a la dirección actual
	
	# Ajusta la velocidad y dirección
	extraVel = (direction * speed) + (perpendicular_dir * offset)
	move_and_slide()

func move_breath(delta):
	var frequency = 2
	var horizontal_amplitude = 15.0
	var vertical_amplitude = 7.0

	# Movimiento en forma de ocho con alternancia suave
	var horizontal_offset = cos(frequency * stageTimer) * horizontal_amplitude * rand_side
	var vertical_offset = sin(frequency * stageTimer * 1.5) * vertical_amplitude

	# Crear una dirección temporal combinando ambas
	var temp_direction = Vector2(horizontal_offset, vertical_offset) * intensity

	# Aplicar la velocidad suavizada con aleatoriedad
	extraVel = temp_direction
	move_and_slide()

func move_block(delta):
	var player_pos = GETPLAYER.get_player()  # Obtén la posición del jugador
	
	# Crear una dirección temporal para no afectar la dirección original
	var temp_direction = Vector2()
	if directionEnum == Direction.NORTH or directionEnum == Direction.SOUTH:
		# Movimiento horizontal (igualar en el eje X)
		var target_x = player_pos.x
		temp_direction.x = (target_x - global_position.x) * intensity / 10 * delta
		temp_direction.y = 0  # Mantener el movimiento solo en el eje X
	elif directionEnum == Direction.EAST or directionEnum == Direction.WEST:
		# Movimiento vertical (igualar en el eje Y)
		var target_y = player_pos.y
		temp_direction.y = (target_y - global_position.y) * intensity / 10 * delta
		temp_direction.x = 0  # Mantener el movimiento solo en el eje Y
	
	# Usar la dirección temporal para el movimiento
	extraVel = temp_direction * speed
	move_and_slide()

func move_center(delta):
	var center_pos = get_viewport().get_visible_rect().size / 2  # Obtén la posición del jugador
	
	# Crear una dirección temporal para no afectar la dirección original
	var temp_direction = Vector2()
	if directionEnum == Direction.NORTH or directionEnum == Direction.SOUTH:
		# Movimiento horizontal (igualar en el eje X)
		var target_x = center_pos.x
		temp_direction.x = (target_x - global_position.x) * intensity / 10 * delta
		temp_direction.y = 0  # Mantener el movimiento solo en el eje X
	elif directionEnum == Direction.EAST or directionEnum == Direction.WEST:
		# Movimiento vertical (igualar en el eje Y)
		var target_y = center_pos.y
		temp_direction.y = (target_y - global_position.y) * intensity / 10 * delta
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
	scrollFollow = false
	var playerPos = GETPLAYER.get_player()
	direction = (playerPos - global_position).normalized()
	extraVel = direction * speed
	move_and_slide()

func move_leave():
	scrollFollow = false
	extraVel = -direction * speed
	move_and_slide()

func move_leave_side(delta):
	scrollFollow = false
	var newDir = Vector2 (0, 0)
	match directionEnum:
		Direction.NORTH: newDir = Vector2(-hSide, 1)
		Direction.SOUTH: newDir = Vector2(-hSide, -1)
		Direction.WEST: newDir = Vector2(1, -hSide)
		Direction.EAST: newDir = Vector2(-1, -hSide)
	extraVel = newDir.normalized() * speed
	move_and_slide()

func move_diagonal():
	var newDir = Vector2 (0, 0)
	match directionEnum:
		Direction.NORTH: newDir = Vector2(-hSide * 1.5, -1)
		Direction.SOUTH: newDir = Vector2(-hSide * 2, 1)
		Direction.WEST: newDir = Vector2(-1, -hSide * 1.5)
		Direction.EAST: newDir = Vector2(1, -hSide * 1.5)
	extraVel = newDir.normalized() * speed
	move_and_slide()

func move_still():
	extraVel = Vector2.ZERO
	move_and_slide()

func _on_hurtbox_area_entered(area):
	if area.is_in_group("Fire") and canDie: health -= area.damage

func _on_hitbox_area_entered(area):
	if area.is_in_group("Play"): canDie = true

func _on_hitbox_area_exited(area):
	if area.is_in_group("Free"): queue_free()
