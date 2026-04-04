# source/bullets/bullet.gd
# Base class for all bullets.
# Handles movement, bounds and BPOOL protocol.
class_name BaseBullet
extends Area2D

# ==============================================================================
# PUBLIC STATE - Configured by emitter
# ==============================================================================

var speed: float = 400.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 1

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var isCancelled: bool = false
var _elapsed: float = 0.0
var _has_been_visible: bool = false

## Velocity applied this frame. Modified by subclasses
var velocity: Vector2 = Vector2.ZERO

# ==============================================================================
# BPOOL PROTOCOL
# ==============================================================================

func on_acquired() -> void:
	_elapsed = 0.0
	_has_been_visible = false
	isCancelled = false
	scale = Vector2.ONE
	if !(self in CAMERA.tracked_nodes): CAMERA.tracked_nodes.append(self)
	_on_acquired()

func on_released() -> void:
	CAMERA.tracked_nodes.erase(self)
	_on_released()

# ==============================================================================
# MAIN LOOP
# ==============================================================================

func _ready() -> void:
	_on_acquired()
	velocity = direction * speed

func _process(delta: float) -> void:
	_elapsed += delta
	
	if isCancelled: 
		_do_release()
		return
	
	# Bounds check
	var vp_rect := get_viewport_rect()
	if vp_rect.has_point(global_position): _has_been_visible = true
	elif _has_been_visible:
		_do_release()
		return
	
	_update(delta)
	position += _get_velocity(delta) * delta

# ==============================================================================
# INTERNAL Release - Call instead of queue_free()
# ==============================================================================

func _do_release() -> void:
	BPOOL.release(self)

# ==============================================================================
# HOOKS - Override in subclasses
# ==============================================================================

## Subclass-specific reset
func _on_acquired() -> void: pass

## Subclass-specific cleanup
func _on_released() -> void: pass

## Called every frame before position update
func _update(_delta: float) -> void: pass

## Returns final velocity for this frame
func _get_velocity(_delta: float) -> Vector2:
	return velocity

func _enter_tree():
	if !(self in CAMERA.tracked_nodes): CAMERA.tracked_nodes.append(self)

func _exit_tree():
	if self in CAMERA.tracked_nodes: CAMERA.tracked_nodes.erase(self)
