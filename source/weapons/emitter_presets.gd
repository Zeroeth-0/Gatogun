# source/weapons/emitter_presets.gd
# Static library of pre-configured EmitterConfig patterns
class_name EmitterPresets
extends Object

const PRED_BULLET := preload (("res://scenes/bullets/bullet.tscn"))

# ==============================================================================
# STREAM PATTERNS
# ==============================================================================

## Single aimed stream. Tracks player at burst start
static func aimed_stream(speed: float = 350.0, warm_up: float = 0.8) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms          = 1
	c.spread_angle  = 0.0
	c.aim_at_player = true
	c.base_speed    = speed
	c.warm_up       = warm_up
	return c

## Multiple parallel streams, all aimed at player
static func aimed_spread(
		arms: int,
		spread: float,
		speed: float = 350.0,
		warm_up: float = 1.2) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms          = arms
	c.spread_angle  = spread
	c.aim_at_player = true
	c.base_speed    = speed
	c.warm_up       = warm_up
	return c

## Speed-layered stream: same direction, N bullets at different speeds
static func speed_layers(
		layers: int,
		speed_min: float,
		speed_max: float,
		aim: bool = true,
		warm_up: float = 1.0) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms           = layers
	c.spread_angle   = 0.0
	c.aim_at_player  = aim
	c.base_speed     = (speed_min + speed_max) * 0.5
	c.random_speed   = (speed_max - speed_min) / (speed_min + speed_max)
	c.warm_up        = warm_up
	return c

# ==============================================================================
# RING PATTERNS
# ==============================================================================

## Full ring
static func ring(
		arms: int,
		speed: float = 300.0,
		rotation_speed: float = 0.0,
		warm_up: float = 1.0) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms           = arms
	c.spread_angle   = 360.0
	c.base_speed     = speed
	c.rotation_speed = rotation_speed
	c.warm_up        = warm_up
	return c

## Alternating ring: odd rounds fire N arms, even rounds fire M arms
static func alternating_ring(
		arms_a: int,
		arms_b: int,
		speed: float = 300.0,
		warm_up: float = 1.0) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms         = arms_a
	c.alter_arms   = arms_b
	c.spread_angle = 360.0
	c.base_speed   = speed
	c.warm_up      = warm_up
	return c

## Layered ring: multiple rings per shot at different speeds
static func layered_ring(
		arms: int,
		speed_inner: float,
		speed_outer: float,
		layers: int = 3,
		layer_interval: float = 0.08,
		warm_up: float = 1.5) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms            = arms
	c.spread_angle    = 360.0
	c.base_speed      = speed_inner
	c.burst_count     = layers
	c.bullet_interval = layer_interval
	c.warm_up         = warm_up
	# Speed increases per burst shot to create the layered effect
	c.speed_var_target = EmitterConfig.SpeedVarTarget.BULLET
	c.speed_variation  = pow(speed_outer / speed_inner, 1.0 / float(layers))
	return c

## Spinning ring: rotates continuously
static func spinning_ring(
		arms: int,
		speed: float = 280.0,
		deg_per_second: float = 45.0,
		warm_up: float = 0.8) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms           = arms
	c.spread_angle   = 360.0
	c.base_speed     = speed
	c.rotation_speed = deg_per_second
	c.burst_rotation = true
	c.burst_count    = 5
	c.bullet_interval = 0.05
	c.warm_up        = warm_up
	return c

# ==============================================================================
# SPIRAL PATTERNS
# ==============================================================================

## Classic spiral: single arm rotating continuously
static func spiral(
		speed: float = 300.0,
		deg_per_second: float = 60.0,
		warm_up: float = 0.15) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms           = 1
	c.spread_angle   = 0.0
	c.base_speed     = speed
	c.rotation_speed = deg_per_second
	c.burst_rotation = true
	c.burst_count    = 8
	c.bullet_interval = 0.05
	c.warm_up        = warm_up
	return c

## Dual counter-rotating spirals.
static func double_spiral(
		speed: float = 300.0,
		deg_per_second: float = 60.0,
		warm_up: float = 0.15) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms           = 2
	c.spread_angle   = 180.0
	c.base_speed     = speed
	c.rotation_speed = deg_per_second
	c.burst_rotation = true
	c.burst_count    = 8
	c.bullet_interval = 0.05
	c.warm_up        = warm_up
	return c

## N-armed spiral. More arms = denser pattern
static func n_spiral(
		arms: int,
		speed: float = 300.0,
		deg_per_second: float = 45.0,
		warm_up: float = 0.12) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms           = arms
	c.spread_angle   = 360.0 / float(arms) * float(arms - 1)
	c.base_speed     = speed
	c.rotation_speed = deg_per_second
	c.burst_rotation = true
	c.burst_count    = 8
	c.bullet_interval = 0.05
	c.warm_up        = warm_up
	return c

# ==============================================================================
# SWEEP PATTERNS
# ==============================================================================

