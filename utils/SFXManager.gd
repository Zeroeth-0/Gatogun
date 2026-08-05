# utils/SFXManager.gd
# Name: SFX
extends Node

# ==============================================================================
# CONSTANTS
# ==============================================================================

const POOL_SIZE: int = 32

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var _pool: Array[AudioStreamPlayer] = []
var _index: int = 0

## Master volume offset applied on top of every call
var master_db: float = 0.0

var _sounds: Dictionary = {
	&"burst": preload("res://sfx/burst.wav"),
	&"medal": preload("res://sfx/medal.wav")
}

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_pool.append(player)

# ==============================================================================
# PUBLIC API
# ==============================================================================

## Plays a registered sound
func play(sound: StringName,
		  db: float = -24.0,
		  pitch_var: float = 0.0,
		  pitch_offset: float = 0.0) -> void:
	if !_sounds.has(sound):
		push_warning("SFX.play(): sound is not registered")
		return
	
	var player := _pool[_index]
	_index = (_index + 1) % POOL_SIZE
	
	player.stream = _sounds[sound]
	player.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var) + pitch_offset
	player.volume_db = db + master_db
	player.play()

## Registers a new sound at runtime
func register(sound: StringName, stream: AudioStream) -> void:
	if stream == null:
		push_error("SFX.register(): null stream")
		return
	_sounds[sound] = stream

## True if the sound id is registered
func has_sound(sound: StringName) -> bool:
	return _sounds.has(sound)
