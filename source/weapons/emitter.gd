## BulletEmitter — Generador definitivo de patrones bullet hell
## Nodo raíz: Marker2D
extends Marker2D

# ════════════════════════════════════════════════════════════════════════════
#  BULLET
# ════════════════════════════════════════════════════════════════════════════
@export_category("BULLET")

## Escena de bala a instanciar en cada disparo.
## Debe tener los métodos set_properties() y modify_direction() (ver bullet.gd).
@export var bulletScene: PackedScene

## Velocidad base de las balas en píxeles/segundo.
## Negativo = las balas salen hacia atrás respecto a la dirección del emitter.
@export_range(-800, 800, 50) var baseSpeed: float = 400.0

@export_group("Direction Modifier")

## Comportamiento de la bala tras ser disparada:
## NONE      → vuela en línea recta sin cambios.
## AIM       → al entrar en la ventana de tiempo, gira hacia el jugador (una vez).
## AIM_MOUSE → igual pero apunta al cursor del ratón.
## GRAVITY   → activa caída por gravedad (intensidad controlada por gravIntensity).
## LEFT      → gira progresivamente a la izquierda (deviationAngle = °/s).
## RIGHT     → gira progresivamente a la derecha.
## RANDOM    → desviación aleatoria continua.
## HOMING    → seguimiento suave del jugador (deviationAngle = °/s de giro máximo).
## SINE_WAVE → oscilación sinusoidal perpendicular al movimiento.
## BOUNCE    → rebota al llegar al borde del viewport.
@export var type: BulletDirection = BulletDirection.NONE

## Intensidad de la gravedad en GRAVITY y SINE_WAVE.
## 0 = sin efecto, 1 = gravedad completa del proyecto.
@export_range(0, 1, 0.1) var gravIntensity: float = 0.5

## Grados de desviación o velocidad de giro según el tipo:
## LEFT/RIGHT/RANDOM → grados/segundo de giro.
## HOMING            → grados/segundo de giro máximo hacia el jugador.
## SINE_WAVE         → amplitud de la oscilación lateral.
@export_range(0, 360, 1) var deviationAngle: int = 45

## Segundos desde el disparo hasta que empieza el modificador de dirección.
@export_range(0, 5, 0.1) var dirStartTime: float = 0.0

## Duración en segundos del modificador de dirección.
## Pasado este tiempo, la bala vuela recta de nuevo (excepto HOMING, que es continuo).
@export_range(0, 5, 0.1) var dirDuration: float = 5.0

@export_group("Speed Modifier")

## Activa la modificación temporal de velocidad por tramos.
@export var modifySpeed: bool = false

## Primera velocidad alternativa en píxeles/segundo.
@export_range(-800, 800, 10) var fstNewSpeed: int = 0

## Momento (segundos desde el disparo) en que se aplica la primera velocidad.
@export_range(0, 5, 0.05) var fstStartTime: float = 0.0

## Segunda velocidad alternativa en píxeles/segundo.
@export_range(-800, 800, 10) var sndNewSpeed: int = 0

## Momento (segundos desde el disparo) en que se aplica la segunda velocidad.
@export_range(0, 5, 0.05) var sndStartTime: float = 0.0

## Curva de velocidad personalizada (opcional).
## Eje X = tiempo normalizado (0→speedCurveDuration). Eje Y = multiplicador sobre baseSpeed.
## Si se asigna, anula fstNewSpeed y sndNewSpeed.
@export var speedCurve: Curve = null

## Duración total de la curva de velocidad en segundos.
@export_range(0.1, 10.0, 0.1) var speedCurveDuration: float = 3.0

enum BulletDirection {
	NONE, AIM, AIM_MOUSE, GRAVITY, LEFT, RIGHT, RANDOM, HOMING, SINE_WAVE, BOUNCE,
}

# ════════════════════════════════════════════════════════════════════════════
#  WEAPON
# ════════════════════════════════════════════════════════════════════════════
@export_category("WEAPON")

enum Direction { NORTH, WEST, SOUTH, EAST, NWEST, NEAST, SWEST, SEAST }

