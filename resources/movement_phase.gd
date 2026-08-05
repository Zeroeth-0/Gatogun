# resources/movement_phase.gd
# Single phase of enemy movement
class_name MovementPhase
extends Resource

enum MoveType {
	STRAIGHT, SINUSOIDAL, OSCILLATE, BREATH,
	BLOCK, CENTER, CURVE, CIRCULAR,
	TOWARDS_PLAYER, LEAVE, LEAVE_SIDE, DIAGONAL, STILL
}

## Movement pattern for this phase
@export var move_type: MoveType = MoveType.STRAIGHT

## Duration. Set to -1 for last phase
@export_range(-1.0, 20.0, 0.1) var duration: float = 1.0

## Movement speed
@export var speed: int = 100

## Flip hside when transitioning to the next phase
@export var invert_next: bool = false

## Degrees used by CURVE (total arc) and CIRCULAR (degrees/second)
@export_range(0, 360, 15) var deviation_angle: int = 90

## Amplitude multiplier for SINUSOIDAL, OSCILLATE, BREATH
@export_range(1, 5, 1) var intensity: int = 1
