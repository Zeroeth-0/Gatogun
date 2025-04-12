extends Node

# === ESTADO DE PUNTUACIÓN ===
var GeneralGameScore: int = 0
var combo: int = 0
var fever: int = 0
var rank: int = 1

# === TIMERS ===
var comboTimer: float = 1.0
var feverTimer: float = 1.0
var comboDrainTime: float = 0.0
var feverDrainTime: float = 0.0

# === CONFIGURACIÓN DE SISTEMA ===
var feverSize: float = 1000
var comboLimit: float = 0.001
var rankCounter: int = 0
var rankLimit: int = 3000
var canBomb: bool = false
var bombCount: int = 0

# === REFERENCIAS UI ===
var comboLabel: RichTextLabel = null
var rankLabel: RichTextLabel = null

# === LOOP PRINCIPAL ===
func _process(delta: float) -> void:
	_update_labels()
	_update_fever(delta)
	_update_combo(delta)
	_check_caps()
	_check_bomb_ready()

# === ACTUALIZACIÓN DE LABELS ===
func _update_labels() -> void:
	comboLabel = get_tree().get_first_node_in_group("Combo")
	rankLabel = get_tree().get_first_node_in_group("Rank")

# === SISTEMA DE FIEBRE ===
func _update_fever(delta: float) -> void:
	feverTimer -= delta
	if fever <= 0:
		fever = 0
		return
	
	if feverTimer <= 0:
		feverTimer = 0
		fever = max(0, fever - 2)

# === SISTEMA DE COMBO ===
func _update_combo(delta: float) -> void:
	comboTimer -= delta
	if combo <= 0:
		combo = 0
		return
	
	if comboTimer <= 0:
		comboLabel.label_out()
		comboDrainTime += delta
		
		var baseLimit = 0.001
		var minLimit = 0.0001
		comboLimit = max(baseLimit * pow(0.95, combo), minLimit)
		
		while comboDrainTime >= comboLimit:
			combo -= 1
			comboDrainTime -= comboLimit

# === RESTRICCIONES DE VALORES MÁXIMOS ===
func _check_caps() -> void:
	bombCount = clamp(bombCount, 0, 3)
	fever = clamp(fever, 0, feverSize)

# === CONDICIÓN PARA HABILITAR BOMBA ===
func _check_bomb_ready() -> void:
	var threshold = feverSize * (1 - pow(0.5, bombCount + 1))
	canBomb = fever >= threshold

# === FUNCIONES PÚBLICAS ===

func increase_combo(value: int) -> void:
	if combo <= 0: comboLabel.label_in()
	
	combo += value
	comboTimer = 1.0
	comboLimit = 0.001

func increase_fever(value: int) -> void:
	fever = min(fever + value, feverSize)
	feverTimer = 1.0

func keep_fever() -> void:
	feverTimer = 1.0

func reset() -> void:
	fever = 0
	combo = 0
	rank = 1
	bombCount = 0

func add_score(score: int) -> void:
	GeneralGameScore += score
