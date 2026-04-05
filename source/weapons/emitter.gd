# source/weapons/emitter.gd
# Interprets EmitterConfig and fires bullets
@tool
class_name BulletEmitter
extends Marker2D

# ==============================================================================
# INSPECTOR
# ==============================================================================

@export var config: EmitterConfig
enum PresetType {
	NONE,
	AIMED_STREAM, AIMED_SPREAD, AIMED_WALL, SPEED_LAYERS,
	RING, ALTERNATING_RING, LAYERED_RING, SPINNING_RING,
	SPIRAL, DOUBLE_SPIRAL, N_SPIRAL,
	SWEEP, SYMMETRIC_SWEEP,
	HOMING_BURST, DELAYED_HOMING,
	CURTAIN, SCATTER
}
@export var apply_preset: PresetType = PresetType.NONE:
	set(value):
		apply_preset = value
		if value != PresetType.NONE and Engine.is_editor_hint():
			_apply_preset(value)
			apply_preset = PresetType.NONE
@export var preset_speed: float = 300.0
@export var preset_arms: int = 8
@export var preset_spread: float = 45.0
@export var preset_warm_up: float = 1.0

func _apply_preset(p: PresetType) -> void:
	match p:
		PresetType.AIMED_STREAM:
			config = EmitterPresets.aimed_stream(preset_speed, preset_warm_up)
		PresetType.AIMED_SPREAD:
			config = EmitterPresets.aimed_spread(preset_arms, preset_spread, preset_speed, preset_warm_up)
		PresetType.AIMED_WALL:
			config = EmitterPresets.aimed_wall(preset_arms, preset_spread, preset_speed, preset_warm_up)
		PresetType.SPEED_LAYERS:
			config = EmitterPresets.speed_layers(preset_arms, preset_speed * 0.6, preset_speed * 1.4)
		PresetType.RING:
			config = EmitterPresets.ring(preset_arms, preset_speed, 0.0, preset_warm_up)
		PresetType.ALTERNATING_RING:
			config = EmitterPresets.alternating_ring(preset_arms, preset_arms - 1, preset_speed, preset_warm_up)
		PresetType.LAYERED_RING:
			config = EmitterPresets.layered_ring(preset_arms, preset_speed * 0.7, preset_speed * 1.3)
		PresetType.SPINNING_RING:
			config = EmitterPresets.spinning_ring(preset_arms, preset_speed, 45.0, preset_warm_up)
		PresetType.SPIRAL:
			config = EmitterPresets.spiral(preset_speed, 60.0, preset_warm_up)
		PresetType.DOUBLE_SPIRAL:
			config = EmitterPresets.double_spiral(preset_speed, 60.0, preset_warm_up)
		PresetType.N_SPIRAL:
			config = EmitterPresets.n_spiral(preset_arms, preset_speed, 45.0, preset_warm_up)
		PresetType.SWEEP:
			config = EmitterPresets.sweep(preset_arms, preset_spread, preset_speed, 12, preset_warm_up)
		PresetType.SYMMETRIC_SWEEP:
			config = EmitterPresets.symmetric_sweep(preset_spread, preset_speed, 10, preset_warm_up)
		PresetType.HOMING_BURST:
			config = EmitterPresets.homing_burst(preset_arms, preset_speed, 120.0, preset_warm_up)
		PresetType.DELAYED_HOMING:
			config = EmitterPresets.delayed_homing(preset_arms, preset_speed, 0.5, 90.0, preset_warm_up)
		PresetType.CURTAIN:
			config = EmitterPresets.curtain(preset_arms, preset_speed, preset_warm_up)
		PresetType.SCATTER:
			config = EmitterPresets.scatter(preset_arms, preset_speed)
	notify_property_list_changed()

# ==============================================================================
# PUBLIC STATE
# ==============================================================================

var total_rounds: int = 0
## Set to false to suppress fire without stopping the loop
var can_shoot: bool = true

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var _running:        bool  = false
var _stop_rotation:  bool  = false
var _rotation_deg:   float = 0.0
var _rotation_dir:   int   = 1
var _ping_pong_dir:  int   = 1
var _bround:         int   = 0
var _usable_arms:    int   = 1
var _current_speed:  float = 0.0

# Rank snapshot — taken once at start, not polled
var _rank: int = 0

# Effective values after rank scaling
var _eff_speed:    float = 0.0
var _eff_arms:     int   = 1
var _eff_burst:    int   = 1
var _eff_rot_spd:  float = 0.0

# Direction cache
var _base_direction: Vector2 = Vector2.DOWN
var _aim_target:     Vector2 = Vector2.ZERO

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	if config == null:
		push_error("No config assigned")
		return
	_start()

func _process(delta: float) -> void:
	if !_running or _stop_rotation: return
	if config.ping_pong and config.sync_ping_pong_to_burst: return
	_rotation_deg += _eff_rot_spd * delta * float(_rotation_dir)
	_handle_rotation_bounds()

