extends Marker2D

@export_category("BULLET")
@export var bulletScene: PackedScene
@export_range(50, 500, 50) var speed: int

@export_category("WEAPON")

@export_group("DIRECTION")
@export var direction: Vector2 = Vector2(0, 1)
@export var aimAtPlayer: bool = false
@export_range(0, 360, 45) var angleLimit: int
@export var parallel: bool = false

@export_group("ROTATION")
@export var burstRotation: bool = false
@export_range(0, 360, 45) var rotationAngle: int
@export_range(0, 20, 5) var rotationSpeed: int
@export var pingPong: bool = false
@export var centerStart: bool = false

@export_category("BURST")
@export_range(1, 16, 1) var burstCount: int
@export_range(0, 1, 0.05) var bulletInterval: float
@export_range(0, 5, 1) var warmUp: float = 1.0

@export_group("START POS")
@export_range(0, 10, 1) var distanceCenter: int

@export_group("SPREAD")
@export_range(0, 360, 45) var spreadAngle: int
@export_range(0, 10, 1) var horizontalSpread: int
@export_range(0, 10, 1) var verticalSpread: int
@export_range(1, 3, 0.1) var speedVariation: float

@export_group("PROBABILITY")
@export_range(0, 10, 1) var randomAngle: int
@export_range(0, 10, 1) var randomHorizontal: int
@export_range(0, 10, 1) var randomVertical: float = 0.0
@export_range(0, 1, 0.1) var randomSpeed: float

@export_group("SYMMETRY")
@export var useSymmetry: bool = false

@export_group("REPEATER")
@export_range(1, 8, 1) var repeatCount: int
@export_range(0, 360, 45) var repeatAngle: int

var warmUpCounter: float = 0.0
var burstShotCounter: int = 0

# Este proceso se encarga de controlar el warmup y el disparo de ráfagas.
func _process(delta: float) -> void:
	if warmUpCounter < warmUp: warmUpCounter += delta
	else:
		burstShotCounter = 0
		fire_burst()
		warmUpCounter = 0.0

# Función para disparar balas en una ráfaga
func fire_burst() -> void:
	while burstShotCounter < burstCount:
		var bullet = bulletScene.instantiate()
		
		bullet.position = global_position
		bullet.set_properties(direction, speed)
		
		get_parent().add_child(bullet)
		
		burstShotCounter += 1
		await get_tree().create_timer(bulletInterval).timeout