## Dirección base del disparo cuando no se apunta automáticamente.
## NORTH = arriba, SOUTH = abajo, EAST = derecha, WEST = izquierda.
@export var directionEnum: Direction = Direction.SOUTH

## Desvío angular respecto a la dirección base, en grados.
## Positivo = gira en sentido antihorario. Negativo = sentido horario.
## Sirve para afinar la dirección sin cambiar el enum (ej: 15° para un ángulo intermedio).
@export_range(-180.0, 180.0, 1.0) var dirDeviation: float = 0.0

## Si está activo, la dirección base apunta siempre al jugador al inicio de cada ráfaga.
@export var aimAtPlayer: bool = false

## Si está activo, la dirección base apunta siempre al cursor del ratón al inicio de cada ráfaga.
@export var aimAtMouse: bool = false

## Si está activo, los brazos se distribuyen en paralelo (desplazamiento lateral)
## en lugar de abrirse angularmente como un abanico.
@export var parallel: bool = false

## Desfase en punta para el modo parallel.
## Positivo = los brazos exteriores se adelantan, creando una cuña hacia delante.
## Negativo = los exteriores se retrasan, creando una cuña hacia atrás.
@export_range(-200, 200, 1) var steepness: int = 0

## Forma de la curva de la punta en modo parallel (solo tiene efecto con steepness != 0).
## 1.0 = lineal (rampa constante entre el centro y los extremos).
## Mayor que 1 = punta más afilada: el centro destaca y los extremos caen abruptamente.
## Menor que 1 = punta más suave: la transición es gradual desde el primer brazo.
## Rango útil: 0.3 (muy suave) hasta 4.0 (muy picudo).
@export_range(0.1, 6.0, 0.1) var steepnessSharpness: float = 1.0

var _directionMap: Dictionary = {
	Direction.NORTH: Vector2.UP,    Direction.SOUTH: Vector2.DOWN,
	Direction.WEST:  Vector2.LEFT,  Direction.EAST:  Vector2.RIGHT,
	Direction.NWEST: Vector2(-1,-1).normalized(), Direction.NEAST: Vector2(1,-1).normalized(),
	Direction.SWEST: Vector2(-1, 1).normalized(), Direction.SEAST: Vector2(1, 1).normalized(),
}
var direction := Vector2.DOWN

# ════════════════════════════════════════════════════════════════════════════
#  ROTATION
# ════════════════════════════════════════════════════════════════════════════
@export_category("ROTATION")

## Si está activo, el emitter continúa rotando mientras dispara la ráfaga.
## Si está desactivado, se congela durante la ráfaga y reanuda después.
@export var burstRotation: bool = false

## Ángulo límite de rotación en grados.
## 0 = rotación libre de 360°. Otro valor = rota hasta ese ángulo y para (o rebota con pingPong).
@export_range(-360, 360, 1) var rotationAngle: int = 0

## Velocidad de rotación en grados/segundo.
## Solo se usa cuando syncPingPongToBurst está desactivado.
@export_range(0, 360, 1) var rotationSpeed: float = 0.0

## Activa el vaivén: el emitter va de un extremo al otro del rango y vuelve.
## Requiere rotationAngle != 0.
@export var pingPong: bool = false

## Sincroniza el vaivén con la cadencia de disparo matemáticamente.
## El disparo 0 sale en un extremo y el último en el otro. Sin drift ni desincronización.
## Desactivado = usa rotationSpeed para la velocidad del vaivén.
@export var syncPingPongToBurst: bool = true

## Si está activo, el rango queda centrado en la dirección de disparo: [-angle/2 … +angle/2].
## Si está desactivado: [0 … angle].
@export var centerStart: bool = true

## Invierte la dirección inicial del vaivén.
@export var pingPongInvert: bool = false

# ════════════════════════════════════════════════════════════════════════════
#  BURST
# ════════════════════════════════════════════════════════════════════════════
@export_category("BURST")

## Ráfagas antes de que el emitter se destruya automáticamente.
## -1 = infinito. Pon 1 en sub-emitters para que disparen una sola vez y desaparezcan.
@export_range(-1, 200, 1) var maxRounds: int = -1

