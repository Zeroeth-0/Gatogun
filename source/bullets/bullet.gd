extends Area2D

@export var speed: float = 200.0
@export var direction: Vector2 = Vector2.DOWN
@export var rotationSpeed: float = 360
@export var sprite: Sprite2D

enum Type { NONE, AIM, GRAVITY, LEFT, RIGHT, RANDOM }
var type: Type = Type.NONE
var deviationAngle: int = 0
var dirStartTime: float = 0
var dirDuration: float = 1.0

var fstNewSpeed: int = 200
var fstStartTime: float = 0

var sndNewSpeed: int = 200
var sndStartTime: float = 0

# Tiempo acumulado para las modificaciones de dirección y velocidad
var elapsed_time: float = 0.0
var velocity
var grav: bool = false

func _ready():
	velocity = direction * speed
	sndStartTime += fstStartTime

# Asigna propiedades de dirección y velocidad a la bala
func set_properties(newDirection: Vector2, newSpeed: float) -> void:
	direction = newDirection
	speed = newSpeed

func modify_direction(newType, newDeviationAngle, newDirStartTime, newDirDuration):
	type = newType
	deviationAngle = newDeviationAngle
	dirStartTime = newDirStartTime
	dirDuration = newDirDuration

func modify_speed(newFstNewSpeed, newFstStartTime, newSndNewSpeed, newSndStartTime):
	fstNewSpeed = newFstNewSpeed
	fstStartTime = newFstStartTime
	sndNewSpeed = newSndNewSpeed
	sndStartTime = newSndStartTime

func _physics_process(delta: float) -> void:
	elapsed_time += delta
	if !grav: velocity = direction * speed
	
	# Modificar dirección según el tipo especificado
	update_direction(delta)

	# Aplicar cambios de velocidad
	update_speed()

	# Movimiento de la bala
	position += velocity * delta
	sprite.rotation_degrees -= rotationSpeed * delta

# Cambia la dirección de la bala según el tipo configurado
func update_direction(delta: float) -> void:
	if elapsed_time >= dirStartTime and elapsed_time <= dirStartTime + dirDuration:
		match type:
			# AIM: Apunta directamente al jugador desde el inicio
			Type.AIM:
				var player_pos = GETPLAYER.get_player()
				direction = (player_pos - global_position).normalized()

			# GRAVITY: Aplica una fuerza de gravedad en el eje Y, como si fuera un rigidbody
			Type.GRAVITY:
				grav = true
				dirDuration = 5
				velocity.y += gravity / 5 * delta

			# LEFT: Gira suavemente hacia la izquierda sin afectar la velocidad
			Type.LEFT:
				direction = direction.rotated(deg_to_rad(deviationAngle) * delta)

			# RIGHT: Gira suavemente hacia la derecha sin afectar la velocidad
			Type.RIGHT:
				direction = direction.rotated(deg_to_rad(-deviationAngle) * delta)

			# RANDOM: Gira suavemente en una dirección aleatoria dentro del rango
			Type.RANDOM:
				var random_angle = randf_range(-deviationAngle, deviationAngle)
				direction = direction.rotated(deg_to_rad(random_angle) * delta)

# Cambia la velocidad de la bala según los cambios de velocidad configurados
func update_speed() -> void:
	if elapsed_time >= fstStartTime and elapsed_time <= sndStartTime:
		speed = fstNewSpeed

	if elapsed_time >= sndStartTime:
		speed = sndNewSpeed
