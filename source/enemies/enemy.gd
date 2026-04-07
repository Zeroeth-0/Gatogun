# source/enemies/enemy.gd
# Pure movement engine for all enemies
@tool
class_name BaseEnemy
extends CharacterBody2D

# ==============================================================================
# ENUMS
# ==============================================================================

enum Direction  { NORTH, WEST, SOUTH, EAST }
enum Handedness { LEFT, RIGHT }

# ==============================================================================
# EXPORTS
# ==============================================================================

## Enemy definition resource. Assign in inspector
@export var data: EnemyData

@export var preset_entry_speed: int = 120
@export var preset_hold_duration: float = 2.0
@export var preset_leave_speed: int = 150
@export var preset_intensity: int = 2

@export_category("Movement")
@export var direction_enum: Direction  = Direction.SOUTH
@export var handedness:     Handedness = Handedness.RIGHT
@export var scroll_follow:  bool       = false

@export_range(2.0, 30.0, 0.5) var acceleration: float = 10.0
@export_range(0.0, 1.0, 0.05) var micro_drift:  float = 0.25
@export var sprite_lean:  bool    = true
@export var sprite_node:  Node2D  = null

# ==============================================================================
# PUBLIC STATE
# ==============================================================================

## Lateral side sign, affected by handedness and phase inversions
var hside: int:
	get: return (-1 if handedness == Handedness.RIGHT else 1) * _hside_invert

var rand_side: int = 1

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var _phase_index:     int     = 0
var _phase_timer:     float   = 0.0
## Direction at phase start — used by CURVE to measure total rotation
var _phase_start_dir: Vector2 = Vector2.DOWN

var _direction:     Vector2 = Vector2.DOWN
var _hside_invert:  int     = 1
var _drift_phase:   float   = 0.0
var _speed_breath:  float   = 1.0
var _target_vel:    Vector2 = Vector2.ZERO
var _overshoot_vel: Vector2 = Vector2.ZERO
var _local_accel:   float   = 10.0

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_direction       = _dir_to_vec(direction_enum)
	_phase_start_dir = _direction
	_drift_phase     = DRNG.drandf_range(0.0, TAU)
	rand_side        = -1 if DRNG.drandi() % 2 == 0 else 1
	CAMERA.tracked_nodes.append(self)
	_on_ready()

func _exit_tree() -> void:
	CAMERA.tracked_nodes.erase(self)

## Override this in subclasses instead of _ready()
func _on_ready() -> void: pass

# ==============================================================================
# PHASE MANAGEMENT
# ==============================================================================

func get_current_phase() -> MovementPhase:
	if data == null or data.movement_phases.is_empty():
		return null
	return data.movement_phases[
		min(_phase_index, data.movement_phases.size() - 1)]

func advance_phase() -> void:
	if data == null or _phase_index >= data.movement_phases.size() - 1:
		return
	var current := data.movement_phases[_phase_index]
	_change_stage(current.invert_next)
	_phase_index += 1

# ==============================================================================
# MOVEMENT ENGINE
# ==============================================================================

func tick_movement(delta: float) -> void:
	_phase_timer += delta
	var phase := get_current_phase()
	if phase == null:
		return

	_speed_breath = 1.0 + sin(_phase_timer * 1.26 + _drift_phase) * 0.08
	_local_accel  = acceleration

	_dispatch_move(phase, delta)
	_smooth_move(delta)

	# Advance when duration expires. -1 means infinite (last phase)
	if phase.duration > 0.0 and _phase_timer >= phase.duration:
		advance_phase()

# ==============================================================================
# TRANSITION
# ==============================================================================