## Segundos de espera antes del primer disparo.
@export_range(0, 10, 0.1) var delay: float = 0.0

## Número de brazos (direcciones) por cada disparo individual.
## Con 1 brazo = un haz. Con 8 brazos y spreadAngle=360 = anillo completo.
@export_range(1, 64, 1) var arms: int = 1

## Número alternativo de brazos que se usa en los disparos pares.
## 0 = desactivado. Crea patrones alternados con diferente número de brazos.
@export_range(0, 64, 1) var alterArms: int = 0

## Si está activo, añade un brazo extra con cada ronda disparada.
@export var growWithRound: bool = false

## Balas por brazo (grosor del brazo). Con 3 = cada brazo dispara 3 balas paralelas.
@export_range(1, 10, 1) var armWidth: int = 1

## Separación entre las balas de un mismo brazo cuando armWidth > 1.
## 0 = todas juntas. 1 = separación máxima.
@export_range(0, 1, 0.05) var armSpacingFactor: float = 0.5

## Disparos consecutivos dentro de una ráfaga. Cada uno espera bulletInterval antes del siguiente.
@export_range(1, 100, 1) var burstCount: int = 1

## Segundos entre disparos dentro de una ráfaga.
@export_range(0, 2, 0.01) var bulletInterval: float = 0.1

## Segundos entre el final de una ráfaga y el inicio de la siguiente.
@export_range(0, 10, 0.05) var warmUp: float = 1.0

## Distancia extra en píxeles desde el emitter a la que aparece cada bala (en su dirección).
@export_range(0, 600, 1) var distanceCenter: int = 0

## Probabilidad de omitir un brazo aleatoriamente. 0 = nunca. 0.5 = la mitad se saltan.
@export_range(0.0, 1.0, 0.01) var skipChance: float = 0.0

## Delay aleatorio máximo en segundos por bala. Crea un efecto de stagger o ruido.
@export_range(0.0, 1.0, 0.01) var staggerDelay: float = 0.0

## Delay en segundos entre el disparo de cada brazo consecutivo.
## Con 0.02–0.05 crea un efecto espiral secuencial (los brazos salen uno tras otro).
@export_range(0.0, 0.5, 0.005) var intraArmDelay: float = 0.0

@export_group("Spread")

## Ángulo total del abanico. 45 = abanico de 45°. 360 = anillo completo.
@export_range(0, 360, 1) var spreadAngle: float = 45.0

## Separación lateral en píxeles entre brazos en modo parallel.
@export_range(0, 1000, 1) var spreadOffset: int = 100

## Activa la simetría del patrón respecto a la dirección de disparo.
## El patrón se duplica: una copia a cada lado del eje central, perfectamente reflejada.
## En las balas simétricas, LEFT se convierte en RIGHT y viceversa.
@export var useSymmetry: bool = false

## Separación en grados entre los dos lados del patrón simétrico.
## 0 = los dos lados parten del mismo eje (se tocan en el centro).
## 30 = cada lado se desplaza 15° hacia afuera, dejando un hueco entre ellos.
@export_range(0, 180, 1) var symmetryGap: float = 0.0

## Qué recibe el multiplicador speedVariation:
## BULLET = cada bala individual. ARM = cada brazo completo.
enum SpeedVar { BULLET, ARM }
@export var speedVar: SpeedVar = SpeedVar.BULLET

## Multiplicador acumulativo de velocidad por disparo o por brazo (según speedVar).
## 1.0 = sin cambio. 1.1 = cada disparo es un 10% más rápido que el anterior.
@export_range(0.5, 2.0, 0.01) var speedVariation: float = 1.0

@export_group("Speed Wave")

## Número de picos de velocidad distribuidos a lo largo del abanico de brazos.
## 0 = desactivado (todos los brazos a la misma velocidad base).
## 1 = un pico en el centro (el brazo central va más rápido que los extremos).
## 2 = dos picos a 1/4 y 3/4 del abanico. 3 = tres picos equidistribuidos. Etc.
@export_range(0, 16, 1) var peakCount: int = 0

## Velocidad extra máxima en píxeles/segundo añadida en cada pico.
## Los brazos en el pico suman esta cantidad. Los brazos en el valle no reciben nada.
@export_range(0, 1000, 10) var peakSpeedBonus: float = 100.0

