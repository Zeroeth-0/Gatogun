extends Marker2D

# === BULLET CONFIG ===
@export_category("BULLET")
@export var bulletScene: PackedScene                                            # Tipo de bala
@export_range(-400, 400, 50) var baseSpeed: float = 400.0                       # Velocidad de bala

@export_group("DIRECTION")
enum BulletDirection { NONE, AIM, GRAVITY, LEFT, RIGHT, RANDOM }
@export var type: BulletDirection = BulletDirection.NONE                        # Tipo de dirección alterada
@export_range(0, 1, 0.1) var gravIntensity: float = 0.5                         # Intensidad de gravedad
@export_range(0, 180, 45) var deviationAngle: int = 45                          # Ángulo de desviación
@export_range(-45, 45, 5) var dirOffset: float = 0.0                            # Compensación de dirección
@export_range(0, 5, 0.1) var dirStartTime: float = 0.0                          # Tiempo inicio alteración
@export_range(0, 5, 0.1) var dirDuration: float = 5.0                           # Duración alteración

@export_group("CHANGE SPEED")
@export var modifySpeed: bool = false                                           # Modificar velocidad
@export_range(-300, 300, 50) var fstNewSpeed: int = 0                           # Primera nueva velociad
@export_range(0, 5, 0.5) var fstStartTime: float = 0.0                          # Tiempo primera modificación
@export_range(-300, 300, 50) var sndNewSpeed: int = 0                           # Segunda nueva velocidad
@export_range(0, 5, 0.5) var sndStartTime: float = 0.0                          # Tiempo segunda modificación

# === WEAPON CONFIG ===
@export_category("WEAPON")
@export var directionEnum: Direction = Direction.SOUTH                          # Orientación de disparo
@export var aimAtPlayer: bool = false                                           # Apuntar al jugador
@export var parallel: bool = false                                              # Balas paralelas
@export_range(-50, 50, 5) var steepness: int = 0                                # Patrón en punta

enum Direction { NORTH, WEST, SOUTH, EAST, NWEST, NEAST, SWEST, SEAST }
var directionMap = {
	Direction.NORTH: Vector2.UP,
	Direction.SOUTH: Vector2.DOWN,
	Direction.WEST: Vector2.LEFT,
	Direction.EAST: Vector2.RIGHT,
	Direction.NWEST: Vector2(-1, -1).normalized(),
	Direction.NEAST: Vector2(1, -1).normalized(),
	Direction.SWEST: Vector2(-1, 1).normalized(),
	Direction.SEAST: Vector2(1, 1).normalized()
}
var direction := Vector2.DOWN


# === ROTATION CONFIG ===
@export_group("ROTATION")
@export var burstRotation: bool = false                                         # Rotación de ráfaga
@export_range(-360, 360, 45) var rotationAngle: int = 0                         # Ángulo de rotación
@export_range(0, 150, 10) var rotationSpeed: int = 0                            # Velocidad de rotación
@export var pingPong: bool = false                                              # Rotación oscilante
@export var centerStart: bool = true                                            # Comenzar en el centro

# === BURST CONFIG ===
@export_category("BURST")
@export_range(0, 5, 0.5) var delay: float = 0.0                                 # Retraso de disparo
@export_range(1, 16, 1) var arms: int = 1                                       # Brazos por ráfaga
@export_range(1, 5, 1) var armWidth: int = 1                                    # Balas por brazo
@export_range(0, 1, 0.1) var armSpacingFactor: float = 0.5                      # Distancia balas brazo
@export_range(1, 10, 1) var burstCount: int = 1                                 # Repeticiones por ráfaga
@export_range(0, 1, 0.05) var bulletInterval: float = 0.1                       # Espera entre repeticiones
@export_range(0, 5, 0.1) var warmUp: float = 1.0                                # Espera entre ráfagas
@export_range(0, 450, 50) var distanceCenter: int = 0                           # Distancia del centro

@export_group("SPREAD")
@export_range(0, 360, 15) var spreadAngle: float = 45.0                         # Ángulo de dispersión
@export_range(0, 600, 100) var spreadOffset: int = 100                          # Compensación de dispersión
@export var useSymmetry: bool = false                                           # Replicar simétricamente
enum SpeedVar { BULLET, ARM }
@export var speedVar: SpeedVar = SpeedVar.BULLET                                # Acelerar balas o ráfaga
@export_range(0.8, 1.2, 0.01) var speedVariation: float = 1.0                   # Cantidad de aceleración

@export_group("PROBABILITY")
@export_range(0, 100, 10) var randomAngle: int = 0                              # Aleatorización de ángulo
@export_range(0, 100, 10) var randomOffset: int = 0                             # Aleatorización de posición
@export_range(0, 0.9, 0.1) var randomSpeed: float = 0.0                         # Aleatorización de velocidad

@export_group("REPEATER")
@export_range(1, 8, 1) var repeatCount: int = 1                                 # Repetir a lo largo del patrón
@export_range(0, 360, 45) var repeatAngle: int = 360                            # Dispersión de las repeticiones
@export var keepSpeed: bool = false                                             # Mantener velocidad entre repeticiones

# === ESTADO INTERNO ===
var rng = RandomNumberGenerator.new()
var rotationDirection := 1
var stopRotation := false
var playerPos: Vector2 = Vector2.ZERO
var speed: float
var canShoot: bool = true
var adjustedDirection = direction
var rank := SCORE.rank

