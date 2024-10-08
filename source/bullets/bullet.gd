extends Area2D

# Properties
@export var speed: float = 200.0
@export var direction: Vector2 = Vector2.DOWN
@export var rotationSpeed: float = 360.0
@export var sprite: Sprite2D

# Direction
enum Type { NONE, AIM, GRAVITY, LEFT, RIGHT, RANDOM }
var type: Type = Type.NONE
var gravIntensity: float = 0
var deviationAngle: int = 0
var dirStartTime: float = 0.0
var dirDuration: float = 1.0

# Speed
var fstNewSpeed: int = 200
var fstStartTime: float = 0.0
var sndNewSpeed: int = 200
var sndStartTime: float = 0.0

var elapsedTime: float = 0.0
var velocity: Vector2
var grav: bool = false
var acceleration: Vector2 = Vector2.ZERO  # Vector de aceleración

func _ready() -> void:
	velocity = direction * speed
	sndStartTime += fstStartTime

# Set direction and speed for the bullet
func set_properties(newDirection: Vector2, newSpeed: float) -> void:
	direction = newDirection
	speed = newSpeed

func modify_direction(newType: Type, newGravIntensity: float, newDeviationAngle: int,
						newDirStartTime: float, newDirDuration: float) -> void:
	type = newType
	gravIntensity = newGravIntensity
	deviationAngle = newDeviationAngle
	dirStartTime = newDirStartTime
	dirDuration = newDirDuration

func modify_speed(newFstNewSpeed: int, newFstStartTime: float, newSndNewSpeed: int, 
					newSndStartTime: float) -> void:
	fstNewSpeed = newFstNewSpeed
	fstStartTime = newFstStartTime
	sndNewSpeed = newSndNewSpeed
	sndStartTime = newSndStartTime

func _physics_process(delta: float) -> void:
	elapsedTime += delta
	
	if !grav: velocity = direction * speed
	else: apply_gravity(delta)
	
	update_direction(delta)
	update_speed()
	
	# Bullet movement
	if grav: velocity += acceleration * delta
	position += velocity * delta
	sprite.rotation_degrees -= rotationSpeed * delta

func apply_gravity(delta: float) -> void:
	acceleration.y = gravity * gravIntensity

# Adjust bullet's direction based on its type
func update_direction(delta: float) -> void:
	if elapsedTime >= dirStartTime and elapsedTime <= dirStartTime + dirDuration:
		match type:
			Type.AIM:
				var playerPos = GETPLAYER.get_player()
				direction = (playerPos - global_position).normalized()
			Type.GRAVITY:
				grav = true
			Type.LEFT:
				direction = direction.rotated(deg_to_rad(deviationAngle) * delta)
			Type.RIGHT:
				direction = direction.rotated(deg_to_rad(-deviationAngle) * delta)
			Type.RANDOM:
				var randomAngle = randf_range(-deviationAngle, deviationAngle)
				direction = direction.rotated(deg_to_rad(randomAngle) * delta)

# Change bullet speed according to the configured intervals
func update_speed() -> void:
	if elapsedTime >= fstStartTime and elapsedTime <= sndStartTime:
		speed = fstNewSpeed
	elif elapsedTime >= sndStartTime:
		speed = sndNewSpeed
