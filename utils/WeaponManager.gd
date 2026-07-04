# utils/WeaponManager.gd
# Name: WEAPON
extends Node

# ==============================================================================
# CONSTANTS
# ==============================================================================

const MAX_LVL: int = 3

# ==============================================================================
# PUBLIC STATE
# ==============================================================================

var burstLvl: int = 3
var laserLvl: int = 3
var chargeLvl: int = 3

## 0 = none, 1 = right, 2 = both
var optionCount: int = 2
var rOptActive: bool:
	get: return optionCount >= 1
var lOptActive: bool:
	get: return optionCount >= 2

# ==============================================================================
# PUBLIC API
# ==============================================================================

func lvl_up(weapon: StringName) -> void:
	match weapon:
		&"OPTION":
			optionCount = mini(optionCount + 1, 2)
			EVENTS.weapon_lvl_flow.emit(&"OPTION", optionCount)
			EVENTS.option_flow.emit(rOptActive, lOptActive)
		_:
			# Las armas ya no suben de nivel
			pass

func reset_lvl() -> void:
	burstLvl = 3
	laserLvl = 3
	chargeLvl = 3
	optionCount = 2
	EVENTS.weapon_reset.emit()
	EVENTS.option_flow.emit(true, true)