func _exit_tree() -> void:
	_running = false

# ==============================================================================
# PUBLIC API
# ==============================================================================

## Assign a new config and restart the fire loop
func set_config(new_config: EmitterConfig) -> void:
	config = new_config
	_running = false
	await get_tree().process_frame
	_start()

## Stop firing. The node stays in the tree
func stop() -> void:
	_running = false

## Resume after stop()
func resume() -> void:
	if config and not _running:
		_running = true

# ==============================================================================
# STARTUP
# ==============================================================================

func _start() -> void:
	_rank          = RANK.rank
	_bround        = 0
	total_rounds   = 0
	_rotation_deg  = 0.0
	_ping_pong_dir = -1 if config.ping_pong_invert else 1
	_running       = true
	
	_apply_rank_scaling()
	_usable_arms   = _eff_arms
	_current_speed = _eff_speed
	
	_base_direction = EmitterConfig.direction_to_vec(config.direction_enum)\
		.rotated(deg_to_rad(config.dir_deviation))

	_init_pingpong_angle()
	_reset_rotation_direction()
	_fire_loop()

# ==============================================================================
# RANK SCALING
# ==============================================================================

func _apply_rank_scaling() -> void:
	var r    := float(_rank)
	var p    := pow(r / 6.0, 2.0)
	
	_eff_speed   = config.base_speed
	_eff_arms    = config.arms
	_eff_burst   = config.burst_count
	_eff_rot_spd = config.rotation_speed
	
	# Rank 0: slight nerf to ease the game for beginners
	if _rank == 0:
		_eff_speed   *= 0.85
		_eff_rot_spd *= 0.85
		return
		
	if _rank <= 1: return
	
	if config.rank_scale_speed:
		_eff_speed = lerp(_eff_speed, _eff_speed * (1.0 + config.rank_factor), p)
	
	if config.rank_scale_arms:
		_eff_arms = int(lerp(float(_eff_arms),
			float(_eff_arms) * (1.0 + config.rank_factor), p))
	
	if config.rank_scale_burst:
		if _eff_burst > 1:
			_eff_burst = int(lerp(float(_eff_burst),
				float(_eff_burst) * (1.0 + config.rank_factor), p))
		else:
			# Single-shot bursts scale to multi-shot at high rank
			_eff_burst = int(lerp(1.0, 1.0 + config.rank_factor * 3.0, p))
	
	if config.rank_scale_rotation:
		_eff_rot_spd = lerp(_eff_rot_spd,
			_eff_rot_spd * (1.0 + config.rank_factor), p)

# ==============================================================================
# MAIN FIRE LOOP
# ==============================================================================

func _fire_loop() -> void:
	if not _running: return
	if config.delay > 0.0: await get_tree().create_timer(config.delay, false).timeout
	_do_burst_cycle()

func _do_burst_cycle() -> void:
	if not _running: return
	
	var is_sync := config.ping_pong and config.sync_ping_pong_to_burst
	if not config.burst_rotation and not is_sync: _stop_rotation = true
	
	_fire_all_shots(is_sync)

func _fire_all_shots(is_sync: bool) -> void:
	if not _running: return
	
	# Capture aim target once per burst
	if config.aim_at_player: _aim_target = GAME.get_player()
	
	var shot_speed := _current_speed
	_shoot_one_shot(0, _eff_burst, is_sync, shot_speed)

func _shoot_one_shot(shot_i: int, total: int, is_sync: bool, speed: float) -> void:
	if not _running: return
	if is_sync: _rotation_deg = _sync_angle_for_shot(shot_i)
	if can_shoot: _fire(speed)
	if shot_i >= total - 1:
		_on_burst_finished(is_sync)
		return
	
	var next_speed := speed
	if config.speed_var_target == EmitterConfig.SpeedVarTarget.BULLET:
		next_speed *= config.speed_variation
	
	await get_tree().create_timer(config.bullet_interval, false).timeout
	_shoot_one_shot(shot_i + 1, total, is_sync, next_speed)

func _on_burst_finished(is_sync: bool) -> void:
	if not _running: return
	# Finalize sync ping-pong position
	if is_sync:
		_rotation_deg = _sync_angle_for_shot(_eff_burst - 1)
		_ping_pong_dir *= -1
	
	_usable_arms = _eff_arms
	if config.grow_with_round: _usable_arms += _bround
	
	if not config.burst_rotation and not is_sync:
		_stop_rotation = false
		_reset_rotation_direction()
	
	_bround += 1
	total_rounds += 1
	
	if not config.keep_speed: _current_speed = _eff_speed
	
	if config.max_rounds >= 0 and total_rounds >= config.max_rounds:
		_running = false
		queue_free()
		return
	
	await get_tree().create_timer(config.warm_up, false).timeout
	_do_burst_cycle()