@export_group("Probability")

## Variación aleatoria del ángulo de cada brazo en grados.
## 0 = todos exactos. 10 = cada brazo puede desviarse ±10° aleatoriamente.
@export_range(0, 180, 1) var randomAngle: int = 0

## Variación aleatoria de la posición de origen en píxeles.
## 0 = todas nacen en el emitter. 50 = rango aleatorio de ±50px.
@export_range(0, 400, 1) var randomOffset: int = 0

## Variación aleatoria de velocidad. 0 = todas iguales. 0.2 = velocidad ±20%.
@export_range(0, 0.9, 0.01) var randomSpeed: float = 0.0

@export_group("Repeater")

## Número de veces que se repite el patrón completo en cada disparo,
## distribuidas angularmente según repeatAngle.
@export_range(1, 16, 1) var repeatCount: int = 1

## Ángulo de distribución entre repeticiones. 360 = distribuidas en anillo completo.
@export_range(0, 360, 1) var repeatAngle: int = 360

## Si está activo, mantiene la velocidad acumulada por speedVariation entre repeticiones.
@export var keepSpeed: bool = false

# ════════════════════════════════════════════════════════════════════════════
#  SUB EMITTER
# ════════════════════════════════════════════════════════════════════════════
@export_category("SUB EMITTER")

## Escena del emitter secundario (Marker2D con este mismo script).
## Se instancia sobre cada bala disparada y lanza su propio patrón.
## Pon maxRounds=1 en el sub-emitter para que dispare una sola ráfaga y desaparezca.
@export var subEmitterScene: PackedScene = null

## Cuándo se activa el sub-emitter:
## ON_DEATH    → al destruirse la bala. El sub-emitter aparece en su posición. Pon maxRounds=1.
## AFTER_DELAY → tras subEmitDelay segundos. El sub-emitter sigue a la bala hasta activarse.
## IMMEDIATELY → al nacer la bala. El sub-emitter la acompaña durante toda su vida.
enum SubEmitTrigger { ON_DEATH, AFTER_DELAY, IMMEDIATELY }
@export var subEmitTrigger: SubEmitTrigger = SubEmitTrigger.ON_DEATH

## Segundos de espera antes de activar el sub-emitter. Solo para AFTER_DELAY.
@export_range(0.0, 10.0, 0.1) var subEmitDelay: float = 0.5

# ════════════════════════════════════════════════════════════════════════════
#  ESTADO INTERNO
# ════════════════════════════════════════════════════════════════════════════
var totalRounds: int = 0  # preservado — usado en scripts externos
var canShoot: bool   = true  # preservado — usado en scripts externos

var rotationDirection := 1
var stopRotation      := false
var playerPos: Vector2 = Vector2.ZERO
var speed: float
var usableArms: int
var rank := float(RANK.rank)
var bRound: int = 0

var _elapsedTime: float = 0.0
var _pingPongDir: int   = 1   # +1 = ida,  -1 = vuelta

# ════════════════════════════════════════════════════════════════════════════
#  INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	if peakCount > 0: dirDeviation = 5
	usableArms = arms
	speed      = baseSpeed
	direction  = _directionMap.get(directionEnum, Vector2.DOWN).rotated(deg_to_rad(dirDeviation))
	_apply_rank_modifiers()
	_init_pingpong_position()
	_reset_rotation_direction()
	shoot()

func _process(delta: float) -> void:
	_elapsedTime += delta
	if "canShoot" in get_parent():
		canShoot = get_parent().canShoot
	if pingPong and syncPingPongToBurst:
		return
	if not stopRotation:
		rotation_degrees += rotationSpeed * delta * rotationDirection
	_handle_rotation_bounds()

# ════════════════════════════════════════════════════════════════════════════
#  PING PONG SINCRONIZADO
# ════════════════════════════════════════════════════════════════════════════
func _sync_angle_for_shot(shot_i: int) -> float:
	var total := float(abs(rotationAngle))
	var lo    := -total / 2.0 if centerStart else 0.0
	var hi    :=  total / 2.0 if centerStart else total
	var t     := 0.0 if burstCount <= 1 else float(shot_i) / float(burstCount - 1)
	return lerp(lo, hi, t) if _pingPongDir >= 0 else lerp(hi, lo, t)

