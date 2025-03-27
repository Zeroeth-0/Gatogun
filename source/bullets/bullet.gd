extends Area2D

# Properties
var speed: int = 250
var direction: Vector2
var rotationSpeed: int = 360
@export var sprite: Sprite2D
@export var revenge: bool = false
@export var medal: PackedScene = preload("res://scenes/items/medal.tscn")
var revHealth: int = 20

# Direction
enum Type { NONE, AIM, GRAVITY, LEFT, RIGHT, RANDOM }
var type: Type = Type.NONE
var gravIntensity: float = 0
var deviationAngle: int = 0
var dirStartTime: float = 0.0
var dirDuration: float = 1.0

# Speed
var modifySpeed: bool = false
var fstNewSpeed: int = speed
var fstStartTime: float = 0.0
var sndNewSpeed: int = speed
var sndStartTime: float = 0.0

var elapsedTime: float = 0.0
var velocity: Vector2
var grav: bool = false
var acceleration: Vector2 = Vector2.ZERO  # Vector de aceleración

func _ready() -> void:
	if revenge: direction = (GETPLAYER.get_player() - position).normalized()
	velocity = direction * speed
	sndStartTime += fstStartTime

# Set direction and speed for the bullet
func set_properties(newDirection: Vector2, newSpeed: int) -> void:
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
	modifySpeed = true
	fstNewSpeed = newFstNewSpeed
	fstStartTime = newFstStartTime
	sndNewSpeed = newSndNewSpeed
	sndStartTime = newSndStartTime

func _process(delta: float) -> void:
	elapsedTime += delta
	
	if !grav: velocity = direction * speed
	else: apply_gravity()
	
	update_direction(delta)
	if modifySpeed: update_speed()
	
	# Bullet movement
	if grav: velocity += acceleration * delta
	position += velocity * delta
	sprite.rotation_degrees -= rotationSpeed * delta

func apply_gravity() -> void:
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

func cancel():
	var item = medal.instantiate()
	get_tree().current_scene.call_deferred("add_child", item)
	item.position = global_position  
	queue_free()

func _on_area_exited(area):
	if area.is_in_group("Free"): queue_free()

func _on_area_entered(area):
	if area.is_in_group("Fire") and revenge:
		revHealth -= 1
		if revHealth <= 0: cancel()
