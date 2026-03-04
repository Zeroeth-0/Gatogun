extends Node
# === CONST NUMS ===
const ZERO: int = 0
const ZERO_POINT: float = 0.0
const ONE: int = 1
const ONE_POINT: float = 1.0
const POINT_ONE: float = 0.1
const POINT_FIVE: float = 0.5
# === CONST VALS ===
const HOT_DRAIN_RATE: float = 50.0
const HOT_SIZE: float = 100.0
const COMBO_LIMIT: float = 0.001
const MULT_DRAIN_LIMIT: float = 0.01
const MAX_MEDAL_COUNTDOWN: float = 2.0
# === ESTADO DE PUNTUACIÓN ===
var GeneralGameScore: int = ZERO
var combo: int = ZERO
var hot: float = ZERO
var medalCountdown: float = ZERO
var mult: int = ONE
# === TIMERS ===
var comboResetTimer: float = POINT_ONE
var comboDrainTime: float = ZERO_POINT
var multDrainTime: float = ZERO_POINT
var hotDrainDelay: float = POINT_FIVE
# === CONFIGURACIÓN DE SISTEMA ===
var hotDrainRate: float = HOT_DRAIN_RATE
var hotSize: float = HOT_SIZE
var comboLimit: float = COMBO_LIMIT
var multDrainLimit: float = MULT_DRAIN_LIMIT
# === REFERENCIAS UI ===
var HUD: Control = null
var comboAvailable: bool = true

# === LOOP PRINCIPAL ===
func _process(delta: float) -> void:
	_update_hot(delta)
	_update_combo(delta)
	_update_mult(delta)
	
	if medalCountdown >= 0:
		medalCountdown -= delta
	else:
		medalCountdown = 0

# === SISTEMA DE INTENSIDAD ===
func _update_hot(delta: float) -> void:
	if hot > 0:
		if hotDrainDelay > 0: hotDrainDelay -= delta
		else:
			hot -= hotDrainRate * delta
			if hot <= 0:
				hot = 0

func increase_hot(value: int) -> void:
	hot = clampf(hot + value, 0.0, hotSize)
	hotDrainDelay = 1.0
	var hud = _get_hud()
	if hud: hud.pulse_hot_bar()

func keep_hot() -> void:
	hotDrainDelay = 0.1
	var hud = _get_hud()
	if hud: hud.keep_hot_bar()

# === SISTEMA DE MULT ===
func _update_mult(delta: float) -> void:
	var needWait: bool = true
	if hot <= 0 and mult > 1:
		if needWait:
			await get_tree().create_timer(0.5).timeout
			needWait = false
		multDrainTime += delta
		while multDrainTime >= multDrainLimit:
			if (mult - 3 >= 1): mult -= 3
			else: mult -= 1
			multDrainTime -= multDrainLimit
	else: needWait = true
	
	if mult <= 1: mult = 1

# === SISTEMA DE COMBO ===
func _update_combo(delta: float) -> void:
	if hot <= 0 and comboResetTimer >= 0: comboResetTimer -= delta
	
	if combo <= 0:
		combo = 0
		return
	
	if comboResetTimer <= 0:
		var hud = _get_hud()
		if hud: hud.label_out()
		comboAvailable = true
		comboDrainTime += delta
		
		var baseLimit = 0.01
		var minLimit = 0.001
		comboLimit = max(baseLimit * pow(0.95, combo), minLimit)
		
		while comboDrainTime >= comboLimit:
			combo -= 3
			comboDrainTime -= comboLimit

# === FUNCIONES PÚBLICAS ===
func increase_combo(value: int) -> void:
	if comboAvailable:
		var hud = _get_hud()
		if hud: hud.label_in()
		comboAvailable = false
	combo += value * 3
	comboResetTimer = 0.1
	comboLimit = 0.001

func increase_mult() -> void:
	mult += 1

func reset() -> void:
	hot = 0
	combo = 0
	mult = 1
	multDrainTime = 0.0
	medalCountdown = 0.0
	comboAvailable = true  # <- añadir esto
	var hud = _get_hud()
	if hud: hud.label_out()

func add_score(score: int) -> void:
	GeneralGameScore += score * mult

func reset_game_score() -> void:
	GeneralGameScore = 0

func _get_hud() -> Control:
	if HUD and HUD.get_parent(): return HUD
	HUD = get_tree().get_first_node_in_group("HUD")
	return HUD
