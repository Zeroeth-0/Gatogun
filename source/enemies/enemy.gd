extends CharacterBody2D

# === ENUMS ===
enum MoveType {
	STRAIGHT, SINUSOIDAL, OSCILLATE, BREATH,
	BLOCK, CENTER, CURVE, CIRCULAR,
	TOWARDS_PLAYER, LEAVE, LEAVE_SIDE, DIAGONAL, STILL
}
enum Direction  { NORTH, WEST, SOUTH, EAST }
enum Handedness { LEFT, RIGHT }
enum EnemyType  { STD, MID, ELITE }

# === EXPORTS GENERALES ===
@export var typeEnum:      EnemyType  = EnemyType.STD
@export var size:          int        = 20
@export var intensity:     int        = 1
@export_range(0, 90, 15) var deviationAngle: int = 90
@export var scrollFollow:  bool       = false
@export var isGround:      bool       = false
@export var scoreCount:    int        = 1
@export var directionEnum: Direction  = Direction.SOUTH
@export var handedness:    Handedness = Handedness.RIGHT

@export_category("CHILDHOOD")
@export var childhood:     MoveType   = MoveType.STRAIGHT
@export var childDuration: float      = 1.0
@export var childSpeed:    int        = 100
@export var adultInvert:   bool       = false

@export_category("ADULTHOOD")
@export var adulthood:     MoveType   = MoveType.STRAIGHT
@export var adultDuration: float      = 1.0
@export var adultSpeed:    int        = 100
@export var oldInvert:     bool       = false

@export_category("OLD AGE")
@export var oldAge:        MoveType   = MoveType.STRAIGHT
@export var oldSpeed:      int        = 100

@export_category("FEEL")
## Qué tan rápido alcanza la velocidad objetivo. Más alto = más ágil/mecánico.
@export_range(2.0, 30.0, 0.5) var acceleration: float = 10.0
## Cuánto oscila lateralmente en trayectorias rectas. 0 = robot, 1 = insecto.
@export_range(0.0, 1.0, 0.05) var micro_drift: float = 0.25
## El sprite se inclina con la inercia lateral. Requiere sprite_node asignado.
@export var sprite_lean: bool    = true
@export var sprite_node: Node2D  = null

# === ESTADO INTERNO ===
var currentStage:     String  = "childhood"
var stageTimer:       float   = 0.0
var speed:            int     = 200
var direction:        Vector2 = Vector2.DOWN
var currentDirection: Vector2 = Vector2.ZERO

# Velocidad objetivo: cada función de movimiento escribe aquí.
# _smooth_move() hace el lerp cada frame — nada llama move_and_slide() directamente.
var _target_vel:    Vector2 = Vector2.ZERO
# Fase aleatoria única por instancia: evita sincronía en formaciones.
var _drift_phase:   float   = 0.0
# Respiración de velocidad orgánica (±8%).
var _speed_breath:  float   = 1.0
# Aceleración local del frame: se resetea en apply_movement, funciones la sobreescriben.
var _local_accel:   float   = 10.0
# Impulso de transición entre fases: decae en _smooth_move dando sensación de peso.
var _overshoot_vel: Vector2 = Vector2.ZERO
# Inversión acumulada de hSide: hSide es computed (solo lectura), no se puede mutar.
var _hSide_invert:  int     = 1
var randSide:       int     = 1

# hSide: sentido lateral según handedness e inversiones de fase acumuladas.
var hSide: int:
	get: return (-1 if handedness == Handedness.RIGHT else 1) * _hSide_invert

# ─────────────────────────────────────────────
func _ready() -> void:
	direction        = _dir_to_vec(directionEnum)
	currentDirection = direction
	stageTimer       = 0.0
	randSide         = -1 if DRNG.drandi() % 2 == 0 else 1
	_drift_phase     = DRNG.drandf_range(0.0, TAU)

# Helper puro: enum → Vector2. Static evita instanciar dict por objeto.
static func _dir_to_vec(d: Direction) -> Vector2:
	match d:
		Direction.NORTH: return Vector2.UP
		Direction.WEST:  return Vector2.LEFT
		Direction.EAST:  return Vector2.RIGHT
	return Vector2.DOWN  # SOUTH por defecto

