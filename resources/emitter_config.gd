# resources/emitter_config.gd
# Data resource describing a complete bullet pattern.
# Pattern can be saved as .tres files and reused.
class_name EmitterConfig
extends Resource

# ==============================================================================
# BULLET
# ==============================================================================

@export_category("Bullet")
## Scene to instantiate
@export var bullet_scene: PackedScene
## Base speed
@export_range(-800.0, 800.0, 10.0) var base_speed: float = 400.0
## SPeed randomization
@export_range(0.0, 0.9, 0.01) var random_speed: float = 0.0

# ==============================================================================
# TIMING
# ==============================================================================

@export_category("Timing")
## Seconds before the first shot
@export_range(0.0, 10.0, 0.05) var delay: float = 0.0
## Shots per burst
@export_range(1, 100, 1) var burst_count: int = 1
## Seconds between shots within a burst
@export_range(0.0, 2.0, 0.01) var bullet_interval: float = 0.1
## Seconds betweet bursts
@export_range(0.0, 10.0, 0.05) var warm_up: float = 1.0
## Total bursts before self-destruction.
# -1 = infinite
@export_range(-1, 200, 1) var max_rounds: int = -1

# ==============================================================================
# SHAPE
# ==============================================================================

@export_category("Shape")
## Number of directions fired per shot
@export_range(1, 64, 1) var arms: int = 1
## Alternate arm count on odd-numbered shots.
# 0 = disabled
@export_range(0, 64, 1) var alter_arms: int = 0
## Add one arm per burst
@export var grow_with_round: bool = false
## Total arc of the fan in degrees
@export_range(0.0, 360.0, 1.0) var spread_angle: float = 0.0
## Bullets per arm, stacked perpendicularly
@export_range(1, 10, 1) var arm_width: int = 1
## Separation between bullets in the same arm
@export_range(0.0, 1.0, 0.05) var arm_spacing_factor: float = 0.5
## Spawn offset from emitter
@export_range(0, 600, 1) var distance_center: int = 0
## Probability to skip an arm
@export_range(0.0, 1.0, 0.01) var skip_chance: float = 0.0
## Max random jitter per arm
@export_range(0, 180, 1) var random_angle: int = 0
## Max random spawn offset per bullet
@export_range(0, 400, 1) var random_offset: int = 0
## Max random delay per bullet
@export_range(0.0, 1.0, 0.01) var stagger_delay: float = 0.0
## Delay between consecutive arms
@export_range(0.0, 0.5, 0.005) var intra_arm_delay: float = 0.0

@export_group("Parallel Mode")
## Arms are arranged side by side
@export var parallel: bool = false
## Spacing between parallel arms
@export_range(0, 1000, 1) var spread_offset: int = 100
## Forward/backward offset creating a wedge shape (parallel only)
@export_range(-200, 200, 1) var steepness: int = 0
## Curve of the wedge
@export_range(0.1, 6.0, 0.1) var steepness_sharpness: float = 1.0

@export_group("Symmetry")
## Mirror the entire pattern across the firing axis
@export var use_symmetry: bool = false
## Gap in degrees between original and mirrored patterns
@export_range(0.0, 180.0, 1.0) var symmetry_gap: float = 0.0

@export_group("Speed Wave")
## Number of speed peaks distributed across the arms
@export_range(0, 16, 1) var peak_count: int = 0
## Extra speed added at each peak
@export_range(0.0, 1000.0, 10.0) var peak_speed_bonus: float = 100.0

@export_group("Repeater")
## Repeat the entire pattern distributed angularly
@export_range(1, 16, 1) var repeat_count: int = 1
## Total angle distributed across repeats
@export_range(0, 360, 1) var repeat_angle: int = 360

# ==============================================================================
# DIRECTION
# ==============================================================================

@export_category("Direction")
enum FiringDirection { NORTH, SOUTH, EAST, WEST, NWEST, NEAST, SWEST, SEAST }
## Base firing direction
@export var direction_enum: FiringDirection = FiringDirection.SOUTH
## Angular offset from the base direction
@export_range(-180.0, 180.0, 1.0) var dir_deviation: float = 0.0
## Aim directly at the player
@export var aim_at_player: bool = false

# ==============================================================================
# BULLET BEHAVIOR
# ==============================================================================