## Sweep: fires across an arc, bouncing back and forth
static func sweep(
		arms: int,
		arc_degrees: float,
		speed: float = 320.0,
		burst: int = 12,
		warm_up: float = 0.5) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms           = arms
	c.spread_angle   = 0.0
	c.aim_at_player  = true
	c.base_speed     = speed
	c.rotation_angle = int(arc_degrees)
	c.ping_pong      = true
	c.sync_ping_pong_to_burst = true
	c.burst_count    = burst
	c.bullet_interval = 0.05
	c.warm_up        = warm_up
	return c

## Symmetric sweep: two arms sweeping in opposite directions
static func symmetric_sweep(
		arc_degrees: float,
		speed: float = 300.0,
		burst: int = 10,
		warm_up: float = 0.6) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms           = 1
	c.spread_angle   = 0.0
	c.use_symmetry   = true
	c.symmetry_gap   = 30.0
	c.aim_at_player  = true
	c.base_speed     = speed
	c.rotation_angle = int(arc_degrees)
	c.ping_pong      = true
	c.sync_ping_pong_to_burst = true
	c.burst_count    = burst
	c.bullet_interval = 0.05
	c.warm_up        = warm_up
	return c

# ==============================================================================
# HOMING PATTERNS
# ==============================================================================

## Soft-homing burst. Fires N bullets that track the player
static func homing_burst(
		count: int = 5,
		speed: float = 250.0,
		turn_speed_deg: float = 120.0,
		warm_up: float = 1.5) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms             = count
	c.spread_angle     = 360.0
	c.base_speed       = speed
	c.behavior_type    = EmitterConfig.BehaviorType.HOMING
	c.behavior_deviation = int(turn_speed_deg)
	c.warm_up          = warm_up
	return c

## Delayed homing: fires straight, then curves toward player
static func delayed_homing(
		arms: int = 1,
		speed: float = 300.0,
		delay_before_turn: float = 0.5,
		turn_speed_deg: float = 90.0,
		warm_up: float = 1.2) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms                 = arms
	c.spread_angle         = 0.0
	c.aim_at_player        = true
	c.base_speed           = speed
	c.behavior_type        = EmitterConfig.BehaviorType.HOMING
	c.behavior_start_time  = delay_before_turn
	c.behavior_deviation   = int(turn_speed_deg)
	c.warm_up              = warm_up
	return c

# ==============================================================================
# DENSE PATTERNS
# ==============================================================================

## Dense aimed wall: wide spread aimed at player
static func aimed_wall(
		arms: int = 16,
		spread: float = 90.0,
		speed: float = 280.0,
		warm_up: float = 2.0) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms          = arms
	c.spread_angle  = spread
	c.aim_at_player = true
	c.base_speed    = speed
	c.warm_up       = warm_up
	c.random_angle  = 3
	return c

## Curtain fire: dense downward wall covering the full screen width
static func curtain(
		arms: int = 20,
		speed: float = 260.0,
		warm_up: float = 1.8) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms          = arms
	c.spread_angle  = 90.0
	c.direction_enum = EmitterConfig.FiringDirection.SOUTH
	c.base_speed    = speed
	c.warm_up       = warm_up
	c.random_angle  = 2
	return c

## Scatter shot: random directions, creates chaotic feel
static func scatter(
		count: int = 12,
		speed: float = 300.0,
		speed_variance: float = 0.3) -> EmitterConfig:
	var c := EmitterConfig.new()
	c.bullet_scene = PRED_BULLET
	c.arms         = count
	c.spread_angle = 360.0
	c.base_speed   = speed
	c.random_speed = speed_variance
	c.random_angle = 15
	c.max_rounds   = 1
	c.delay        = 0.0
	c.warm_up      = 0.0
	return c

# ==============================================================================
# PATTERN UTILITIES
# ==============================================================================

## Returns a copy of the config with all rank-scaling disabled
static func no_rank(base: EmitterConfig) -> EmitterConfig:
	var c: EmitterConfig = base.duplicate()
	c.bullet_scene = PRED_BULLET
	c.rank_scale_speed    = false
	c.rank_scale_arms     = false
	c.rank_scale_burst    = false
	c.rank_scale_rotation = false
	return c

## Returns a copy with inverted rotation direction
static func inverted(base: EmitterConfig) -> EmitterConfig:
	var c: EmitterConfig = base.duplicate()
	c.bullet_scene = PRED_BULLET
	c.ping_pong_invert = not c.ping_pong_invert
	c.rotation_speed   = -c.rotation_speed
	return c

## Returns a copy aimed downward (common for enemies entering from top)
static func aimed_south(base: EmitterConfig) -> EmitterConfig:
	var c: EmitterConfig = base.duplicate()
	c.bullet_scene = PRED_BULLET
	c.direction_enum = EmitterConfig.FiringDirection.SOUTH
	c.aim_at_player  = false
	return c