func _init_pingpong_position() -> void:
	if not pingPong or rotationAngle == 0:
		return
	if pingPongInvert:
		_pingPongDir = -1
	if syncPingPongToBurst:
		rotation_degrees = _sync_angle_for_shot(0)
		return
	var half := float(abs(rotationAngle)) / 2.0
	if centerStart:
		rotation_degrees = -half if not pingPongInvert else half
	else:
		rotation_degrees = 0.0 if not pingPongInvert else float(rotationAngle)

func _reset_rotation_direction() -> void:
	rotationDirection = 0 if rotationAngle == 0 else (1 if rotationAngle >= 0 else -1)

# ════════════════════════════════════════════════════════════════════════════
#  RANK
# ════════════════════════════════════════════════════════════════════════════
func _apply_rank_modifiers() -> void:
	if rank == 4: rank = 4.5

	var pScale := (rank / 6.0) ** 2
	if rank > 1:
		speed         = lerp(speed,         speed         + speed         / 2.0, pScale)
		arms          = int(lerp(float(arms),  float(arms)  + float(arms)  / 2.0, pScale))
		rotationSpeed = lerp(rotationSpeed, rotationSpeed + rotationSpeed / 2.0, pScale)
		burstCount    = int(lerp(float(burstCount), float(burstCount) + float(burstCount) / 2.0, pScale)) \
			if burstCount > 1 \
			else int(lerp(float(burstCount), float(burstCount) * 3.0, pScale))

	if rank == 0:
		speed *= 0.9
		if arms       > 1: arms       = int(arms       * 1)
		if burstCount > 1: burstCount = int(burstCount * 1)
		rotationSpeed *= 0.9

# ════════════════════════════════════════════════════════════════════════════
#  LÍMITES DE ROTACIÓN (modo libre)
# ════════════════════════════════════════════════════════════════════════════
func _handle_rotation_bounds() -> void:
	if rotationAngle == 0: return
	var total := float(abs(rotationAngle))
	var hi    :=  total / 2.0 if centerStart else total
	var lo    := -total / 2.0 if centerStart else 0.0
	if rotationAngle < 0:
		var tmp := lo; lo = hi; hi = tmp
	if pingPong:
		if   rotation_degrees >= hi: rotationDirection = -1
		elif rotation_degrees <= lo: rotationDirection =  1
	else:
		if rotationSpeed > 0:
			if rotation_degrees >= hi and abs(rotationAngle) < 360: rotationDirection = 0
			if rotation_degrees <= lo and abs(rotationAngle) < 360: rotationDirection = 0

# ════════════════════════════════════════════════════════════════════════════
#  BUCLE PRINCIPAL
# ════════════════════════════════════════════════════════════════════════════
func shoot() -> void:
	await get_tree().create_timer(delay, false).timeout
	while true:
		if aimAtPlayer: playerPos = GAME.get_player()
		if aimAtMouse:  playerPos = get_global_mouse_position()

		var currentSpeed: float = speed
		var isSyncMode: bool    = pingPong and syncPingPongToBurst

		if not burstRotation and not isSyncMode:
			stopRotation = true

		var t0: float = Time.get_ticks_msec() / 1000.0

		for shot_i in burstCount:
			if isSyncMode:
				rotation_degrees = _sync_angle_for_shot(shot_i)
			if speedVar == SpeedVar.BULLET: currentSpeed *= speedVariation
			if canShoot: fire(currentSpeed)
			await get_tree().create_timer(bulletInterval, false).timeout

		if isSyncMode:
			rotation_degrees = _sync_angle_for_shot(burstCount - 1)

		usableArms = arms

		if not burstRotation and not isSyncMode:
			stopRotation = false
			_reset_rotation_direction()

		if isSyncMode and warmUp > 0.0:
			stopRotation = true

		var elapsed: float = (Time.get_ticks_msec() / 1000.0) - t0
		if elapsed < warmUp:
			await get_tree().create_timer(warmUp - elapsed, false).timeout

		if isSyncMode:
			_pingPongDir *= -1
			stopRotation  = false

		totalRounds += 1
		if maxRounds >= 0 and totalRounds >= maxRounds:
			queue_free()
			return

