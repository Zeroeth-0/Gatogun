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
var feverDrainRate: float = 33.3
var feverSize: float = 100
var comboLimit: float = 0.001
var multDrainLimit: float = 0.03
var rankCounter: int = 0
var rankLimit: int = 3000
var canBomb: bool = false
var bombCount: int = 0

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
	_check_bomb_ready()
	
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
			mult -= 1
			multDrainTime -= multDrainLimit

# === SISTEMA DE COMBO ===
func _update_combo(delta: float) -> void:
	if fever <= 0 and comboTimer >= 0:
		comboTimer -= delta
	
	if combo <= 0:
		combo = 0
		return
	
	if comboTimer <= 0:
		comboLabel.label_out()
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
	bombCount = clamp(bombCount, 0, 3)
	fever = clamp(fever, 0, feverSize)

# === CONDICIÓN PARA HABILITAR BOMBA ===
func _check_bomb_ready() -> void:
	var threshold = feverSize * (1 - pow(0.5, bombCount + 1))
	canBomb = fever >= threshold

# === FUNCIONES PÚBLICAS ===

func increase_combo(value: int) -> void:
	if comboAvailable:
		comboLabel.label_in()
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
	fever = 0
	combo = 0
	bombCount = 0
	mult = 1
	multDrainTime = 0.0

func add_score(score: int) -> void:
	GeneralGameScore += score * mult
