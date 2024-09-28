extends Marker2D

# ------------------------------------------------Bullet--------------------------------------------------

@export_category("BULLET")
@export var bulletScene: PackedScene # Implementado
@export_range(50, 500, 50) var speed: int # Implementado

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
@export_range(0, 360, 45) var rotationAngle: int
@export_range(0, 20, 5) var rotationSpeed: int
@export var pingPong: bool = false
@export var centerStart: bool = false

# ------------------------------------------------Burst---------------------------------------------------

@export_category("BURST")
@export_range(1, 16, 1) var arms: int # Número de balas (ramas)
@export_range(1, 10, 1) var burstCount: int = 1 # Implementado
@export_range(0, 1, 0.05) var bulletInterval: float # Implementado
@export_range(0, 5, 1) var warmUp: float = 1.0 # Implementado
@export_range(0, 10, 1) var distanceCenter: int

@export_group("SPREAD")
@export_range(0, 360, 45) var spreadAngle: float = 45.0 # Implementado
@export_range(0, 600, 100) var spreadOffset: int
@export_range(1, 3, 0.1) var speedVariation: float
@export var useSymmetry: bool = false

@export_group("PROBABILITY")
@export_range(0, 10, 1) var randomAngle: int
@export_range(0, 10, 1) var randomHorizontal: int
@export_range(0, 10, 1) var randomVertical: float = 0.0
@export_range(0, 1, 0.1) var randomSpeed: float

@export_group("REPEATER")
@export_range(1, 8, 1) var repeatCount: int
@export_range(0, 360, 45) var repeatAngle: int

func _ready():
	direction = DIRECTION_MAP.get(directionEnum)
	shoot()

func _process(delta):
	# Si hay rotación del arma, se maneja aquí
	pass

func shoot():
	while true:
		await get_tree().create_timer(warmUp).timeout
		for i in burstCount:
			fire()
			await get_tree().create_timer(bulletInterval).timeout

func fire() -> void:
	# Si solo hay una bala, la disparamos directamente en la dirección central
	if arms == 1:
		shoot_bullet(direction, global_position)
		return
	
	var shoot_dir = direction
	var shoot_pos = global_position
	var eachSpreadOffset = spreadOffset / float(arms)
	var eachArmAngle

	# Cálculo del ángulo por bala si no está en modo paralelo:
	if spreadAngle == 360: eachArmAngle = spreadAngle / float(arms)
	else: eachArmAngle = spreadAngle / float(arms - 1)
	
	# Ajuste del offset del patrón si el número de brazos (arms) es par
	var offsetCorrection = 0.0
	if arms % 2 == 0: offsetCorrection = eachSpreadOffset / 2

	# Disparamos cada bala con la dirección ajustada
	for i in range(arms):
		if parallel:
			# Cálculo de la separación horizontal y vertical
			var offset = ((i - arms / 2) * eachSpreadOffset) * direction.orthogonal()
			shoot_pos = global_position + Vector2(offset) + direction.orthogonal() * offsetCorrection
		else:
			# Calculamos el ángulo para cada bala, aplicando la corrección si es par
			var angle_offset = eachArmAngle * i - spreadAngle / 2
			shoot_dir = direction.rotated(deg_to_rad(angle_offset))
		
		# Disparamos la bala en la dirección calculada
		shoot_bullet(shoot_dir, shoot_pos)

func shoot_bullet(shoot_dir: Vector2, shoot_pos: Vector2):
	var bullet = bulletScene.instantiate() as Node2D
	bullet.position = shoot_pos
	bullet.set_properties(shoot_dir, speed)
	get_parent().add_child(bullet)
