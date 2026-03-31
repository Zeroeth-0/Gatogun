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

var burstLvl: int = 1
var laserLvl: int = 1
var chargeLvl: int = 1

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
		&"ALL":
			burstLvl = mini(burstLvl + 1, MAX_LVL)
			laserLvl = mini(laserLvl + 1, MAX_LVL)
			chargeLvl = mini(chargeLvl + 1, MAX_LVL)
			EVENTS.weapon_lvl_flow.emit(&"ALL", burstLvl)
		&"MAX":
			burstLvl = MAX_LVL
			laserLvl = MAX_LVL
			chargeLvl = MAX_LVL
			optionCount = 2
			EVENTS.weapon_lvl_flow.emit(&"MAX", MAX_LVL)
			EVENTS.option_flow.emit(true, true)
		&"OPTION":
			optionCount = mini(optionCount + 1, 2)
			EVENTS.weapon_lvl_flow.emit(&"OPTION", optionCount)
			EVENTS.option_flow.emit(rOptActive, lOptActive)
		_:
			push_warning("WEAPON.lvl_up(): unkwnown weapon")
			return

func reset_lvl() -> void:
	burstLvl = 1
	laserLvl = 1
	chargeLvl = 1
	optionCount = 2
	EVENTS.weapon_reset.emit()
	EVENTS.option_flow.emit(true, true)
	