func _ready() -> void:
	speed = baseSpeed
	direction = directionMap.get(directionEnum, Vector2.DOWN)
	_apply_rank_modifiers()
	shoot()

func _process(delta: float) -> void:
	if "canShoot" in get_parent(): canShoot = get_parent().canShoot
	
	if not stopRotation: rotation_degrees += rotationSpeed * delta * rotationDirection
	
	_handle_rotation_bounds()

func _apply_rank_modifiers() -> void:
	if rank == 4: rank = 4.5
	
	var scale := (rank / 6.0) ** 2
	if rank > 1:
		speed = lerp(speed, speed + speed / 2, scale)
		arms = lerp(arms, arms + arms / 2, scale)
		burstCount = lerp(burstCount, burstCount + burstCount / 2, scale) \
			if burstCount > 1 \
			else lerp(burstCount, burstCount * 3, scale)
		rotationSpeed = lerp(rotationSpeed, rotationSpeed + rotationSpeed / 2, scale)
	
	if rank == 0:
		speed *= 0.75
		if arms > 1: arms *= 0.75
		if burstCount > 1: burstCount *= 0.75
		rotationSpeed *= 0.75

func _handle_rotation_bounds() -> void:
	var adjAngle = rotationAngle
	var nullAngle = 0.0
	
	if centerStart:
		adjAngle /= 2.0
		nullAngle = -adjAngle
	
	if rotationAngle >= 0:
		if pingPong:
			if rotation_degrees >= adjAngle: rotationDirection = -1
			elif rotation_degrees <= nullAngle: rotationDirection = 1
		elif rotation_degrees >= rotationAngle and rotationAngle < 360: rotationDirection = 0
	else:
		if pingPong:
			if rotation_degrees <= adjAngle: rotationDirection = 1
			elif rotation_degrees >= nullAngle: rotationDirection = -1
		elif rotation_degrees <= rotationAngle and rotationAngle < 360: rotationDirection = 0

func shoot() -> void:
	await get_tree().create_timer(delay).timeout
	
	while true:
		if aimAtPlayer: playerPos = GAME.get_player()
		else: adjustedDirection = direction.rotated(deg_to_rad(dirOffset))
		
		var currentSpeed = speed
		if not burstRotation: stopRotation = true
		
		# Iniciamos el temporizador del próximo ciclo de ráfaga YA
		var nextWarmupTimer = get_tree().create_timer(warmUp)
		
		for i in burstCount:
			if speedVar == SpeedVar.BULLET: currentSpeed *= speedVariation
			if canShoot: fire(currentSpeed)
			await get_tree().create_timer(bulletInterval).timeout
		
		if not burstRotation: stopRotation = false
		
		# Esperamos a que el warmUp se termine *después* de haber disparado todo
		await nextWarmupTimer.timeout

func fire(currentSpeed: float) -> void:
	var spreadStep = spreadOffset / float(arms)
	var divisor = arms if spreadAngle == 360 else (arms - 1)
	var angleStep = spreadAngle / float(divisor)
	var offsetCorrection = spreadStep / 2.0
	
	for r in repeatCount:
		var repeatRotation = repeatAngle / float(repeatCount) * r
		var baseDir = adjustedDirection.rotated(rotation + deg_to_rad(repeatRotation))
		
		for i in arms:
			if speedVar == SpeedVar.ARM: currentSpeed *= speedVariation
			var shootDir = baseDir
			var shootPos = global_position
			
			if aimAtPlayer: shootDir = (playerPos - shootPos).normalized().rotated(deg_to_rad(dirOffset))
			
			if parallel:
				var offset = (i - arms / 2.0) * spreadStep + rng.randf_range(-randomOffset, randomOffset)
				var steepFactor = abs(i - (arms - 1) / 2.0) * steepness
				
				shootPos += shootDir * steepFactor
				shootDir = shootDir.rotated(deg_to_rad(steepFactor * 0.01))
				shootPos += shootDir.orthogonal() * (offset + offsetCorrection)
			else:
				var angleOffset = angleStep * i - spreadAngle / 2.0 + rng.randf_range(-randomAngle, randomAngle)
				if arms != 1: shootDir = shootDir.rotated(deg_to_rad(angleOffset))
				if spreadAngle == 360: shootDir *= -1
			
			for j in armWidth:
				var armOffset = (j - (armWidth - 1) / 2.0) * spreadStep * armSpacingFactor
				var finalPos = shootPos + shootDir.orthogonal() * armOffset
				var finalSpeed = currentSpeed * rng.randf_range(1 - randomSpeed, 1 + randomSpeed)
				
				if not useSymmetry: _shoot_bullet(shootDir, finalPos, finalSpeed)
				else:
					var symmetryDir = shootDir
					_shoot_bullet(symmetryDir, finalPos, finalSpeed)
					_shoot_bullet(symmetryDir * Vector2(-1, 1), finalPos, finalSpeed)

func _shoot_bullet(dir: Vector2, pos: Vector2, spd: float) -> void:
	var bullet = bulletScene.instantiate()
	bullet.position = pos + dir * distanceCenter
	bullet.set_properties(dir, spd)
	bullet.modify_direction(type, gravIntensity, deviationAngle, dirStartTime, dirDuration)
	if modifySpeed: bullet.modify_speed(fstNewSpeed, fstStartTime, sndNewSpeed, sndStartTime)
	get_tree().current_scene.add_child(bullet)
