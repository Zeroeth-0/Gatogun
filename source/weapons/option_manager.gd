extends Node2D

# === ESTILOS ===
enum StyleEnum { RANGE, DAMAGE, CLASSIC }

# === EXPORTS GENERALES ===
@export var GatoStyle: StyleEnum = StyleEnum.RANGE
@export var stdTargetPos: Vector2 = Vector2.ZERO
@export var dpsTargetPos: Vector2 = Vector2.ZERO

# === FLUJO DE COMPORTAMIENTO ===
func _process(_delta: float) -> void:
	option_waker()

func _ready():
	formation_handler()
	shot_type()

# === AUXILIAR ===
func formation_handler():
	match GatoStyle:
		StyleEnum.CLASSIC:
			$OptionR.OptionType = $OptionR.OptionEnum.FOLLOW
			$OptionL.OptionType = $OptionL.OptionEnum.FOLLOW
		_:
			$OptionR.OptionType = $OptionR.OptionEnum.SIDES
			$OptionL.OptionType = $OptionL.OptionEnum.SIDES

func shot_type():
	match GatoStyle:
		StyleEnum.DAMAGE:
			$OptionR.isLinear = true
			$OptionL.isLinear = true
			$OptionR.targetPos = dpsTargetPos * Vector2($OptionR.offSign, 1)
			$OptionL.targetPos = dpsTargetPos * Vector2($OptionL.offSign, 1)
		_:
			$OptionR.targetPos = stdTargetPos * Vector2($OptionR.offSign, 1)
			$OptionL.targetPos = stdTargetPos * Vector2($OptionL.offSign, 1)
			$OptionR.isLinear = false
			$OptionL.isLinear = false

func option_waker():
	$OptionR.visible = WEAPON.rOptActive
	$OptionR.set_process(WEAPON.rOptActive)
	$OptionL.visible = WEAPON.lOptActive
	$OptionL.set_process(WEAPON.lOptActive)