# ─────────────────────────────────────────────
# CAMBIO DE FASE — inyecta vida orgánica en la transición
# ─────────────────────────────────────────────
func _change_stage(nextStage: String, shouldInvert: bool) -> void:
	# Carry: el enemigo "se lleva" parte de la inercia actual al cambiar de fase.
	var carry  := DRNG.drandf_range(0.18, 0.42)
	# Recoil: pequeño rebote en sentido contrario al movimiento.
	var recoil := DRNG.drandf_range(0.04, 0.13)
	# Jolt lateral: micro-tambaleo perpendicular, da sensación de "sacudón".
	var jolt   := DRNG.drandf_range(-0.09, 0.09)
	var perp   := Vector2(-direction.y, direction.x)

	# La suma de carry (adelante) y recoil (atrás) crea el efecto
	# "se pasa, rebota un poco, se asienta" cuando el overshoot decae.
	_overshoot_vel  = velocity * carry
	_overshoot_vel -= direction * float(speed) * recoil
	_overshoot_vel += perp * float(speed) * jolt

	currentStage     = nextStage
	stageTimer       = 0.0
	currentDirection = direction
	if shouldInvert:
		_hSide_invert *= -1

# ─────────────────────────────────────────────
# PUNTO DE ENTRADA — llamar cada frame desde la subclase
# ─────────────────────────────────────────────
func apply_movement(moveType: MoveType, dur: float, delta: float) -> void:
	_speed_breath = 1.0 + sin(stageTimer * 1.26 + _drift_phase) * 0.08
	_local_accel  = acceleration  # reset antes del match; cada función puede ajustarlo

	match moveType:
		MoveType.STRAIGHT:       _target_straight()
		MoveType.SINUSOIDAL:     _target_sinusoidal()
		MoveType.OSCILLATE:      _target_oscillate()
		MoveType.BREATH:         _target_breath()
		MoveType.BLOCK:          _target_block()
		MoveType.CENTER:         _target_center()
		MoveType.CURVE:          _target_curve(dur, delta)
		MoveType.CIRCULAR:       _target_circular(delta)
		MoveType.TOWARDS_PLAYER: _target_towards_player()
		MoveType.LEAVE:          _target_leave()
		MoveType.LEAVE_SIDE:     _target_leave_side()
		MoveType.DIAGONAL:       _target_diagonal()
		MoveType.STILL:          _target_still()

	_smooth_move(delta)

# ─────────────────────────────────────────────
# MOTOR DE SUAVIZADO + VIDA
# ─────────────────────────────────────────────
func _smooth_move(delta: float) -> void:
	# El overshoot de transición decae exponencialmente; la tasa alta (7.0)
	# hace que dure ~0.3-0.5s: notorio pero no persistente.
	_overshoot_vel = _overshoot_vel.lerp(Vector2.ZERO, 7.0 * delta)

	var t = clamp(_local_accel * delta, 0.0, 1.0)
	velocity = velocity.lerp(_target_vel + _overshoot_vel, t)
	move_and_slide()

	# Lean del sprite: se inclina con la componente lateral de la velocidad REAL.
	# El retraso natural del lerp hace que el lean reaccione con inercia.
	if sprite_lean and is_instance_valid(sprite_node):
		var side_axis  := Vector2(-direction.y, direction.x)
		var lateral    := velocity.dot(side_axis)
		var lean_angle = clamp(lateral * 0.0025, -0.30, 0.30)
		sprite_node.rotation = lerp(sprite_node.rotation, lean_angle, 9.0 * delta)

# ─────────────────────────────────────────────
# FUNCIONES DE OBJETIVO DE VELOCIDAD
# Solo escriben en _target_vel (y opcionalmente _local_accel).
# ─────────────────────────────────────────────

func _target_straight() -> void:
	# Micro-drift: oscilación lateral con frecuencia ligeramente irracional
	# para que no suene periódico/mecánico. Evoca vuelo de insecto en línea recta.
	var side  := Vector2(-direction.y, direction.x)
	var drift := sin(stageTimer * 2.7 + _drift_phase) * 18.0 * micro_drift
	_target_vel = direction * float(speed) * _speed_breath + side * drift

func _target_sinusoidal() -> void:
	var side   := Vector2(-direction.y, direction.x)
	var offset := sin(2.0 * stageTimer + PI * 0.5) * 55.0 * float(intensity) * float(hSide)
	_target_vel = direction * float(speed) * _speed_breath + side * offset

func _target_oscillate() -> void:
	# Oscilación cuadrada: el lerp del motor suaviza el salto brusco,
	# el enemigo "arranca" lateralmente con inercia en vez de teleportarse.
	var side   := Vector2(-direction.y, direction.x)
	var offset = sign(sin(2.0 * stageTimer + PI * 0.5)) * 55.0 * float(intensity) * float(hSide)
	_target_vel = direction * float(speed) * _speed_breath + side * offset

