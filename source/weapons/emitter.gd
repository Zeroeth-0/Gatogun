extends Marker2D

# ------------------------------------------------Bullet--------------------------------------------------

@export_category("BULLET")
@export var bulletScene: PackedScene # Implementado
@export_range(-300, 300, 50) var speed: float # Implementado

@export_group("DIRECTION")
enum Type { NONE, AIM, GRAVITY, LEFT, RIGHT, RANDOM, ANGLE }
@export var type: Type = Type.NONE
@export_range(0, 360, 15) var deviationAngle: int
@export_range(0, 10, 1) var strength: int
@export_range(0, 5, 0.5) var dirStartTime: float
@export_range(0, 5, 0.5) var dirDuration: float

@export_group("FIRST CHANGE SPEED")
@export_range(-300, 300, 50) var fstNewSpeed: int
@export_range(0, 5, 0.5) var fstStartTime: float
@export_range(0, 5, 0.5) var fstDuration: float

@export_group("SECOND CHANGE SPEED")
@export_range(-300, 300, 50) var sndNewSpeed: int
@export_range(0, 5, 0.5) var sndStartTime: float
@export_range(0, 5, 0.5) var sndDuration: float

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
var direction: Vector2 = Vector2(0, 1) # Dirección central del patrón
@export var aimAtPlayer: bool = false
@export var parallel: bool = false # Implementado

@export_group("ROTATION")
@export var burstRotation: bool = false
@export_range(0, 360, 15) var rotationAngle: int # Implementado
@export_range(-150, 150, 10) var rotationSpeed: int # Implementado
@export var pingPong: bool = false # Implementado
@export var centerStart: bool = false # Implementado

# ------------------------------------------------Burst---------------------------------------------------

@export_category("BURST")
@export_range(1, 16, 1) var arms: int # Implementado
@export_range(1, 10, 1) var burstCount: int = 1 # Implementado
@export_range(0, 1, 0.05) var bulletInterval: float # Implementado
@export_range(0, 5, 0.5) var warmUp: float = 1.0 # Implementado
@export_range(0, 450, 50) var distanceCenter: int # Implementado

@export_group("SPREAD")
@export_range(0, 360, 15) var spreadAngle: float = 45.0 # Implementado
@export_range(0, 600, 100) var spreadOffset: int # Implementado
enum SpeedVar { BULLET, ARM }
@export var speedVar: SpeedVar = SpeedVar.BULLET
@export_range(0.9, 1.1, 0.02) var speedVariation: float = 1 # Implementado
@export var useSymmetry: bool = false # Implementado

@export_group("PROBABILITY")
@export_range(0, 100, 10) var randomAngle: int # Implementado
@export_range(0, 100, 10) var randomOffset: int # Implementado
@export_range(0, 0.9, 0.1) var randomSpeed: float # Implementado

@export_group("REPEATER")
@export_range(1, 8, 1) var repeatCount: int # Implementado
@export_range(0, 360, 45) var repeatAngle: int # Implementado
@export var keepSpeed: bool = false # Implementado

var rng = RandomNumberGenerator.new()
var rotation_direction = 1

func _ready():
	direction = DIRECTION_MAP.get(directionEnum)
	shoot()

func _process(delta):
	# Aplicar la rotación si burstRotation está activado
	rotation_degrees += rotationSpeed * delta * rotation_direction
	handle_rotation()

func handle_rotation():
	var adj_angle = rotationAngle
	var null_angle = 0
	
	if centerStart:
		adj_angle = rotationAngle / 2
		null_angle = null_angle - rotationAngle / 2
	
	if pingPong:
		if rotation_degrees >= adj_angle: rotation_direction = -1
		if rotation_degrees <= null_angle: rotation_direction = 1
	else:
		if rotation_degrees >= rotationAngle and rotationAngle < 360 : rotation_direction = 0

func shoot():
	while true:
		await get_tree().create_timer(warmUp).timeout
		var new_spd = speed
		
		for i in burstCount:
			if speedVar == SpeedVar.BULLET: new_spd *= speedVariation
			fire(new_spd)
			await get_tree().create_timer(bulletInterval).timeout

func fire(new_spd) -> void:
	var shoot_spd = new_spd
	var eachSpreadOffset = spreadOffset / float(arms)
	var eachArmAngle
	
	# Cálculo del ángulo por bala si no está en modo paralelo:
	if spreadAngle == 360: eachArmAngle = spreadAngle / float(arms)
	else: eachArmAngle = spreadAngle / float(arms - 1)
	
	# Ajuste del offset del patrón si el número de brazos (arms) es par
	var offsetCorrection = 0.0
	if arms % 2 == 0: offsetCorrection = eachSpreadOffset / 2
	
	# Repeater: Repetir el burst en función de `repeatCount` y `repeatAngle`
	for r in range(repeatCount):
		if keepSpeed: shoot_spd = new_spd
		
		# Ángulo para este burst repetido
		var repeat_rotation = repeatAngle / float(repeatCount) * r
		
		# Disparamos el patrón original y aplicamos la variación de velocidad
		for i in range(arms):
			if speedVar == SpeedVar.ARM: shoot_spd *= speedVariation
			var shoot_dir = direction.rotated(rotation + deg_to_rad(repeat_rotation)) # Aplicamos la rotación al burst
			var shoot_pos = global_position
		
			# Lógica para balas paralelas o con dispersión
			if parallel:
				# Cálculo de la separación horizontal y vertical
				var offset = (((i - arms / 2) * eachSpreadOffset) + rng.randf_range(-randomOffset, randomOffset)) * shoot_dir.orthogonal()
				shoot_pos = global_position + Vector2(offset) + shoot_dir.orthogonal() * offsetCorrection
			else:
				# Calculamos el ángulo para cada bala
				var angle_offset = eachArmAngle * i - spreadAngle / 2 + rng.randf_range(-randomAngle, randomAngle)
				if arms != 1: 
					shoot_dir = shoot_dir.rotated(deg_to_rad(angle_offset))  # Aplicamos el ángulo a la rotación del burst
				if spreadAngle == 360: 
					shoot_dir *= -1
			
			var curr_spd = shoot_spd * rng.randf_range(1 - randomSpeed, 1 + randomSpeed)
			
			match useSymmetry:
				false:
					shoot_bullet(shoot_dir, shoot_pos, curr_spd)
				true:
					shoot_bullet(shoot_dir.rotated(deg_to_rad(45)), shoot_pos, curr_spd)
					shoot_bullet(shoot_dir.rotated(deg_to_rad(45)) * Vector2(-1, 1), shoot_pos, curr_spd)

func shoot_bullet(shoot_dir: Vector2, shoot_pos: Vector2, shoot_spd: float):
	var bullet = bulletScene.instantiate() as Node2D
	bullet.position = shoot_pos + shoot_dir * distanceCenter
	bullet.set_properties(shoot_dir, shoot_spd)
	get_parent().add_child(bullet)
