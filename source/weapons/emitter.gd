extends Marker2D

# ------------------------------------------------ Bullet ------------------------------------------------
@export_category("BULLET")
@export var bulletScene: PackedScene
@export_range(-300, 300, 50) var speed: float = 200

@export_group("DIRECTION")
enum Type { NONE, AIM, GRAVITY, LEFT, RIGHT, RANDOM }
@export var type: Type = Type.NONE
@export_range(0, 1, 0.1) var gravIntensity: float = 0
@export_range(0, 360, 45) var deviationAngle: int = 45
@export_range(0, 5, 0.5) var dirStartTime: float
@export_range(0, 5, 0.5) var dirDuration: float = 5

@export_group("FIRST CHANGE SPEED")
@export_range(-300, 300, 50) var fstNewSpeed: int = 200
@export_range(0, 5, 0.5) var fstStartTime: float

@export_group("SECOND CHANGE SPEED")
@export_range(-300, 300, 50) var sndNewSpeed: int = 200
@export_range(0, 5, 0.5) var sndStartTime: float

# ------------------------------------------------ Weapon ------------------------------------------------
@export_category("WEAPON")
@export_group("DIRECTION")
enum Direction { NORTH, WEST, SOUTH, EAST, NWEST, NEAST, SWEST, SEAST }
@export var directionEnum: Direction = Direction.SOUTH

var DIRECTION_MAP = {
	Direction.NORTH: Vector2(0, -1),
	Direction.SOUTH: Vector2(0, 1),
	Direction.WEST: Vector2(-1, 0),
	Direction.EAST: Vector2(1, 0),
	Direction.NWEST: Vector2(-1, -1).normalized(),
	Direction.NEAST: Vector2(1, -1).normalized(),
	Direction.SWEST: Vector2(-1, 1).normalized(),
	Direction.SEAST: Vector2(1, 1).normalized()
}
var direction: Vector2 = Vector2(0, 1)
@export var aimAtPlayer: bool = false
@export var parallel: bool = false
@export_range(-50, 50, 5) var steepness: int = 0

@export_group("ROTATION")
@export var burstRotation: bool = false
@export_range(0, 180, 45) var rotationAngle: int = 0
@export_range(-150, 150, 10) var rotationSpeed: int = 0
@export var pingPong: bool = false
@export var centerStart: bool = true

# ------------------------------------------------ Burst ------------------------------------------------
@export_category("BURST")
@export_range(1, 16, 1) var arms: int = 1
@export_range(1, 10, 1) var burstCount: int = 1
@export_range(0, 1, 0.05) var bulletInterval: float = 0.1
@export_range(0, 5, 0.5) var warmUp: float = 1.0
@export_range(0, 450, 50) var distanceCenter: int = 0

@export_group("SPREAD")
@export_range(0, 360, 15) var spreadAngle: float = 45.0
@export_range(0, 600, 100) var spreadOffset: int = 100
enum SpeedVar { BULLET, ARM }
@export var speedVar: SpeedVar = SpeedVar.BULLET
@export_range(0.9, 1.1, 0.02) var speedVariation: float = 1
@export var useSymmetry: bool = false

@export_group("PROBABILITY")
@export_range(0, 100, 10) var randomAngle: int = 0
@export_range(0, 100, 10) var randomOffset: int = 0
@export_range(0, 0.9, 0.1) var randomSpeed: float = 0

@export_group("REPEATER")
@export_range(1, 8, 1) var repeatCount: int = 1
@export_range(0, 360, 45) var repeatAngle: int = 360
@export var keepSpeed: bool = false

# Random number generator
var rng = RandomNumberGenerator.new()
var rotationDirection = 1
var stopRotation = false
var playerPos: Vector2 = Vector2()

func _ready() -> void:
	direction = DIRECTION_MAP.get(directionEnum)
	shoot()

func _physics_process(delta: float) -> void:
	if not stopRotation: rotation_degrees += rotationSpeed * delta * rotationDirection
	handle_rotation()

