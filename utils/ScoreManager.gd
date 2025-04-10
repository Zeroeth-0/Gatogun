extends Node

# Parámetros generales
var GeneralGameScore: int = 0
var combo: int = 0
var fever: int = 0
var rank: int = 1
var comboTimer: float = 1.0
var feverTimer: float = 1.0
var feverSize: float = 1000
var canBomb: bool = false
var bombCount: int = 0

var comboDrainTime: float = 0.0  # Acumulador para reducción de combo
var feverDrainTime: float = 0.0
var comboLimit = 0.001
var rankCounter = 0
var rankLimit = 3000

var comboLabel: RichTextLabel = null
var rankLabel: RichTextLabel = null

func _process(delta):
	fever_counter(delta)
	combo_counter(delta)
	comboLabel = get_tree().get_first_node_in_group("Combo")
	rankLabel = get_tree().get_first_node_in_group("Rank")
	
	if bombCount >= 3: bombCount = 3
	if fever >= 5000: fever = 5000
	
	
	var threshold = feverSize * (1 - pow(0.5, bombCount + 1))
	canBomb = fever >= threshold

func fever_counter(delta):
	feverTimer -= delta
	if fever <= 0: fever = 0
	
	if feverTimer <= 0:
		feverTimer = 0
		if fever: fever -= 2

func combo_counter(delta):
	comboTimer -= delta
	var baseComboLimit = 0.001
	var minComboLimit = 0.0001
	if combo <= 0: combo = 0
	
	if comboTimer <= 0 and combo > 0:
		comboLabel.label_out()
		comboDrainTime += delta  # Acumula tiempo transcurrido
		
		# Reducimos comboLimit con el tiempo o el número de combos
		comboLimit = max(baseComboLimit * pow(0.95, combo), minComboLimit)

		while comboDrainTime >= comboLimit:
			combo -= 1
			comboDrainTime -= comboLimit

func increase_combo(val):
	if combo <= 0: comboLabel.label_in()
	
	combo += val;
	comboTimer = 1.0
	comboLimit = 0.001

func increase_fever(val):
	if fever < feverSize: fever += val
	else: fever = feverSize
	feverTimer = 1.0

func keep_fever():
	feverTimer = 1

func reset():
	fever = 0
	combo = 0
	rank = 1
	bombCount = 0

func add_score(score):
	GeneralGameScore += score
