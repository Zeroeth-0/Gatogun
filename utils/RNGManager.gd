# RNGManager.gd
# Autoload / Singleton
extends Node

var rng := RandomNumberGenerator.new()

var initial_seed: int = 0
var is_replay_mode: bool = false

# Llamar al iniciar partida o al cargar replay
func reset_rng(seed_value: int, replay: bool = false) -> void:
	initial_seed = seed_value
	rng.seed = seed_value
	is_replay_mode = replay

# === FUNCIONES PÚBLICAS ===
func drandi() -> int:
	return rng.randi()

func drandi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)

func drandf() -> float:
	return rng.randf()

func drandf_range(from: float, to: float) -> float:
	return rng.randf_range(from, to)

func drandfn(mean: float = 0.0, deviation: float = 1.0) -> float:
	return rng.randfn(mean, deviation)
