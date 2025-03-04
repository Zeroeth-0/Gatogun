extends Node

# Parámetros generales
var GeneralGameScore: int = 0
var combo: int = 0
var fever: int = 0
var isFever: bool = false
var rank: int = 1
var comboTimer: float = 1.0
var feverTimer: float = 3.0
@export_range(0, 6, 1) var Rank: float = 1.0

var comboDrainTime: float = 0.0  # Acumulador para reducción de combo
var feverDrainTime: float = 0.0

func _process(delta):
	fever_counter(delta)
	combo_counter(delta)
	
	if fever >= 200:
		fever = 100
		if rank < 6: rank += 1
	
	if fever >= 100: isFever = true
	if fever <= 0:
		isFever = false
		rank = 1

func fever_counter(delta):
	feverTimer -= delta
	if feverTimer <= 0 and !isFever: fever = 0
	
	if fever > 0 and isFever:
		feverDrainTime += delta
		var drainRate = 0.05
		while feverDrainTime >= drainRate:
			fever -= 1
			feverDrainTime -= drainRate
	elif fever <= 0: fever = 0

func combo_counter(delta):
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

func increase_fever(val):
	fever += val
	feverTimer = 3.0

func add_score(score):
	if isFever: score *= 2**rank
	GeneralGameScore += score
