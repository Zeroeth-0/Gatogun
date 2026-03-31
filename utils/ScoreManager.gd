# utils/ScoreManager.gd
# Name: SCORE
extends Node

# ==============================================================================
# CONSTANTS
# ==============================================================================

const HOT_DRAIN_RATE: float = 50.0
const HOT_SIZE: float = 100.0
const MAX_MEDAL_COUNTDOWN: float = 2.0
const MULT_INITIAL_DELAY: float = 0.5
const MULT_DRAIN_LIMIT: float = 0.01
const COMBO_RESET_TIME: float = 0.1

# ==============================================================================
# PUBLIC STATE
# Freely read from outside. Modify only through public methods
# ==============================================================================

var GeneralGameScore: int = 0
var combo: int = 0
var mult: int = 1
var hot: float = 0.0
var medalCountdown: float = 0.0

## Exposed so HUD can read max values for bar setup
var hotSize: float = HOT_SIZE

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var _hot_drain_delay: float = 0.0
var _combo_reset_timer: float = COMBO_RESET_TIME
var _combo_drain_time: float = 0.0
var _combo_available: bool = true
var _mult_drain_delay: float = 0.0
var _mult_drain_time: float = 0.0

# ==============================================================================
# MAIN LOOP
# ==============================================================================

func _process(delta: float) -> void:
	_tick_hot(delta)
	_tick_combo(delta)
	_tick_mult(delta)
	_tick_medal_countdown(delta)

# ==============================================================================
# HOT SYSTEM
# ==============================================================================

func _tick_hot(delta: float) -> void:
	if hot <= 0.0: return
	if _hot_drain_delay > 0.0:
		_hot_drain_delay -= delta
		return
	var prev := hot
	hot = maxf(hot - HOT_DRAIN_RATE * delta, 0.0)
	if hot != prev: EVENTS.hot_flow.emit(hot, false)

func increase_hot(value: int) -> void:
	hot = clampf(hot + float(value), 0.0, HOT_SIZE)
	_hot_drain_delay = 1.0
	EVENTS.hot_flow.emit(hot, false)
	EVENTS.hot_bar_pulse.emit()

func keep_hot() -> void:
	_hot_drain_delay = 0.1
	EVENTS.hot_flow.emit(hot, true)
	EVENTS.hot_bar_keep.emit()

# ==============================================================================
# MULT SYSTEM
# ==============================================================================

func _tick_mult(delta: float) -> void:
	if hot > 0.0 or mult <= 1:
		_mult_drain_delay = MULT_INITIAL_DELAY
		_mult_drain_time = 0.0
		return
	if _mult_drain_delay > 0.0:
		_mult_drain_delay -= delta
		return
	_mult_drain_time += delta
	while _mult_drain_time >= MULT_DRAIN_LIMIT:
		var prev := mult
		mult = max(mult - 1, 1)
		_mult_drain_time -= MULT_DRAIN_LIMIT
		if mult != prev: EVENTS.mult_flow.emit(mult)

func increase_mult() -> void:
	mult += 1
	EVENTS.mult_flow.emit(mult)

# ==============================================================================
# COMBO SYSTEM
# ==============================================================================

func _tick_combo(delta: float) -> void:
	if combo <= 0:
		combo = 0
		return
	
	# Timer only drains while hot is 0
	if hot <= 0.0: _combo_reset_timer -= delta
	if _combo_reset_timer > 0.0: return
	
	# Timer expired -> Signal HUD to hide combo label
	if !_combo_available:
		_combo_available = true
		EVENTS.combo_label_out.emit()
	
	# Drain combo (faster for larger combo)
	_combo_drain_time += delta
	var limit := maxf(0.01 * pow(0.95, float(combo)), 0.001)
	while _combo_drain_time >= limit and combo > 0:
		combo = max(combo - 3, 0)
		_combo_drain_time -= limit
	EVENTS.combo_flow.emit(combo)

func increase_combo(value: int) -> void:
	if _combo_available:
		_combo_available = false
		EVENTS.combo_label_in.emit()
	combo += value * 3
	_combo_reset_timer = COMBO_RESET_TIME
	EVENTS.combo_flow.emit(combo)

# ==============================================================================
# MEDAL COUNTDOWN
# ==============================================================================

func _tick_medal_countdown(delta: float) -> void:
	if medalCountdown <= 0.0:
		medalCountdown = 0.0
		return
	medalCountdown = maxf(medalCountdown - delta, 0.0)
	EVENTS.medal_countdown_flow.emit(medalCountdown)

# ==============================================================================
# SCORE
# ==============================================================================

func add_score(amount: int) -> void:
	var scored := amount * mult
	GeneralGameScore += scored
	EVENTS.score_flow.emit(GeneralGameScore, scored)

func reset_game_score() -> void:
	GeneralGameScore = 0
	EVENTS.score_flow.emit(0, 0)

# ==============================================================================
# RESET
# ==============================================================================

func reset() -> void:
	hot = 0.0
	combo = 0
	mult = 1
	medalCountdown = 0.0
	_combo_available = true
	_combo_reset_timer = COMBO_RESET_TIME
	_combo_drain_time = 0.0
	_mult_drain_delay = MULT_INITIAL_DELAY
	_mult_drain_time = 0.0
	_hot_drain_delay = 0.0
	
	EVENTS.score_reset.emit()
	EVENTS.combo_flow.emit(0)
	EVENTS.mult_flow.emit(1)
	EVENTS.hot_flow.emit(0.0, false)
	EVENTS.combo_label_out.emit()
