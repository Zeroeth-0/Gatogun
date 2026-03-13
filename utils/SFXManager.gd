# AudioManager.gd — ponlo en Autoload
extends Node

const POOL_SIZE = 16  # Voces simultáneas para SFX cortos

var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

# Registra tus sonidos aquí
var sounds = {
	"burst": preload("res://sfx/burst.wav"),
	"medal": preload("res://sfx/medal.wav")
}

func _ready():
	# Crear el pool de AudioStreamPlayers
	for i in POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_pool.append(player)

func play(sound_name: String, db: float = -24.0, pitch_variation: float = 0.0, plus_pitch: float = 0.0):
	if not sounds.has(sound_name): return
	
	var player = _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	
	player.stream = sounds[sound_name]
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation) + plus_pitch
	player.volume_db = db
	player.play()
