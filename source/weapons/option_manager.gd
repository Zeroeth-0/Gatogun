extends Node2D

@export var stdTargetPos: Vector2 = Vector2.ZERO
@export var dpsTargetPos: Vector2 = Vector2.ZERO

var lastMoveDirection: Vector2 = Vector2.DOWN

func _process(_delta: float) -> void:
	formation_handler()
	shot_type()
	option_waker()
	if get_parent() and "lastMoveDirection" in get_parent():
		lastMoveDirection = get_parent().lastMoveDirection

func _ready():
	formation_handler()
	shot_type()

func formation_handler():
	if not has_node("OptionR") or not has_node("OptionL"): return
	match GAME.OptionStyle:
		GAME.OptionEnum.FOLLOW:
			$OptionR.OptionType = 1
			$OptionL.OptionType = 1
		_:
			$OptionR.OptionType = 0
			$OptionL.OptionType = 0

func shot_type():
	if not has_node("OptionR") or not has_node("OptionL"): return
	match GAME.OptionStyle:
		GAME.OptionEnum.ORBIT:
			$OptionR.targetPos = dpsTargetPos * Vector2($OptionR.offSign, 1)
			$OptionL.targetPos = dpsTargetPos * Vector2($OptionL.offSign, 1)
		_:
			$OptionR.targetPos = stdTargetPos * Vector2($OptionR.offSign, 1)
			$OptionL.targetPos = stdTargetPos * Vector2($OptionL.offSign, 1)

func option_waker():
	if not has_node("OptionR") or not has_node("OptionL"): return
	$OptionR.visible = WEAPON.rOptActive
	$OptionR.set_process(WEAPON.rOptActive)
	$OptionL.visible = WEAPON.lOptActive
	$OptionL.set_process(WEAPON.lOptActive)