# ════════════════════════════════════════════════════════════════════════════
#  FIRE
# ════════════════════════════════════════════════════════════════════════════
func fire(currentSpeed: float) -> void:
	var armsToUse: int = alterArms if (alterArms > 0 and bRound % 2 == 1) else usableArms
	# halfN: distancia del brazo central al extremo, para normalizar steepness.
	var halfN: float = max(float(armsToUse - 1) / 2.0, 0.001)

	for r in repeatCount:
		var spreadStep: float = float(spreadOffset) / float(armsToUse)
		var divisor:    float = float(armsToUse) if spreadAngle == 360.0 \
								else max(1.0, float(armsToUse - 1))
		var angleStep:  float = spreadAngle / divisor
		var offCorr:    float = spreadStep / 2.0
		var repRot:     float = float(repeatAngle) / float(repeatCount) * r

		var baseDir := direction.rotated(rotation + deg_to_rad(repRot))
		if aimAtPlayer or aimAtMouse:
			baseDir = (playerPos - global_position).normalized()

		# gapRad solo se aplica si useSymmetry está activo.
		# Si no, symmetryGap != 0 rotaría toda la dirección de disparo aunque no haya espejo.
		var gapRad: float = deg_to_rad(symmetryGap * 0.5) if useSymmetry else 0.0

		var armSpeed: float = currentSpeed
		for i in armsToUse:
			if skipChance > 0.0 and DRNG.drandf_range(0.0, 1.0) < skipChance:
				continue
			if speedVar == SpeedVar.ARM: armSpeed *= speedVariation

			# ── Onda de velocidad ─────────────────────────────────────────
			var peakBonus: float = 0.0
			if peakCount > 0 and armsToUse > 1:
				var x: float = float(i) / float(armsToUse - 1)
				peakBonus = abs(sin(x * float(peakCount) * PI)) * peakSpeedBonus

			var noise := Vector2(DRNG.drandf_range(-randomOffset, randomOffset),
								 DRNG.drandf_range(-randomOffset, randomOffset))

			# ── Dirección y posición del disparo original ─────────────────
			var shootDir: Vector2
			var shootPos: Vector2

			if parallel:
				shootDir = baseDir.rotated(gapRad)
				# steepnessSharpness controla la curva de la cuña:
				# normDist = 0 en el centro, 1 en los extremos.
				# pow(normDist, 1/sharpness): sharpness>1 = cuña más picuda.
				var normDist  = abs(float(i) - halfN) / halfN
				var steepPow  := pow(normDist, 1.0 / steepnessSharpness)
				var steepDist := steepPow * halfN * float(steepness)
				var lateral   := float(i) - float(armsToUse) / 2.0
				shootPos  = global_position + noise
				shootPos += shootDir * steepDist
				shootPos += shootDir.orthogonal() * (lateral * spreadStep + offCorr)
			else:
				var aOff: float = 0.0
				if armsToUse > 1:
					aOff = angleStep * i - spreadAngle / 2.0 \
						   + DRNG.drandf_range(-randomAngle, randomAngle)
				shootDir = baseDir.rotated(gapRad + deg_to_rad(aOff))
				if spreadAngle == 360.0:
					shootDir *= -1.0
				shootPos = global_position + noise

			# ── Disparar balas del brazo (armWidth) ───────────────────────
			for j in armWidth:
				var wOff:     float   = (float(j) - float(armWidth - 1) / 2.0) \
										* spreadStep * armSpacingFactor
				var finalPos: Vector2 = shootPos + shootDir.orthogonal() * wOff
				var finalSpd: float   = (armSpeed + peakBonus) \
										* DRNG.drandf_range(1.0 - randomSpeed, 1.0 + randomSpeed)
				var armDelay: float   = float(i) * intraArmDelay \
										+ DRNG.drandf_range(0.0, staggerDelay)

				_fire_bullet(shootDir, finalPos, finalSpd, armDelay, type)

				# ── Copia simétrica ───────────────────────────────────────
				if useSymmetry:
					# Reflejar la dirección respecto al eje base (baseDir)
					var mirrorDir: Vector2 = _mirror_direction(shootDir, baseDir)

					var mirrorPos: Vector2
					if parallel:
						# Reconstruir posición espejo: misma profundidad (steep),
						# lateral invertido respecto al eje
						var normDist2  = abs(float(i) - halfN) / halfN
						var steepPow2  := pow(normDist2, 1.0 / steepnessSharpness)
						var steepDist2 := steepPow2 * halfN * float(steepness)
						var lateral2   := float(i) - float(armsToUse) / 2.0
						mirrorPos  = global_position + noise
						mirrorPos += mirrorDir * steepDist2
						mirrorPos += mirrorDir.orthogonal() * (-(lateral2 * spreadStep + offCorr))
						mirrorPos += mirrorDir.orthogonal() * (-wOff)
					else:
						# Modo angular: misma posición de origen, armWidth invertido
						mirrorPos = shootPos + mirrorDir.orthogonal() * (-wOff)

					# LEFT↔RIGHT invertidos en la bala simétrica
					_fire_bullet(mirrorDir, mirrorPos, finalSpd, armDelay, _flip_lr_type(type))

	bRound += 1
	if growWithRound: usableArms += 1