@export_category("Bullet Behavior")
enum BehaviorType {
	NONE,         ## Straight line
	AIM,          ## Turns toward player
	GRAVITY,      ## Falls under gravity
	TURN_LEFT,    ## Continuously rotates left
	TURN_RIGHT,   ## Continuously rotates right
	RANDOM_TURN,  ## Random rotation
	HOMING,       ## Follows player continuously
	SINE_WAVE,    ## Oscillates perpendicular to movement
	BOUNCE,       ## Bounces off viewport edges
}
## Behavior applied to bullets fired by this emitter
@export var behavior_type: BehaviorType = BehaviorType.NONE
## Seconds after spawn before the behavior activates
@export_range(0.0, 5.0, 0.1) var behavior_start_time: float = 0.0
## Seconds the behavior stays active.
# -1 = permanent
@export_range(-1.0, 10.0, 0.1) var behavior_duration: float = 5.0
## Intensity multiplier for the behavior
@export_range(0.0, 1.0, 0.01) var behavior_intensity: float = 0.5
## Angular parameter for turning behaviors
@export_range(0, 360, 1) var behavior_deviation: int = 45

@export_group("Speed Modification")
## Enable two-step speed change
@export var modify_speed: bool = false
## Speed during the first phase
@export_range(-800, 800, 10) var speed_phase_1: int = 0
## Time after spawn when phase 1 starts
@export_range(0.0, 5.0, 0.05) var speed_phase_1_time: float = 0.0
## Speed during the second phase
@export_range(-800, 800, 10) var speed_phase_2: int = 0
## Time after spawn when phase 2 starts
@export_range(0.0, 5.0, 0.05) var speed_phase_2_time: float = 1.0
## Curve-based speed override
@export var speed_curve: Curve = null
## Duration of the speed curve
@export_range(0.1, 10.0, 0.1) var speed_curve_duration: float = 3.0

# ==============================================================================
# ROTATION
# ==============================================================================

@export_category("Rotation")
## Emitter rotation speed
@export_range(0.0, 360.0, 1.0) var rotation_speed: float = 0.0
## Max rotation angle
@export_range(-360, 360, 1) var rotation_angle: int = 0
## Continue rotating during a burst
@export var burst_rotation: bool = false
## Bounce back and forth
@export var ping_pong: bool = false
## Sync the ping-pong sweep mathematically to the burst
@export var sync_ping_pong_to_burst: bool = true
## Center the sweep at the firing direction
@export var center_start: bool = true
## Invert the initial sweep direction
@export var ping_pong_invert: bool = false

# ==============================================================================
# SPEED VARIATION PER BURST
# ==============================================================================

@export_category("Burst Speed")
enum SpeedVarTarget { BULLET, ARM }
## Apply  per bullet or per arm
@export var speed_var_target: SpeedVarTarget = SpeedVarTarget.BULLET
## Cumulative speed multiplier.
# 1 = no change
@export_range(0.5, 2.0, 0.01) var speed_variation: float = 1.0
## Preserve speed accumulation across bursts
@export var keep_speed: bool = false

# ==============================================================================
# SUB EMITTER
# ==============================================================================

@export_category("Sub Emitter")
## Scene containing a pre-configured BulletEmitter
@export var sub_emitter_scene: PackedScene = null
enum SubEmitterTrigger {
	ON_DEATH,     ## Spawns at bullet death position
	AFTER_DELAY,  ## Spawns after sub_delay seconds, follows bullet
	IMMEDIATELY,  ## Spawns on bullet creation, stays attached
}
@export var sub_trigger: SubEmitterTrigger = SubEmitterTrigger.ON_DEATH
## Delay for trigger
@export_range(0.0, 10.0, 0.1) var sub_delay: float = 0.5

# ==============================================================================
# STATIC DIRECTION MAP
# ==============================================================================

static func direction_to_vec(d: FiringDirection) -> Vector2:
	match d:
		FiringDirection.NORTH:  return Vector2.UP
		FiringDirection.EAST:   return Vector2.RIGHT
		FiringDirection.WEST:   return Vector2.LEFT
		FiringDirection.NWEST:  return Vector2(-1.0, -1.0).normalized()
		FiringDirection.NEAST:  return Vector2( 1.0, -1.0).normalized()
		FiringDirection.SWEST:  return Vector2(-1.0,  1.0).normalized()
		FiringDirection.SEAST:  return Vector2( 1.0,  1.0).normalized()
	return Vector2.DOWN  # SOUTH
