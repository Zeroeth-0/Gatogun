extends Node

# Parámetros generales
var GeneralGameScore: int = 0
var combo: int = 0
var comboTimer: float = 1.0
@export_range(0, 6, 1) var Rank: float = 1.0

var comboDrainTime: float = 0.0  # Acumulador para reducción de combo

func _process(delta):
	comboTimer -= delta
	if combo <= 0: combo = 0
	
	if comboTimer <= 0 and combo > 0:
		comboDrainTime += delta  # Acumula tiempo transcurrido
	
		while comboDrainTime >= 0.001:
			combo -= 1
			comboDrainTime -= 0.001  # Resta el tiempo usado para mantener precisión


func increase_combo(val):
	combo += val;
	comboTimer = 1.0

func add_score():
	GeneralGameScore += combo