# ==============================================================================
# FIRE
# ==============================================================================

func _fire(current_speed: float) -> void:
	var arms_to_use := alter_arms_for_round()
	var half_n := maxf(float(arms_to_use - 1) / 2.0, 0.001)
	var base_dir := _get_base_direction()
	var gap_rad := deg_to_rad(config.symmetry_gap * 0.5) if config.use_symmetry else 0.0
	
	for r in config.repeat_count:
		var rep_offset := deg_to_rad(
			float(config.repeat_angle) / float(config.repeat_count) * float(r))
		var rep_dir := base_dir.rotated(deg_to_rad(_rotation_deg) + rep_offset)
		
		var spread_step := float(config.spread_offset) / float(arms_to_use)
		var divisor := float(arms_to_use) if config.spread_angle == 360.0 \
			else maxf(1.0, float(arms_to_use - 1))
		var angle_step := config.spread_angle / divisor
		
		var arm_speed := current_speed
		
		for i in arms_to_use:
			# Skip chance
			if config.skip_chance > 0.0 \
					and DRNG.drandf_range(0.0, 1.0) < config.skip_chance: continue
			# Per-arm speed variation
			if config.speed_var_target == EmitterConfig.SpeedVarTarget.ARM:
				arm_speed *= config.speed_variation
			# Speed wave peak bonus
			var peak_bonus := 0.0
			if config.peak_count > 0 and arms_to_use > 1:
				var x := float(i) / float(arms_to_use - 1)
				peak_bonus = abs(sin(x * float(config.peak_count) * PI)) \
					* config.peak_speed_bonus
			# Spawn noise
			var noise := Vector2(
				DRNG.drandf_range(-float(config.random_offset), float(config.random_offset)),
				DRNG.drandf_range(-float(config.random_offset), float(config.random_offset)))
			# Direction and position
			var shoot_dir: Vector2
			var shoot_pos: Vector2
			# Parallel shooting
			if config.parallel:
				shoot_dir = rep_dir.rotated(gap_rad)
				var norm_d = abs(float(i) - half_n) / half_n
				var steep_p := pow(norm_d, 1.0 / config.steepness_sharpness)
				var steep_d := steep_p * half_n * float(config.steepness)
				var lateral := float(i) - float(arms_to_use) / 2.0
				shoot_pos = global_position + noise \
					+ shoot_dir * steep_d \
					+ shoot_dir.orthogonal() * (lateral * spread_step + spread_step / 2.0)
			else:
				var a_off := 0.0
				if arms_to_use > 1:
					a_off = angle_step * float(i) - config.spread_angle / 2.0 \
						+ float(DRNG.drandf_range(-config.random_angle, config.random_angle))
				shoot_dir = rep_dir.rotated(gap_rad + deg_to_rad(a_off))
				if config.spread_angle == 360.0: shoot_dir *= -1.0
				shoot_pos = global_position + noise
			
			# Fire arm_width bullets per arm
			for j in config.arm_width:
				var w_off := (float(j) - float(config.arm_width - 1) / 2.0) \
					* spread_step * config.arm_spacing_factor
				var final_pos := shoot_pos + shoot_dir.orthogonal() * w_off
				var final_spd := (arm_speed + peak_bonus) \
					* DRNG.drandf_range(1.0 - config.random_speed, 1.0 + config.random_speed)
				# Per-bullet speed variation
				if config.speed_var_target == EmitterConfig.SpeedVarTarget.BULLET:
					arm_speed *= config.speed_variation
				var arm_delay := float(i) * config.intra_arm_delay \
					+ DRNG.drandf_range(0.0, config.stagger_delay)
				_shoot_bullet(shoot_dir, final_pos, final_spd, arm_delay, false)
				# Symmetry mirror
				if config.use_symmetry:
					var mirror_dir := _mirror_direction(shoot_dir, rep_dir)
					var mirror_pos: Vector2
					if config.parallel:
						var norm_d2 = abs(float(i) - half_n) / half_n
						var steep_p2 := pow(norm_d2, 1.0 / config.steepness_sharpness)
						var steep_d2 := steep_p2 * half_n * float(config.steepness)
						var lateral2 := float(i) - float(arms_to_use) / 2.0
						mirror_pos = global_position + noise \
							+ mirror_dir * steep_d2 \
							+ mirror_dir.orthogonal() \
								* (-(lateral2 * spread_step + spread_step / 2.0) - w_off)
					else:
						mirror_pos = shoot_pos + mirror_dir.orthogonal() * (-w_off)
					_shoot_bullet(mirror_dir, mirror_pos, final_spd, arm_delay, true)

# ==============================================================================
# SHOOT ONE BULLET
# ==============================================================================