func handle_rotation() -> void:
	var adjAngle = rotationAngle / 2.0 if centerStart else rotationAngle
	var nullAngle = -rotationAngle / 2.0 if centerStart else 0
	
	if pingPong:
		if rotation_degrees >= adjAngle: rotationDirection = -1
		elif rotation_degrees <= nullAngle: rotationDirection = 1
	elif rotation_degrees >= rotationAngle and rotationAngle < 360: rotationDirection = 0

# Start shooting bullets
func shoot() -> void:
	while true:
		await get_tree().create_timer(warmUp).timeout
		var newSpeed = speed
		if not burstRotation: stopRotation = true
		
		if aimAtPlayer: playerPos = GETPLAYER.get_player()
		
		for i in burstCount:
			if speedVar == SpeedVar.BULLET: newSpeed *= speedVariation
			fire(newSpeed)
			await get_tree().create_timer(bulletInterval).timeout
		
		if not burstRotation: stopRotation = false

# Fire bullets
func fire(newSpeed: float) -> void:
	var eachSpreadOffset = spreadOffset / float(arms)
	var eachArmAngle = spreadAngle / float(arms) if spreadAngle == 360  else spreadAngle / float(arms - 1)
	var offsetCorrection = eachSpreadOffset / 2 if arms % 2 == 0  else 0.0
	
	for r in range(repeatCount):
		var repeatRotation = repeatAngle / float(repeatCount) * r
		
		for i in range(arms):
			if speedVar == SpeedVar.ARM: newSpeed *= speedVariation
			
			var shootDir = direction.rotated(rotation + deg_to_rad(repeatRotation))
			var shootPos = global_position
			
			if aimAtPlayer: shootDir = (playerPos - shootPos).normalized()
			
			if parallel: handle_parallel_shooting(i, eachSpreadOffset, shootDir, shootPos, offsetCorrection)
			else:
				var angleOffset = eachArmAngle * i - spreadAngle / 2 + rng.randf_range(-randomAngle, randomAngle)
				if arms != 1: shootDir = shootDir.rotated(deg_to_rad(angleOffset))
				if spreadAngle == 360: shootDir *= -1
			
			var finalSpeed = newSpeed * rng.randf_range(1 - randomSpeed, 1 + randomSpeed)
			
			if useSymmetry: shoot_symmetric_bullets(shootDir, shootPos, finalSpeed)
			else: shoot_bullet(shootDir, shootPos, finalSpeed)

# Handle parallel shooting
func handle_parallel_shooting(i: int, eachSpreadOffset: float, shootDir: Vector2, shootPos: Vector2, offsetCorrection: float) -> void:
	var offset = ((i - arms / 2.0) * eachSpreadOffset) + rng.randf_range(-randomOffset, randomOffset)
	var steepnessFactor = abs(i - (arms - 1) / 2.0) * steepness
	shootPos += shootDir * steepnessFactor
	var steepnessDirAdjustment = steepnessFactor * 0.01
	shootDir = shootDir.rotated(deg_to_rad(steepnessDirAdjustment))
	shootPos += shootDir.orthogonal() * (offset + offsetCorrection)

# Shoot symmetric bullets
func shoot_symmetric_bullets(shootDir: Vector2, shootPos: Vector2, speed: float) -> void:
	shoot_bullet(shootDir.rotated(deg_to_rad(45)), shootPos, speed)
	shoot_bullet(shootDir.rotated(deg_to_rad(45)) * Vector2(-1, 1), shootPos, speed)

# Shoot a single bullet
func shoot_bullet(shootDir: Vector2, shootPos: Vector2, speed: float) -> void:
	var bullet = bulletScene.instantiate() as Node2D
	bullet.position = shootPos + shootDir * distanceCenter
	bullet.set_properties(shootDir.normalized(), speed)
	bullet.modify_direction(type, gravIntensity, deviationAngle, dirStartTime, dirDuration)
	bullet.modify_speed(fstNewSpeed, fstStartTime, sndNewSpeed, sndStartTime)
	get_parent().add_child(bullet)
