extends Area2D

# ════════════════════════════════════════════════════════════════════════════
#  PROPIEDADES BASE
#  Fijadas por el emitter antes de que la bala entre al árbol de escena.
# ════════════════════════════════════════════════════════════════════════════
var speed: float         = 400.0
var direction            := Vector2.ZERO

## Velocidad de giro visual del sprite en grados/segundo.
var rotationSpeed: float = 400.0

# ════════════════════════════════════════════════════════════════════════════
#  SPRITE
# ════════════════════════════════════════════════════════════════════════════

## Modo de rotación visual del sprite:
## SPIN_CONTINUOUS → gira sin parar a rotationSpeed grados/segundo.
## FACE_MOVEMENT   → siempre apunta en la dirección de movimiento.
enum SpriteRotationMode { SPIN_CONTINUOUS, FACE_MOVEMENT }
@export var sprite_rotation_mode: SpriteRotationMode = SpriteRotationMode.SPIN_CONTINUOUS

# ════════════════════════════════════════════════════════════════════════════
#  DIRECCIÓN — configurada por el emitter vía modify_direction()
# ════════════════════════════════════════════════════════════════════════════
enum DirectionType {
	NONE,
	AIM,        ## Gira hacia el jugador una vez al entrar en la ventana de tiempo
	AIM_MOUSE,  ## Gira hacia el cursor una vez al entrar en la ventana de tiempo
	GRAVITY,    ## Activa la caída por gravedad (gravIntensity = 0–1)
	LEFT,       ## Gira continuamente a la izquierda (deviationAngle = °/s)
	RIGHT,      ## Gira continuamente a la derecha (deviationAngle = °/s)
	RANDOM,     ## Desviación aleatoria continua (deviationAngle = amplitud en °/s)
	HOMING,     ## Seguimiento suave del jugador (deviationAngle = °/s de giro máximo)
	SINE_WAVE,  ## Oscilación sinusoidal perpendicular al movimiento
	BOUNCE,     ## Rebota al llegar al borde del viewport
}
@export var directionType  := DirectionType.NONE
@export var gravIntensity  := 0.0
@export var deviationAngle := 0
@export var dirStartTime   := 0.0
@export var dirDuration    := 1.0

# ════════════════════════════════════════════════════════════════════════════
#  VELOCIDAD — configurada por el emitter vía modify_speed()
# ════════════════════════════════════════════════════════════════════════════
@export var modifySpeed  := false
@export var fstNewSpeed  := 400
@export var fstStartTime := 0.0
@export var sndNewSpeed  := 400
@export var sndStartTime := 0.0

var _speedCurve:         Curve = null
var _speedCurveBase:     float = 400.0
var _speedCurveDuration: float = 3.0

# ════════════════════════════════════════════════════════════════════════════
#  SUB EMITTER
# ════════════════════════════════════════════════════════════════════════════
var _subEmitterScene: PackedScene = null
var _subEmitTrigger:  int         = 0   # 0=ON_DEATH 1=AFTER_DELAY 2=IMMEDIATELY
var _subEmitDelay:    float       = 0.5
var _subEmitFired:    bool        = false

# ════════════════════════════════════════════════════════════════════════════
#  ESTADO INTERNO
# ════════════════════════════════════════════════════════════════════════════
var isCancelled := false

var elapsedTime  := 0.0
var velocity     := Vector2.ZERO
var useGravity   := false
var acceleration := Vector2.ZERO

var _sineAmplitude: float = 0.0
var _sineFrequency: float = 1.0

# NUEVA VARIABLE: para permitir que balas que nacen fuera entren sin destruirse
var _has_been_visible: bool = false

# ════════════════════════════════════════════════════════════════════════════
#  INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	velocity      = direction * speed
	sndStartTime += fstStartTime
	if directionType == DirectionType.SINE_WAVE:
		_setup_sine_wave()

func _setup_sine_wave() -> void:
	_sineAmplitude = float(deviationAngle) * (speed / 400.0) * 0.8
	_sineFrequency = max(0.1, gravIntensity * 3.0)

# ════════════════════════════════════════════════════════════════════════════
#  PROCESO PRINCIPAL
# ════════════════════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	elapsedTime += delta

	if isCancelled:
		queue_free()
		return

	# ────────────────────────────────────────────────
	# Chequeo mejorado: destruir SOLO cuando SALE después de haber estado dentro
	# ────────────────────────────────────────────────
	var vp := get_viewport_rect()
	var currently_inside := vp.has_point(global_position)

	if currently_inside:
		_has_been_visible = true
	elif _has_been_visible:
		# Estaba dentro antes → ahora salió → destruir
		queue_free()
		return

	# Si nunca ha estado dentro, permitimos que siga viva (puede estar entrando)

	_update_direction(delta)
	if modifySpeed:  _update_speed_lerp()
	if _speedCurve:  _update_speed_curve()

	if useGravity:
		_apply_gravity()
		velocity += acceleration * delta
	else:
		velocity = direction * speed

	var finalVelocity := velocity
	if _sineAmplitude > 0.0:
		var perp := velocity.normalized().orthogonal()
		finalVelocity += perp * _sineAmplitude * sin(TAU * _sineFrequency * elapsedTime)

	position += finalVelocity * delta

	if directionType == DirectionType.BOUNCE:
		_handle_bounce()

	_update_sprite_rotation(delta, finalVelocity)

func _update_sprite_rotation(delta: float, vel: Vector2) -> void:
	match sprite_rotation_mode:
		SpriteRotationMode.SPIN_CONTINUOUS:
			$Sprite2D.rotation_degrees -= rotationSpeed * delta
		SpriteRotationMode.FACE_MOVEMENT:
			if vel.length_squared() > 0.001:
				$Sprite2D.rotation = vel.angle() - deg_to_rad(90.0)

