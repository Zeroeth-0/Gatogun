extends Area2D

# === PROPIEDADES INTERNAS ===
var speed := 400
var direction := Vector2.ZERO
var rotationSpeed := 400

# === NUEVO: Modo de rotación del sprite ===
enum SpriteRotationMode {
	SPIN_CONTINUOUS,     # Gira continuamente (como antes)
	FACE_MOVEMENT        # Siempre apunta hacia donde se mueve
}

@export var sprite_rotation_mode : SpriteRotationMode = SpriteRotationMode.SPIN_CONTINUOUS

# === CONFIGURACIÓN DE DIRECCIÓN ===
enum DirectionType { NONE, AIM, GRAVITY, LEFT, RIGHT, RANDOM }
@export var directionType := DirectionType.NONE
@export var gravIntensity := 0.0
@export var deviationAngle := 0
@export var dirStartTime := 0.0
@export var dirDuration := 1.0

# === CONFIGURACIÓN DE VELOCIDAD TEMPORAL ===
@export var modifySpeed := false
@export var fstNewSpeed := speed
@export var fstStartTime := 0.0
@export var sndNewSpeed := speed
@export var sndStartTime := 0.0

# === ESTADO INTERNO ===
var elapsedTime := 0.0
var velocity := Vector2.ZERO
var useGravity := false
var acceleration := Vector2.ZERO
var isCancelled := false

# === FLUJO DE COMPORTAMIENTO ===
func _ready() -> void:
	velocity = direction * speed
	sndStartTime += fstStartTime


func _process(delta: float) -> void:
	elapsedTime += delta
	
	# Actualiza velocidad base o con gravedad
	velocity = direction * speed if !useGravity else velocity
	if useGravity: _apply_gravity()
	
	_update_direction(delta)
	if modifySpeed: _update_speed()
	
	# Movimiento de la bala
	if useGravity:
		velocity += acceleration * delta
	
	position += velocity * delta
	
	# ── Rotación del sprite según el modo seleccionado ──
	match sprite_rotation_mode:
		SpriteRotationMode.SPIN_CONTINUOUS:
			$Sprite2D.rotation_degrees -= rotationSpeed * delta
		
		SpriteRotationMode.FACE_MOVEMENT:
			if velocity.length_squared() > 0.001:   # evita errores cuando velocity ≈ 0
				$Sprite2D.rotation = velocity.angle() - deg_to_rad(90)


# === CONFIGURACIÓN EXTERNA ===
func set_properties(newDirection: Vector2, newSpeed: int) -> void:
	direction = newDirection
	speed = newSpeed


func modify_direction(newType: DirectionType, newGravIntensity: float, newDeviationAngle: int,
					  newStartTime: float, newDuration: float) -> void:
	directionType = newType
	gravIntensity = newGravIntensity
	deviationAngle = newDeviationAngle
	dirStartTime = newStartTime
	dirDuration = newDuration


func modify_speed(firstSpeed: int, firstStart: float, secondSpeed: int, secondStart: float) -> void:
	modifySpeed = true
	fstNewSpeed = firstSpeed
	fstStartTime = firstStart
	sndNewSpeed = secondSpeed
	sndStartTime = secondStart


# === LÓGICA DE COMPORTAMIENTO ===
func _apply_gravity() -> void:
	acceleration.y = gravity * gravIntensity   # asumiendo que 'gravity' es una variable global o de proyecto


func _update_direction(delta: float) -> void:
	if elapsedTime < dirStartTime or elapsedTime > dirStartTime + dirDuration:
		return
	
	match directionType:
		DirectionType.AIM:
			direction = (GAME.get_player() - global_position).normalized()
		
		DirectionType.GRAVITY:
			useGravity = true
		
		DirectionType.LEFT:
			direction = direction.rotated(deg_to_rad(deviationAngle) * delta)
		
		DirectionType.RIGHT:
			direction = direction.rotated(deg_to_rad(-deviationAngle) * delta)
		
		DirectionType.RANDOM:
			var angle = DRNG.drandf_range(-deviationAngle, deviationAngle)
			direction = direction.rotated(deg_to_rad(angle) * delta)


func _update_speed() -> void:
	if elapsedTime >= fstStartTime and elapsedTime <= sndStartTime:
		speed = fstNewSpeed
	elif elapsedTime >= sndStartTime:
		speed = sndNewSpeed


# Compensación movimiento cámara
func _enter_tree():
	CAMERA.tracked_nodes.append(self)


func _exit_tree():
	CAMERA.tracked_nodes.erase(self)