func _shoot_bullet(
		dir: Vector2,
		pos: Vector2,
		spd: float,
		delay: float,
		is_mirror: bool) -> void:
	if delay > 0.0: _shoot_bullet_delayed(dir, pos, spd, delay, is_mirror)
	else: _spawn_bullet(dir, pos, spd, is_mirror)

func _shoot_bullet_delayed(
		dir: Vector2,
		pos: Vector2,
		spd: float,
		wait: float,
		is_mirror: bool) -> void:
	await get_tree().create_timer(wait, false).timeout
	if _running and is_inside_tree(): _spawn_bullet(dir, pos, spd, is_mirror)

func _spawn_bullet(
		dir: Vector2,
		pos: Vector2,
		spd: float,
		is_mirror: bool) -> void:
	if config.bullet_scene == null:
		push_error("BulletEmitter '%s': bullet_scene is null." % name)
		return
	var bullet: Node = BPOOL.acquire(config.bullet_scene)
	if bullet == null: return
	# Configure behavior modifier
	var behavior := config.behavior_type
	if is_mirror: behavior = _flip_lr_behavior(behavior)
	bullet.set_properties(dir, int(spd))
	bullet.modify_direction(
		behavior,
		config.behavior_intensity,
		config.behavior_deviation,
		config.behavior_start_time,
		config.behavior_duration)
	if config.modify_speed:
		bullet.modify_speed(
			config.speed_phase_1,
			config.speed_phase_1_time,
			config.speed_phase_2,
			config.speed_phase_2_time)
	if config.speed_curve != null and bullet.has_method("set_speed_curve"):
		bullet.set_speed_curve(config.speed_curve, config.base_speed,
			config.speed_curve_duration)
	# Position must be set after BPOOL.acquire()
	bullet.global_position = pos + dir * float(config.distance_center)
	# Sub-emitter
	if config.sub_emitter_scene != null and bullet.has_method("set_sub_emitter"):
		bullet.set_sub_emitter(
			config.sub_emitter_scene,
			int(config.sub_trigger),
			config.sub_delay)

# ==============================================================================
# DIRECTION HELPERS
# ==============================================================================

func _get_base_direction() -> Vector2:
	if config.aim_at_player:
		return (_aim_target - global_position).normalized()
	return _base_direction

func _mirror_direction(dir: Vector2, axis: Vector2) -> Vector2:
	var n := axis.normalized()
	return (2.0 * dir.dot(n) * n - dir).normalized()

func _flip_lr_behavior(b: EmitterConfig.BehaviorType) -> EmitterConfig.BehaviorType:
	match b:
		EmitterConfig.BehaviorType.TURN_LEFT:  return EmitterConfig.BehaviorType.TURN_RIGHT
		EmitterConfig.BehaviorType.TURN_RIGHT: return EmitterConfig.BehaviorType.TURN_LEFT
	return b

func alter_arms_for_round() -> int:
	if config.alter_arms > 0 and _bround % 2 == 1: return config.alter_arms
	return _usable_arms

# ==============================================================================
# ROTATION HELPERS
# ==============================================================================

func _init_pingpong_angle() -> void:
	if not config.ping_pong or config.rotation_angle == 0: return
	if config.sync_ping_pong_to_burst:
		_rotation_deg = _sync_angle_for_shot(0)
		return
	var half := float(abs(config.rotation_angle)) / 2.0
	if config.center_start: _rotation_deg = -half if not config.ping_pong_invert else half
	else: _rotation_deg = 0.0 if not config.ping_pong_invert else float(config.rotation_angle)

func _sync_angle_for_shot(shot_i: int) -> float:
	var total := float(abs(config.rotation_angle))
	var lo := -total / 2.0 if config.center_start else 0.0
	var hi :=  total / 2.0 if config.center_start else total
	var t := 0.0 if _eff_burst <= 1 else float(shot_i) / float(_eff_burst - 1)
	return lerp(lo, hi, t) if _ping_pong_dir >= 0 else lerp(hi, lo, t)

func _reset_rotation_direction() -> void:
	if config.rotation_angle == 0: _rotation_dir = 1
	else: _rotation_dir = 1 if config.rotation_angle >= 0 else -1

func _handle_rotation_bounds() -> void:
	if config.rotation_angle == 0: return
	var total := float(abs(config.rotation_angle))
	var hi :=  total / 2.0 if config.center_start else total
	var lo := -total / 2.0 if config.center_start else 0.0
	if config.rotation_angle < 0: var tmp := lo; lo = hi; hi = tmp
	if config.ping_pong:
		if _rotation_deg >= hi:   _rotation_dir = -1
		elif _rotation_deg <= lo: _rotation_dir =  1
	else:
		if abs(config.rotation_angle) < 360:
			if _rotation_deg >= hi: _rotation_dir = 0
			if _rotation_deg <= lo: _rotation_dir = 0
