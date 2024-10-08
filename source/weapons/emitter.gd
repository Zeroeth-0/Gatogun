extends Marker2D

# ------------------------------------------------Bullet--------------------------------------------------

@export_category("BULLET")
@export var bulletScene: PackedScene
@export_range(-300, 300, 50) var speed: float = 200 # Implementado

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

# ------------------------------------------------Weapon--------------------------------------------------

@export_category("WEAPON")
@export_group("DIRECTION")
enum Direction { NORTH, WEST, SOUTH, EAST, NWEST, NEAST, SWEST, SEAST }
@export var directionEnum: Direction = Direction.SOUTH # Implementado
var DIRECTION_MAP = {
	Direction.NORTH: Vector2(0, -1).normalized(),
	Direction.SOUTH: Vector2(0, 1).normalized(),
	Direction.WEST: Vector2(-1, 0).normalized(),
	Direction.EAST: Vector2(1, 0).normalized(),
	Direction.NWEST: Vector2(-1, -1).normalized(),
	Direction.NEAST: Vector2(1, -1).normalized(),
	Direction.SWEST: Vector2(-1, 1).normalized(),
	Direction.SEAST: Vector2(1, 1).normalized()
}
var direction: Vector2 = Vector2(0, 1)
@export var aimAtPlayer: bool = false
@export var parallel: bool = false # Implementado
@export_range(-50, 50, 5) var steepness: int = 0 # Implementado

@export_group("ROTATION")
@export var burstRotation: bool = false # Implementado
@export_range(0, 180, 45) var rotationAngle: int = 0 # Implementado
@export_range(-150, 150, 10) var rotationSpeed: int = 0 # Implementado
@export var pingPong: bool = false # Implementado
@export var centerStart: bool = true # Implementado

# ------------------------------------------------Burst---------------------------------------------------

@export_category("BURST")
@export_range(1, 16, 1) var arms: int = 1 # Implementado
@export_range(1, 10, 1) var burstCount: int = 1 # Implementado
@export_range(0, 1, 0.05) var bulletInterval: float = 0.1 # Implementado
@export_range(0, 5, 0.5) var warmUp: float = 1.0 # Implementado
@export_range(0, 450, 50) var distanceCenter: int = 0 # Implementado

@export_group("SPREAD")
@export_range(0, 360, 15) var spreadAngle: float = 45.0 # Implementado
@export_range(0, 600, 0) var spreadOffset: int = 100 # Implementado
enum SpeedVar { BULLET, ARM }
@export var speedVar: SpeedVar = SpeedVar.BULLET # Implementado
@export_range(0.9, 1.1, 0.02) var speedVariation: float = 1 # Implementado
@export var useSymmetry: bool = false # Implementado

@export_group("PROBABILITY")
@export_range(0, 100, 10) var randomAngle: int = 0 # Implementado
@export_range(0, 100, 10) var randomOffset: int = 0 # Implementado
@export_range(0, 0.9, 0.1) var randomSpeed: float = 0 # Implementado

@export_group("REPEATER")
@export_range(1, 8, 1) var repeatCount: int = 1 # Implementado
@export_range(0, 360, 45) var repeatAngle: int = 360 # Implementado
@export var keepSpeed: bool = false # Implementado

var rng = RandomNumberGenerator.new()
var rotation_direction = 1
var stop_rotation = false
var player_pos: Vector2 = Vector2()

func _ready():
	direction = DIRECTION_MAP.get(directionEnum)
	shoot()

func _physics_process(delta):
	if not stop_rotation:
		rotation_degrees += rotationSpeed * delta * rotation_direction
	handle_rotation()

func handle_rotation():
	var adj_angle = rotationAngle
	var null_angle = 0
	
	if centerStart:
		adj_angle = rotationAngle / 2.0
		null_angle = null_angle - rotationAngle / 2.0
	
	if pingPong:
		if rotation_degrees >= adj_angle:
			rotation_direction = -1
		elif rotation_degrees <= null_angle:
			rotation_direction = 1
	else: 
		if rotation_degrees >= rotationAngle and rotationAngle < 360:
			rotation_direction = 0

