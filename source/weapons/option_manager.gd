extends Node2D

# === EXPORTS GENERALES ===
@export var stdTargetPos: Vector2 = Vector2.ZERO
@export var dpsTargetPos: Vector2 = Vector2.ZERO

# === ESTADO INTERNO ===
var lastMoveDirection: Vector2 = Vector2.DOWN

# === FLUJO DE COMPORTAMIENTO ===
func _process(_delta: float) -> void:
	option_waker()
	lastMoveDirection = get_parent().lastMoveDirection

func _ready():
	formation_handler()
	shot_type()

# === AUXILIAR ===
func formation_handler():
	match GAME.GatoStyle:
		GAME.GatoEnum.CLASSIC:
			$OptionR.OptionType = $OptionR.OptionEnum.FOLLOW
			$OptionL.OptionType = $OptionL.OptionEnum.FOLLOW
		_:
			$OptionR.OptionType = $OptionR.OptionEnum.SIDES
			$OptionL.OptionType = $OptionL.OptionEnum.SIDES

func shot_type():
	match GAME.GatoStyle:
		GAME.GatoEnum.DAMAGE:
			$OptionR.targetPos = dpsTargetPos * Vector2($OptionR.offSign, 1)
			$OptionL.targetPos = dpsTargetPos * Vector2($OptionL.offSign, 1)
		_:
			$OptionR.targetPos = stdTargetPos * Vector2($OptionR.offSign, 1)
			$OptionL.targetPos = stdTargetPos * Vector2($OptionL.offSign, 1)

func option_waker():
	$OptionR.visible = WEAPON.rOptActive
	$OptionR.set_process(WEAPON.rOptActive)
	$OptionL.visible = WEAPON.lOptActive
	$OptionL.set_process(WEAPON.lOptActive)
