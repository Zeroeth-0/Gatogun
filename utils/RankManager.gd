# utils/RankManager.gd
# Name: RANK
extends Node

# ==============================================================================
# ENUMS + CONSTANTS
# ==============================================================================

enum DifficultyEnum { NOVICE, ORIGINAL, MANIAC }
const THRESHOLD: int = 100

# ==============================================================================
# PUBLIC STATE
# ==============================================================================

var DifficultyStyle: DifficultyEnum = DifficultyEnum.ORIGINAL
var rank: int = 1
var baseRank: int = 1

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var medalCombo: int = 0
var canDecrease: bool = false
var _current_hot: float = 0.0 # local mirror to detect hot -> 0 transition

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	EVENTS.hot_flow.connect(_on_hot_flow)
	EVENTS.mult_flow.connect(_on_mult_flow)

# ==============================================================================
# EVENT LISTENERS
# ==============================================================================

func _on_hot_flow(new_hot: float, _is_keeping: bool) -> void:
	if DifficultyStyle != DifficultyEnum.ORIGINAL: return
	var was_positive := _current_hot > 0.0
	_current_hot = new_hot
	if new_hot > 0.0: canDecrease = true
	elif was_positive and canDecrease: decrease_rank()

func _on_mult_flow(new_mult: int) -> void:
	if DifficultyStyle != DifficultyEnum.ORIGINAL: return
	# If mult dropped below our medal combo, the chain is broken
	if new_mult < medalCombo: reset_combo()

# ==============================================================================
# PUBLIC API
# ==============================================================================

func increase_combo() -> void:
	if DifficultyStyle != DifficultyEnum.ORIGINAL: return
	medalCombo += 1
	EVENTS.medal_combo_flow.emit(medalCombo)
	if medalCombo >= THRESHOLD * rank: increase_rank()

func increase_rank() -> void:
	if DifficultyStyle != DifficultyEnum.ORIGINAL: return
	var prev := rank
	rank = min(rank + 1, 6)
	reset_combo()
	if rank != prev: EVENTS.rank_flow.emit(rank, prev)

func decrease_rank() -> void:
	if DifficultyStyle != DifficultyEnum.ORIGINAL: return
	var prev := rank
	rank = max(rank - 1, 1)
	canDecrease = false
	reset_combo()
	if rank != prev: EVENTS.rank_flow.emit(rank, prev)

func reset_combo() -> void:
	medalCombo = 0
	EVENTS.medal_combo_flow.emit(0)

func reset_all() -> void:
	reset_combo()
	canDecrease = false
	_current_hot = 0.0
	DifficultyStyle = DifficultyEnum.ORIGINAL
	var prev := rank
	rank = 1
	baseRank = 1
	if rank != prev: EVENTS.rank_flow.emit(rank, prev)

func reset_soft() -> void:
	reset_combo()
	canDecrease = false
	_current_hot = 0.0
	var prev := rank
	rank = baseRank
	if rank != prev: EVENTS.rank_flow.emit(rank, prev)

## Called when difficulty is selected. Sets baseRank and clamps rank
func set_difficulty(style: DifficultyEnum) -> void:
	DifficultyStyle = style
	match style:
		DifficultyEnum.NOVICE:
			baseRank = 0
			rank = 0
		DifficultyEnum.MANIAC:
			baseRank = 6
			rank = 6
		DifficultyEnum.ORIGINAL:
			baseRank = 1
			rank = 1
	EVENTS.rank_flow.emit(rank, rank)
