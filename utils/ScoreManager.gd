extends Node

# === CONST NUMS ===
const ZERO: int = 0
const ZERO_POINT: float = 0.0
const ONE: int = 1
const ONE_POINT: float = 1.0
const POINT_ONE: float = 0.1

# === CONST VALS ===
const HOT_DRAIN_RATE: float = 50.0
const HOT_SIZE: float = 100.0
const COMBO_LIMIT: float = 0.001
const MULT_DRAIN_LIMIT: float = 0.03

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
var hotDrainDelay: float = ONE_POINT

# === CONFIGURACIÓN DE SISTEMA ===
var hotDrainRate: float = HOT_DRAIN_RATE
var hotSize: float = HOT_SIZE
var comboLimit: float = COMBO_LIMIT
var multDrainLimit: float = MULT_DRAIN_LIMIT
var rank = ONE

# === REFERENCIAS UI ===
var HUD: Control = null
var comboAvailable: bool = true

# === LOOP PRINCIPAL ===
func _process(delta: float) -> void:
	_update_hot()
	_update_combo(delta)
	_update_mult(delta)
	
	if medalCountdown >= 0:
		medalCountdown -= delta
	else:
		medalCountdown = 0

# === SISTEMA DE INTENSIDAD ===
func _update_hot() -> void:
	var dist = INF
	for e in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(e):
			dist = min(dist, GAME.get_player().distance_to(e.global_position))
	if medalCountdown > 0: hot = 100.0
	else: hot = clamp(remap(dist, 200.0, 500.0, 100.0, 0.0), 0.0, 100.0)

# === SISTEMA DE MULT ===
func _update_mult(delta: float) -> void:
	var needWait: bool = true
	if hot <= 0 and mult > 1:
		if needWait:
			await get_tree().create_timer(3.0).timeout
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
	var needWait: bool = true
	if hot <= 0 and comboResetTimer >= 0:
		if needWait:
			await get_tree().create_timer(3.0).timeout
			needWait = false
		comboResetTimer -= delta
	else: needWait = true
	
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
	if rank > 1: rank -= 1
	hot = 0
	combo = 0
	mult = 1
	multDrainTime = 0.0
	var hud = _get_hud()
	if hud: hud.label_out()

func add_score(score: int) -> void:
	GeneralGameScore += score * mult

func reset_game_score() -> void:
	GeneralGameScore = 0
	rank = 1

func _get_hud() -> Control:
	if HUD and HUD.get_parent(): return HUD
	
	# Si no existe
	HUD = get_tree().get_first_node_in_group("HUD")
	return HUD