func _target_breath() -> void:
	# Dos frecuencias distintas en X e Y para evitar órbitas circulares perfectas.
	var x_off := cos(2.1 * stageTimer + _drift_phase) * 16.0 * float(randSide)
	var y_off := sin(3.3 * stageTimer + _drift_phase) * 8.0
	_target_vel = Vector2(x_off, y_off) * float(intensity) * _speed_breath

func _target_block() -> void:
	# Aceleración reducida: sensación de arrastre/peso al seguir al jugador.
	_local_accel = acceleration * 0.6
	var player_pos := GAME.get_player()
	var spd_f      := float(speed)
	if directionEnum == Direction.NORTH or directionEnum == Direction.SOUTH:
		var dx := player_pos.x - global_position.x
		_target_vel = Vector2(clamp(dx * 4.0, -spd_f, spd_f),
							  direction.y * spd_f * 0.15)
	else:
		var dy := player_pos.y - global_position.y
		_target_vel = Vector2(direction.x * spd_f * 0.15,
							  clamp(dy * 4.0, -spd_f, spd_f))

func _target_center() -> void:
	# Amortiguación proporcional: cuanto más cerca del centro, más lento.
	# Crea el efecto de "asentarse" sin clavarse en seco.
	var center := get_viewport().get_visible_rect().size * 0.5
	if directionEnum == Direction.NORTH or directionEnum == Direction.SOUTH:
		var dx := center.x - global_position.x
		_target_vel = Vector2(clamp(dx * 4.0, -220.0, 220.0), 0.0)
	else:
		var dy := center.y - global_position.y
		_target_vel = Vector2(0.0, clamp(dy * 4.0, -220.0, 220.0))

func _target_curve(dur: float, delta: float) -> void:
	if dur > 0.0:
		var rot_speed  := deg_to_rad(float(deviationAngle)) / dur
		# angle_to: ángulo que falta para volver a currentDirection.
		# Cuando ha girado deviationAngle desde el inicio de la fase, se detiene.
		var angle_left := absf(direction.angle_to(currentDirection))
		if angle_left < deg_to_rad(float(deviationAngle)):
			direction = direction.rotated(rot_speed * float(hSide) * delta)
	_target_vel = direction * float(speed) * _speed_breath

func _target_circular(delta: float) -> void:
	direction   = direction.rotated(deg_to_rad(float(deviationAngle)) * float(hSide) * delta)
	_target_vel = direction * float(speed) * _speed_breath

func _target_towards_player() -> void:
	scrollFollow   = false
	var to_player  := GAME.get_player() - global_position
	if to_player.length_squared() > 0.0:
		direction = to_player.normalized()
	_target_vel = direction * float(speed) * _speed_breath

func _target_leave() -> void:
	scrollFollow = false
	_target_vel  = -direction * float(speed) * _speed_breath

func _target_leave_side() -> void:
	scrollFollow = false
	var h := float(hSide)
	var new_dir: Vector2
	match directionEnum:
		Direction.NORTH: new_dir = Vector2( h,  1.0)
		Direction.SOUTH: new_dir = Vector2( h, -1.0)
		Direction.WEST:  new_dir = Vector2( 1.0,  h)
		Direction.EAST:  new_dir = Vector2(-1.0,  h)
	_target_vel = new_dir.normalized() * float(speed) * _speed_breath

func _target_diagonal() -> void:
	var h := float(hSide)
	var new_dir: Vector2
	match directionEnum:
		Direction.NORTH: new_dir = Vector2(-h * 1.5, -1.0)
		Direction.SOUTH: new_dir = Vector2(-h * 2.0,  1.0)
		Direction.WEST:  new_dir = Vector2(-1.0, -h * 1.5)
		Direction.EAST:  new_dir = Vector2( 1.0, -h * 1.5)
	_target_vel = new_dir.normalized() * float(speed) * _speed_breath

func _target_still() -> void:
	# Aceleración muy baja: el enemigo frena con peso pronunciado, estilo mech de Ketsui.
	# El overshoot de transición añade el rebote inicial; el lerp lento hace el resto.
	_local_accel = acceleration * 0.22
	_target_vel  = Vector2.ZERO

# ─────────────────────────────────────────────
# CÁMARA
# ─────────────────────────────────────────────
func _enter_tree() -> void:
	CAMERA.tracked_nodes.append(self)

func _exit_tree() -> void:
	CAMERA.tracked_nodes.erase(self)