# ════════════════════════════════════════════════════════════════════════════
#  API PÚBLICA — llamada por el emitter
# ════════════════════════════════════════════════════════════════════════════

func set_properties(newDir: Vector2, newSpeed: int) -> void:
	direction = newDir
	speed     = float(newSpeed)

func modify_direction(
		newType: DirectionType, newGravInt: float, newDevAngle: int,
		newStart: float, newDur: float) -> void:
	directionType  = newType
	gravIntensity  = newGravInt
	deviationAngle = newDevAngle
	dirStartTime   = newStart
	dirDuration    = newDur
	if directionType == DirectionType.SINE_WAVE:
		_setup_sine_wave()

func modify_speed(fs: int, fst: float, ss: int, sst: float) -> void:
	modifySpeed  = true
	fstNewSpeed  = fs
	fstStartTime = fst
	sndNewSpeed  = ss
	sndStartTime = sst

func set_speed_curve(curve: Curve, baseSpd: float, dur: float = 3.0) -> void:
	_speedCurve         = curve
	_speedCurveBase     = baseSpd
	_speedCurveDuration = dur

func set_sub_emitter(scene: PackedScene, trigger: int, emitDelay: float) -> void:
	_subEmitterScene = scene
	_subEmitTrigger  = trigger
	_subEmitDelay    = emitDelay
	match trigger:
		2: _spawn_sub_emitter()          # IMMEDIATELY
		1: _schedule_sub_emitter_delayed() # AFTER_DELAY
		# 0 (ON_DEATH): se maneja en _exit_tree

# ════════════════════════════════════════════════════════════════════════════
#  DIRECCIÓN — lógica interna
# ════════════════════════════════════════════════════════════════════════════
func _update_direction(delta: float) -> void:
	match directionType:
		DirectionType.NONE, DirectionType.BOUNCE:
			return
		DirectionType.HOMING:
			_update_homing(delta)
			return
		DirectionType.SINE_WAVE:
			_sineAmplitude = float(deviationAngle) * (speed / 400.0) * 0.8
			return

	if elapsedTime < dirStartTime or elapsedTime > dirStartTime + dirDuration:
		return

	match directionType:
		DirectionType.AIM:
			direction = (GAME.get_player() - global_position).normalized()
		DirectionType.AIM_MOUSE:
			direction = (get_global_mouse_position() - global_position).normalized()
		DirectionType.GRAVITY:
			useGravity = true
		DirectionType.LEFT:
			direction = direction.rotated( deg_to_rad(deviationAngle) * delta)
		DirectionType.RIGHT:
			direction = direction.rotated(-deg_to_rad(deviationAngle) * delta)
		DirectionType.RANDOM:
			direction = direction.rotated(
				deg_to_rad(DRNG.drandf_range(-deviationAngle, deviationAngle)) * delta)

func _update_homing(delta: float) -> void:
	var desired   := (GAME.get_player() - global_position).normalized()
	var maxTurn   := deg_to_rad(float(deviationAngle)) * delta
	var angleDiff := direction.angle_to(desired)
	direction = direction.rotated(clamp(angleDiff, -maxTurn, maxTurn))

# ════════════════════════════════════════════════════════════════════════════
#  BOUNCE
# ════════════════════════════════════════════════════════════════════════════
func _handle_bounce() -> void:
	var rect := get_viewport_rect()
	if position.x < rect.position.x or position.x > rect.end.x: direction.x = -direction.x
	if position.y < rect.position.y or position.y > rect.end.y: direction.y = -direction.y

# ════════════════════════════════════════════════════════════════════════════
#  VELOCIDAD
# ════════════════════════════════════════════════════════════════════════════
func _update_speed_lerp() -> void:
	if   elapsedTime >= fstStartTime and elapsedTime <= sndStartTime: speed = float(fstNewSpeed)
	elif elapsedTime > sndStartTime:                                  speed = float(sndNewSpeed)

func _update_speed_curve() -> void:
	if _speedCurveDuration <= 0.0: return
	speed = _speedCurve.sample(clamp(elapsedTime / _speedCurveDuration, 0.0, 1.0)) * _speedCurveBase

func _apply_gravity() -> void:
	acceleration.y = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) * gravIntensity

# ════════════════════════════════════════════════════════════════════════════
#  SUB EMITTER
# ════════════════════════════════════════════════════════════════════════════
func _spawn_sub_emitter() -> void:
	if _subEmitFired or _subEmitterScene == null: return
	_subEmitFired = true
	var emitter = _subEmitterScene.instantiate()
	if _subEmitTrigger == 0:
		if "maxRounds" in emitter:
			emitter.maxRounds = 1
		GLOBAL.add_to_game.call_deferred(emitter)
		emitter.set_deferred("global_position", global_position)
	else:
		add_child(emitter)
		emitter.position = Vector2.ZERO

func _schedule_sub_emitter_delayed() -> void:
	await get_tree().create_timer(_subEmitDelay, false).timeout
	if is_instance_valid(self): _spawn_sub_emitter()

# ════════════════════════════════════════════════════════════════════════════
#  ÁRBOL DE ESCENA
# ════════════════════════════════════════════════════════════════════════════
func _enter_tree() -> void:
	CAMERA.tracked_nodes.append(self)

func _exit_tree() -> void:
	CAMERA.tracked_nodes.erase(self)
	if _subEmitterScene != null and _subEmitTrigger == 0 and not _subEmitFired:
		_subEmitFired = true
		var emitter = _subEmitterScene.instantiate()
		if "maxRounds" in emitter:
			emitter.maxRounds = 1
		GLOBAL.add_to_game.call_deferred(emitter)
		emitter.set_deferred("global_position", global_position)