func _change_stage(should_invert: bool) -> void:
	var carry  := DRNG.drandf_range(0.18, 0.42)
	var recoil := DRNG.drandf_range(0.04, 0.13)
	var jolt   := DRNG.drandf_range(-0.09, 0.09)
	var perp   := Vector2(-_direction.y, _direction.x)

	_overshoot_vel  = velocity * carry
	_overshoot_vel -= _direction * float(_get_current_speed()) * recoil
	_overshoot_vel += perp      * float(_get_current_speed()) * jolt

	_phase_timer     = 0.0
	_phase_start_dir = _direction

	if should_invert:
		_hside_invert *= -1

func _get_current_speed() -> int:
	var ph := get_current_phase()
	return ph.speed if ph else 100

# ==============================================================================
# SMOOTH MOVEMENT + SPRITE LEAN
# ==============================================================================

func _smooth_move(delta: float) -> void:
	_overshoot_vel = _overshoot_vel.lerp(Vector2.ZERO, 7.0 * delta)
	var t = clamp(_local_accel * delta, 0.0, 1.0)
	velocity = velocity.lerp(_target_vel + _overshoot_vel, t)
	move_and_slide()

	if sprite_lean and is_instance_valid(sprite_node):
		var side_axis  := Vector2(-_direction.y, _direction.x)
		var lateral    := velocity.dot(side_axis)
		var lean_angle = clamp(lateral * 0.0025, -0.30, 0.30)
		sprite_node.rotation = lerp(sprite_node.rotation, lean_angle, 9.0 * delta)

# ==============================================================================
# MOVEMENT DISPATCH
# ==============================================================================

func _dispatch_move(phase: MovementPhase, delta: float) -> void:
	match phase.move_type:
		MovementPhase.MoveType.STRAIGHT:       _target_straight(phase)
		MovementPhase.MoveType.SINUSOIDAL:     _target_sinusoidal(phase)
		MovementPhase.MoveType.OSCILLATE:      _target_oscillate(phase)
		MovementPhase.MoveType.BREATH:         _target_breath(phase)
		MovementPhase.MoveType.BLOCK:          _target_block(phase)
		MovementPhase.MoveType.CENTER:         _target_center()
		MovementPhase.MoveType.CURVE:          _target_curve(phase, delta)
		MovementPhase.MoveType.CIRCULAR:       _target_circular(phase, delta)
		MovementPhase.MoveType.TOWARDS_PLAYER: _target_towards_player(phase)
		MovementPhase.MoveType.LEAVE:          _target_leave(phase)
		MovementPhase.MoveType.LEAVE_SIDE:     _target_leave_side(phase)
		MovementPhase.MoveType.DIAGONAL:       _target_diagonal(phase)
		MovementPhase.MoveType.STILL:          _target_still()

# ==============================================================================
# MOVEMENT TARGET FUNCTIONS
# ==============================================================================

func _target_straight(phase: MovementPhase) -> void:
	var side  := Vector2(-_direction.y, _direction.x)
	var drift := sin(_phase_timer * 2.7 + _drift_phase) * 18.0 * micro_drift
	_target_vel = _direction * float(phase.speed) * _speed_breath + side * drift

func _target_sinusoidal(phase: MovementPhase) -> void:
	var side   := Vector2(-_direction.y, _direction.x)
	var offset := sin(2.0 * _phase_timer + PI * 0.5) \
		* 55.0 * float(phase.intensity) * float(hside)
	_target_vel = _direction * float(phase.speed) * _speed_breath + side * offset

func _target_oscillate(phase: MovementPhase) -> void:
	var side   := Vector2(-_direction.y, _direction.x)
	var offset = sign(sin(2.0 * _phase_timer + PI * 0.5)) \
		* 55.0 * float(phase.intensity) * float(hside)
	_target_vel = _direction * float(phase.speed) * _speed_breath + side * offset

func _target_breath(phase: MovementPhase) -> void:
	var x_off := cos(2.1 * _phase_timer + _drift_phase) \
		* 16.0 * float(rand_side)
	var y_off := sin(3.3 * _phase_timer + _drift_phase) * 8.0
	_target_vel = Vector2(x_off, y_off) * float(phase.intensity) * _speed_breath