# ════════════════════════════════════════════════════════════════════════════
#  HELPERS
# ════════════════════════════════════════════════════════════════════════════

## Invierte LEFT y RIGHT. Cualquier otro tipo lo devuelve sin cambios.
func _flip_lr_type(t: BulletDirection) -> BulletDirection:
	match t:
		BulletDirection.LEFT:  return BulletDirection.RIGHT
		BulletDirection.RIGHT: return BulletDirection.LEFT
		_: return t

func _fire_bullet(dir: Vector2, pos: Vector2, spd: float,
				  d: float, bType: BulletDirection) -> void:
	if d > 0.0:
		_shoot_bullet_delayed(dir, pos, spd, d, bType)
	else:
		_shoot_bullet(dir, pos, spd, bType)

func _shoot_bullet_delayed(dir: Vector2, pos: Vector2, spd: float,
							wait: float, bType: BulletDirection) -> void:
	await get_tree().create_timer(wait, false).timeout
	if is_inside_tree(): _shoot_bullet(dir, pos, spd, bType)

func _shoot_bullet(dir: Vector2, pos: Vector2, spd: float,
				   bType: BulletDirection) -> void:
	var bullet = bulletScene.instantiate()
	bullet.set_properties(dir, spd)
	bullet.modify_direction(bType, gravIntensity, deviationAngle, dirStartTime, dirDuration)
	if modifySpeed:
		bullet.modify_speed(fstNewSpeed, fstStartTime, sndNewSpeed, sndStartTime)
	if speedCurve != null and bullet.has_method("set_speed_curve"):
		bullet.set_speed_curve(speedCurve, baseSpeed, speedCurveDuration)
	# PRIMERO add_to_game (dispara _ready en la bala), DESPUÉS posición y sub-emitter.
	# El orden importa: set_sub_emitter necesita que la bala ya esté en el árbol.
	GLOBAL.add_to_game(bullet)
	bullet.global_position = pos + dir * float(distanceCenter)
	if subEmitterScene != null and bullet.has_method("set_sub_emitter"):
		bullet.set_sub_emitter(subEmitterScene, int(subEmitTrigger), subEmitDelay)

# API pública para compatibilidad con scripts externos
func mirror_direction(dir: Vector2, axis: Vector2) -> Vector2:
	return _mirror_direction(dir, axis)
func reflect_vector(v: Vector2, axis: Vector2) -> Vector2:
	return _reflect_vector(v, axis)
func _mirror_direction(dir: Vector2, axis: Vector2) -> Vector2:
	return _reflect_vector(dir, axis).normalized()
func _reflect_vector(v: Vector2, axis: Vector2) -> Vector2:
	var n := axis.normalized()
	return 2.0 * v.dot(n) * n - v
