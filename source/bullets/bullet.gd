# source/bullets/bullet.gd
# Base class for all enemy bullets
# REESCRITO CON ENFOQUE TOTALMENTE DIFERENTE
extends BaseBullet

# ==============================================================================
# SPRITE ROTATION
# ==============================================================================

enum SpriteRotationMode { SPIN_CONTINUOUS, FACE_MOVEMENT, ALL_DOWN }
@export var sprite_rotation_mode: SpriteRotationMode = SpriteRotationMode.SPIN_CONTINUOUS
var rotationSpeed: float = 400.0

# ==============================================================================
# DIRECTION MODIFIER
# ==============================================================================

enum DirectionType {
	NONE, AIM, GRAVITY,
	LEFT, RIGHT, RANDOM,
	HOMING, SINE_WAVE, BOUNCE
}

var directionType: int = DirectionType.NONE
var gravIntensity: float = 0.0
var deviationAngle: int = 0
var dirStartTime: float = 0.0
var dirDuration: float = 1.0

# ==============================================================================
# SPEED MODIFIER
# ==============================================================================

var modifySpeed: bool = false
var fstNewSpeed: int = 400
var fstStartTime: float = 0.0
var sndNewSpeed: int = 400
var _snd_start_abs: float = 0.0

var _speedCurve: Curve = null
var _speedCurveBase: float = 400.0
var _speedCurveDuration: float = 3.0

# ==============================================================================
# SUB EMITTER
# ==============================================================================

var _subEmitterScene: PackedScene = null
var _subEmitTrigger: int = 0
var _subEmitDelay: float = 0.5
var _subEmitFired: bool = false

# ==============================================================================
# PHYSICS STATE
# ==============================================================================

var useGravity: bool = false
var acceleration: Vector2 = Vector2.ZERO
var _sineAmplitude: float = 0.0
var _sineFrequency: float = 1.0

# ==============================================================================
# BPOOL HOOKS - RESET TOTAL
# ==============================================================================

func _on_acquired() -> void:
	# Reset completo para evitar contaminación del pool
	directionType   = DirectionType.NONE
	gravIntensity   = 0.0
	deviationAngle  = 0
	dirStartTime    = 0.0
	dirDuration     = 1.0
	
	useGravity      = false
	acceleration    = Vector2.ZERO
	_sineAmplitude  = 0.0
	_sineFrequency  = 1.0
	
	modifySpeed     = false
	fstNewSpeed     = 400
	fstStartTime    = 0.0
	sndNewSpeed     = 400
	_snd_start_abs  = 0.0
	_speedCurve     = null
	
	_subEmitterScene = null
	_subEmitTrigger  = 0
	_subEmitDelay    = 0.5
	_subEmitFired    = false
	
	# === RESETS CRÍTICOS ===
	_elapsed = 0.0
	velocity = Vector2.ZERO
	acceleration = Vector2.ZERO
	
	add_to_group("Enemy Bullet")


func _on_released() -> void:
	if _subEmitterScene != null and _subEmitTrigger == 0 and !_subEmitFired:
		_subEmitFired = true
		var emitter := _subEmitterScene.instantiate()
		if "maxRounds" in emitter:
			emitter.maxRounds = 1
		GLOBAL.add_to_game.call_deferred(emitter)
		emitter.set_deferred("global_position", global_position)
	
	remove_from_group("Enemy Bullet")
	_subEmitterScene = null


# ==============================================================================
# UPDATE HOOKS
# ==============================================================================

func _update(delta: float) -> void:
	# 1. Bounce (solo mientras está activo)
	if directionType == DirectionType.BOUNCE and _is_modifier_active():
		_handle_bounce()
	
	# 2. Dirección normal
	_update_direction(delta)
	
	# 3. Modificadores de velocidad
	if modifySpeed:     _update_speed_lerp()
	if _speedCurve:     _update_speed_curve()
	
	# 4. Física
	if useGravity:
		_apply_gravity()
		velocity += acceleration * delta
	else:
		velocity = direction * speed
	
	# 5. Rotación sprite
	_update_sprite_rotation(delta, velocity)
	
	# 6. Control de vida propio
	_check_out_of_bounds_and_release()