func _target_block(phase: MovementPhase) -> void:
	_local_accel = acceleration * 0.6
	var player_pos := GAME.get_player()
	var spd_f      := float(phase.speed)
	if direction_enum == Direction.NORTH or direction_enum == Direction.SOUTH:
		var dx := player_pos.x - global_position.x
		_target_vel = Vector2(
			clamp(dx * 4.0, -spd_f, spd_f),
			_direction.y * spd_f * 0.15)
	else:
		var dy := player_pos.y - global_position.y
		_target_vel = Vector2(
			_direction.x * spd_f * 0.15,
			clamp(dy * 4.0, -spd_f, spd_f))

func _target_center() -> void:
	var center := get_viewport().get_visible_rect().size * 0.5
	if direction_enum == Direction.NORTH or direction_enum == Direction.SOUTH:
		var dx := center.x - global_position.x
		_target_vel = Vector2(clamp(dx * 4.0, -220.0, 220.0), 0.0)
	else:
		var dy := center.y - global_position.y
		_target_vel = Vector2(0.0, clamp(dy * 4.0, -220.0, 220.0))

func _target_curve(phase: MovementPhase, delta: float) -> void:
	if phase.duration > 0.0:
		var rot_speed  := deg_to_rad(float(phase.deviation_angle)) / phase.duration
		var angle_left := absf(_direction.angle_to(_phase_start_dir))
		if angle_left < deg_to_rad(float(phase.deviation_angle)):
			_direction = _direction.rotated(rot_speed * float(hside) * delta)
	_target_vel = _direction * float(phase.speed) * _speed_breath

func _target_circular(phase: MovementPhase, delta: float) -> void:
	_direction = _direction.rotated(
		deg_to_rad(float(phase.deviation_angle)) * float(hside) * delta)
	_target_vel = _direction * float(phase.speed) * _speed_breath

func _target_towards_player(phase: MovementPhase) -> void:
	scroll_follow = false
	var to_player := GAME.get_player() - global_position
	if to_player.length_squared() > 0.0:
		_direction = to_player.normalized()
	_target_vel = _direction * float(phase.speed) * _speed_breath

func _target_leave(phase: MovementPhase) -> void:
	scroll_follow = false
	_target_vel = -_direction * float(phase.speed) * _speed_breath

func _target_leave_side(phase: MovementPhase) -> void:
	scroll_follow = false
	var h := float(hside)
	var new_dir: Vector2
	match direction_enum:
		Direction.NORTH: new_dir = Vector2( h,  1.0)
		Direction.SOUTH: new_dir = Vector2( h, -1.0)
		Direction.WEST:  new_dir = Vector2( 1.0,  h)
		Direction.EAST:  new_dir = Vector2(-1.0,  h)
		_: new_dir = Vector2.DOWN
	_target_vel = new_dir.normalized() * float(phase.speed) * _speed_breath

func _target_diagonal(phase: MovementPhase) -> void:
	var h := float(hside)
	var new_dir: Vector2
	match direction_enum:
		Direction.NORTH: new_dir = Vector2(-h * 1.5, -1.0)
		Direction.SOUTH: new_dir = Vector2(-h * 2.0,  1.0)
		Direction.WEST:  new_dir = Vector2(-1.0, -h * 1.5)
		Direction.EAST:  new_dir = Vector2( 1.0, -h * 1.5)
		_: new_dir = Vector2.DOWN
	_target_vel = new_dir.normalized() * float(phase.speed) * _speed_breath

func _target_still() -> void:
	_local_accel = acceleration * 0.22
	_target_vel  = Vector2.ZERO

# ==============================================================================
# STATIC HELPERS
# ==============================================================================

static func _dir_to_vec(d: Direction) -> Vector2:
	match d:
		Direction.NORTH: return Vector2.UP
		Direction.WEST:  return Vector2.LEFT
		Direction.EAST:  return Vector2.RIGHT
	return Vector2.DOWN