func shoot():
	while true:
		await get_tree().create_timer(warmUp).timeout
		var new_spd = speed
		if !burstRotation: stop_rotation = true
		
		if aimAtPlayer: player_pos = GETPLAYER.get_player()
		
		for i in burstCount:
			if speedVar == SpeedVar.BULLET: new_spd *= speedVariation
				
			fire(new_spd)
			await get_tree().create_timer(bulletInterval).timeout
		
		if !burstRotation: stop_rotation = false

func fire(new_spd) -> void:
	var shoot_spd = new_spd
	var eachSpreadOffset = spreadOffset / float(arms)
	var eachArmAngle
	
	if spreadAngle == 360:
		eachArmAngle = spreadAngle / float(arms)
	else:
		eachArmAngle = spreadAngle / float(arms - 1)
	
	var offsetCorrection = 0.0
	if arms % 2 == 0:
		offsetCorrection = eachSpreadOffset / 2
	
	for r in range(repeatCount):
		if keepSpeed:
			shoot_spd = new_spd
		
		var repeat_rotation = repeatAngle / float(repeatCount) * r
		
		for i in range(arms):
			if speedVar == SpeedVar.ARM:
				shoot_spd *= speedVariation
			
			var shoot_dir = direction.rotated(rotation + deg_to_rad(repeat_rotation))
			var shoot_pos = global_position
			
			# Si aimAtPlayer está activado, ajustamos la dirección hacia el jugador
			if aimAtPlayer:
				shoot_dir = (player_pos - shoot_pos).normalized()
			
			if parallel:
				# Aplicamos steepness para disparo paralelo
				var offset = ((i - arms / 2.0) * eachSpreadOffset) + rng.randf_range(-randomOffset, randomOffset)
				
				# Ajustamos la posición con steepness
				var steepness_factor = abs(i - (arms - 1) / 2.0) * steepness
				shoot_pos += shoot_dir * steepness_factor  # Posiciona las balas con la forma de pico
				
				# Ajustamos también la dirección para que siga el ángulo visual correcto
				var steepness_dir_adjustment = steepness_factor * 0.01
				shoot_dir = shoot_dir.rotated(deg_to_rad(steepness_dir_adjustment))
				
				# Actualizamos posición paralela con offset corregido
				shoot_pos += shoot_dir.orthogonal() * (offset + offsetCorrection)
			else:
				# Comportamiento normal sin steepness
				var angle_offset = eachArmAngle * i - spreadAngle / 2 + rng.randf_range(-randomAngle, randomAngle)
				if arms != 1: 
					shoot_dir = shoot_dir.rotated(deg_to_rad(angle_offset))
				if spreadAngle == 360:
					shoot_dir *= -1
			
			# Velocidad final ajustada
			var curr_spd = shoot_spd * rng.randf_range(1 - randomSpeed, 1 + randomSpeed)
			
			# Lógica de simetría (opcional)
			match useSymmetry:
				false:
					shoot_bullet(shoot_dir, shoot_pos, curr_spd)
				true:
					shoot_bullet(shoot_dir.rotated(deg_to_rad(45)), shoot_pos, curr_spd)
					shoot_bullet(shoot_dir.rotated(deg_to_rad(45)) * Vector2(-1, 1), shoot_pos, curr_spd)

func shoot_bullet(shoot_dir: Vector2, shoot_pos: Vector2, shoot_spd: float):
	var bullet = bulletScene.instantiate() as Node2D
	bullet.position = shoot_pos + shoot_dir * distanceCenter
	bullet.set_properties(shoot_dir.normalized(), shoot_spd)
	bullet.modify_direction(type, gravIntensity, deviationAngle, dirStartTime, dirDuration)
	bullet.modify_speed(fstNewSpeed, fstStartTime, sndNewSpeed, sndStartTime)
	get_parent().add_child(bullet)
