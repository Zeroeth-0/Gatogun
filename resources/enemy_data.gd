# resources/enemy_data.gd
# Data resource describing one enemy type
class_name EnemyData
extends Resource

enum EnemyType { STD, MID, ELITE }

# ==============================================================================
# IDENTITY
# ==============================================================================

@export_category("Identity")
@export var enemy_id: StringName = &"unknown"
@export var enemy_type: EnemyType = EnemyType.STD
@export var base_health: float = 16.0
@export var score_count: int = 1
@export var explosion_scale: float = 1.5

# ==============================================================================
# BEHAVIOR
# ==============================================================================

@export_category("Behavior")

## Y position below which the enemy stops shooting
@export var cutoff_y: float = 450.0

## If true, player contact blocks shooting instead of damaging the player
@export var is_ground: bool = false

## After this many emitter rounds, health halves once. STD = 1, ELITE = 2 in original design
@export var halving_trigger_round: int = 1

# ==============================================================================
# DROPS
# ==============================================================================

@export_category("Drops")

## Drops a powerup on death
@export var drops_powerup: bool = false

## Can spawn revenge bullets on death
@export var drops_revenge: bool = true

# ==============================================================================
# MOVEMENT
# ==============================================================================

@export_category("Movement")

## Phases executed in order. Last phase runs forever
@export var movement_phases: Array[MovementPhase] = []
