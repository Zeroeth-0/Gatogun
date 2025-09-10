extends Node

# === DICCIONARIO ARMAS ===
var weapons:= {
	"BURST": 1.0,
	"LASER": 1.0,
	"CHARGE": 1.0,
	"OPTION": 1.0
}

# === ESTADO ARMAS ===
var burstLvl: float = 1.0
var laserLvl: float = 1.0
var chargeLvl: float = 1.0
var maxLvl: float = 3.0
var rOptActive: bool = false
var lOptActive: bool = false
var optionCounter: float = 0.0

# === NIVEL ARMAS ===
func lvl_up(weapon: String):
	match weapon:
		"ALL":
			for key in weapons: weapons[key] = min(weapons[key] + 1.0, maxLvl)
		"MAX":
			for key in weapons: weapons[key] = maxLvl
			optionCounter = 2
		"OPTION":
			if optionCounter < 2: optionCounter += 1.0
		_:
			if weapons.has(weapon): weapons[weapon] = min(weapons[weapon] + 1.0, maxLvl)
	remap_lvl()

func remap_lvl():
	burstLvl = weapons["BURST"]
	laserLvl = weapons["LASER"]
	chargeLvl = weapons["CHARGE"]
	rOptActive = optionCounter >= 1
	lOptActive = optionCounter >= 2