# ==============================================================================
# GET VELOCITY
# ==============================================================================

func _get_velocity(_delta: float) -> Vector2:
	var final_vel := velocity
	
	if _sineAmplitude > 0.0:
		var perp := velocity.normalized().orthogonal()
		final_vel += perp * _sineAmplitude * sin(TAU * _sineFrequency * _elapsed)
	
	return final_vel


# ==============================================================================
# NUEVA FUNCIÓN: Comprueba si el modificador de dirección sigue activo
# ==============================================================================

func _is_modifier_active() -> bool:
	if dirDuration <= 0.0:
		return true  # duración infinita
	return _elapsed <= dirStartTime + dirDuration


# ==============================================================================
# PUBLIC API
# ==============================================================================

func set_properties(newDir: Vector2, newSpeed: int) -> void:
	direction = newDir
	speed = float(newSpeed)
	velocity = direction * speed


func modify_direction(newType: int, newGravInt: float, newDevAngle: int, newStart: float, newDur: float) -> void:
	directionType  = newType
	gravIntensity  = newGravInt
	deviationAngle = newDevAngle
	dirStartTime   = newStart
	dirDuration    = newDur
	if directionType == DirectionType.SINE_WAVE:
		_setup_sine_wave()


func modify_speed(fs: int, fst: float, ss: int, sst: float) -> void:
	modifySpeed   = true
	fstNewSpeed   = fs
	fstStartTime  = fst
	sndNewSpeed   = ss
	_snd_start_abs = fst + sst


func set_speed_curve(curve: Curve, baseSpd: float, dur: float = 3.0) -> void:
	_speedCurve         = curve
	_speedCurveBase     = baseSpd
	_speedCurveDuration = dur


func set_sub_emitter(scene: PackedScene, trigger: int, emitDelay: float) -> void:
	_subEmitterScene = scene
	_subEmitTrigger  = trigger
	_subEmitDelay    = emitDelay
	match trigger:
		2: _spawn_sub_emitter()
		1: _schedule_sub_emitter_delayed()


# ==============================================================================
# DIRECTION LOGIC
# ==============================================================================

func _setup_sine_wave() -> void:
	_sineAmplitude = float(deviationAngle) * (speed / 400.0) * 0.8
	_sineFrequency = max(0.1, gravIntensity * 3.0)


func _update_direction(delta: float) -> void:
	if not _is_modifier_active():
		return  # ya acabó el tiempo del modificador
	
	match directionType:
		DirectionType.NONE, DirectionType.BOUNCE: return
		DirectionType.HOMING:
			_update_homing(delta)
			return
		DirectionType.SINE_WAVE:
			_sineAmplitude = float(deviationAngle) * (speed / 400.0) * 0.8
			return
	
	if _elapsed < dirStartTime:
		return
	
	match directionType:
		DirectionType.AIM:
			direction = (GAME.get_player() - global_position).normalized()
		DirectionType.GRAVITY:
			useGravity = true
		DirectionType.LEFT:
			direction = direction.rotated(deg_to_rad(float(deviationAngle)) * delta)
		DirectionType.RIGHT:
			direction = direction.rotated(-deg_to_rad(float(deviationAngle)) * delta)
		DirectionType.RANDOM:
			direction = direction.rotated(deg_to_rad(DRNG.drandf_range(-float(deviationAngle), float(deviationAngle))) * delta)


func _update_homing(delta: float) -> void:
	if not _is_modifier_active():
		return
	var desired := (GAME.get_player() - global_position).normalized()
	var max_turn := deg_to_rad(float(deviationAngle) * 2.0) * delta
	var angle_diff := direction.angle_to(desired)
	direction = direction.rotated(clamp(angle_diff, -max_turn, max_turn))


# ==============================================================================
# BOUNCE
# ==============================================================================

