extends Node

# === ESTADO DE PUNTUACIÓN ===
var GeneralGameScore: int = 0
var combo: int = 0
var fever: float = 0
var medalCountdown: float = 0
var mult: int = 1

# === TIMERS ===
var comboTimer: float = 0.1
var comboDrainTime: float = 0.0
var multDrainTime: float = 0.0
var feverTimer: float = 0.0

# === CONFIGURACIÓN DE SISTEMA ===
var feverDrainRate: float = 50.0
var feverSize: float = 100
var comboLimit: float = 0.001
var multDrainLimit: float = 0.03
var rank = 1

# === REFERENCIAS UI ===
var comboLabel: RichTextLabel = null
var comboAvailable: bool = true

# === LOOP PRINCIPAL ===
func _process(delta: float) -> void:
	_update_labels()
	_update_fever(delta)
	_update_combo(delta)
	_update_mult(delta)
	_check_caps()
	
	if medalCountdown >= 0:
		medalCountdown -= delta
	else:
		medalCountdown = 0

# === ACTUALIZACIÓN DE LABELS ===
func _update_labels() -> void:
	comboLabel = get_tree().get_first_node_in_group("Combo")

# === SISTEMA DE FIEBRE ===
func _update_fever(delta: float) -> void:
	if fever > 0:
		if feverTimer > 0:
			feverTimer -= delta
		else:
			fever -= feverDrainRate * delta
			if fever <= 0:
				fever = 0

# === SISTEMA DE MULT ===
func _update_mult(delta: float) -> void:
	if fever <= 0 and mult > 1:
		multDrainTime += delta
		while multDrainTime >= multDrainLimit:
			if (mult - 3 >= 1): mult -= 3
			else: mult -= 1
			multDrainTime -= multDrainLimit

# === SISTEMA DE COMBO ===
func _update_combo(delta: float) -> void:
	if fever <= 0 and comboTimer >= 0:
		comboTimer -= delta
	
	if combo <= 0:
		combo = 0
		return
	
	if comboTimer <= 0:
		if comboLabel: comboLabel.label_out()
		comboAvailable = true
		comboDrainTime += delta
		
		var baseLimit = 0.01
		var minLimit = 0.001
		comboLimit = max(baseLimit * pow(0.95, combo), minLimit)
		
		while comboDrainTime >= comboLimit:
			combo -= 1
			comboDrainTime -= comboLimit

# === RESTRICCIONES DE VALORES MÁXIMOS ===
func _check_caps() -> void:
	fever = clamp(fever, 0, feverSize)

# === FUNCIONES PÚBLICAS ===

func increase_combo(value: int) -> void:
	if comboAvailable:
		if comboLabel: comboLabel.label_in()
		comboAvailable = false
	combo += value
	comboTimer = 0.1
	comboLimit = 0.001

func increase_fever(value: int) -> void:
	fever = min(fever + value, feverSize)
	feverTimer = 0.1  # Delay antes de que empiece a bajar

func keep_fever() -> void:
	feverTimer = 0.1

func increase_mult() -> void:
	mult += 1

func reset() -> void:
	if rank > 1: rank -= 1
	fever = 0
	combo = 0
	mult = 1
	multDrainTime = 0.0
	if comboLabel: comboLabel.label_out()

func add_score(score: int) -> void:
	GeneralGameScore += score * mult

func reset_game_score() -> void:
	GeneralGameScore = 0
	rank = 1
