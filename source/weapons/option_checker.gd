extends Node2D

func _process(delta: float) -> void:
	$OptionR.visible = WEAPON.rOptActive
	$OptionR.set_process(WEAPON.rOptActive)
	$OptionL.visible = WEAPON.lOptActive
	$OptionL.set_process(WEAPON.lOptActive)