func _handle_bounce() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	
	var cam := vp.get_camera_2d()
	var margin := 8.0
	
	var left := 0.0
	var right := 680.0
	var top := 0.0
	var bottom := 730.0
	
	if cam != null:
		var viewport_rect := cam.get_viewport_rect()
		var half := viewport_rect.size / (cam.zoom * 2.0)
		
		left   = cam.global_position.x - half.x
		right  = cam.global_position.x + half.x
		top    = cam.global_position.y - half.y
		bottom = cam.global_position.y + half.y
	
	# Rebote horizontal
	if position.x <= left + margin:
		position.x = left + margin
		direction.x = -direction.x
		velocity.x = -velocity.x
	elif position.x >= right - margin:
		position.x = right - margin
		direction.x = -direction.x
		velocity.x = -velocity.x
	
	# Rebote vertical
	if position.y <= top + margin:
		position.y = top + margin
		direction.y = -direction.y
		velocity.y = -velocity.y
	elif position.y >= bottom - margin:
		position.y = bottom - margin
		direction.y = -direction.y
		velocity.y = -velocity.y


# ==============================================================================
# CONTROL DE VIDA
# ==============================================================================

func _check_out_of_bounds_and_release() -> void:
	if directionType == DirectionType.BOUNCE:
		return
	
	var vp := get_viewport()
	if vp == null:
		return
	
	var cam := vp.get_camera_2d()
	var left := 0.0
	var right := 680.0
	var top := 0.0
	var bottom := 730.0
	
	if cam != null:
		var viewport_rect := cam.get_viewport_rect()
		var half := viewport_rect.size / (cam.zoom * 2.0)
		
		left   = cam.global_position.x - half.x
		right  = cam.global_position.x + half.x
		top    = cam.global_position.y - half.y
		bottom = cam.global_position.y + half.y
	
	var rect := Rect2(left, top, right - left, bottom - top)
	
	if not rect.grow(80.0).has_point(position):
		BPOOL.release(self)


# ==============================================================================
# SPEED + GRAVITY + SPRITE
# ==============================================================================

func _update_speed_lerp() -> void:
	if _elapsed >= fstStartTime and _elapsed <= _snd_start_abs:
		speed = float(fstNewSpeed)
	elif _elapsed > _snd_start_abs:
		speed = float(sndNewSpeed)


func _update_speed_curve() -> void:
	if _speedCurveDuration <= 0.0: return
	speed = _speedCurve.sample(clamp(_elapsed / _speedCurveDuration, 0.0, 1.0)) * _speedCurveBase


func _apply_gravity() -> void:
	acceleration.y = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) * gravIntensity


func _update_sprite_rotation(delta: float, vel: Vector2) -> void:
	if !has_node("Sprite2D"): return
	match sprite_rotation_mode:
		SpriteRotationMode.SPIN_CONTINUOUS:
			$Sprite2D.rotation_degrees -= rotationSpeed * delta
		SpriteRotationMode.FACE_MOVEMENT:
			if vel.length_squared() > 0.001:
				$Sprite2D.rotation = vel.angle() - deg_to_rad(90.0)
		SpriteRotationMode.ALL_DOWN:
			$Sprite2D.rotation = deg_to_rad(90.0)


# ==============================================================================
# SUB EMITTER
# ==============================================================================

func _spawn_sub_emitter() -> void:
	if _subEmitFired or _subEmitterScene == null: return
	_subEmitFired = true
	var emitter := _subEmitterScene.instantiate()
	if "maxRounds" in emitter: emitter.maxRounds = 1
	GLOBAL.add_to_game.call_deferred(emitter)
	emitter.set_deferred("global_position", global_position)


func _schedule_sub_emitter_delayed() -> void:
	get_tree().create_timer(_subEmitDelay, false).timeout.connect(
		func() -> void:
			if is_instance_valid(self) and !isCancelled:
				_spawn_sub_emitter()
	, CONNECT_ONE_SHOT)
