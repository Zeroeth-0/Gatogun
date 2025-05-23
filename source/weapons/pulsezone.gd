extends Area2D

@export var scaleSpeed := 20.0
@export var scaleResetSpeed := 300.0
@export var maxScale := 30.0
@export var minScale := 1.0

func _process(delta):
	var targetScale: float

	if not INPUT.firing and not INPUT.fireHold:
		targetScale = maxScale
		scale.x = move_toward(scale.x, targetScale, scaleSpeed * delta)
		scale.y = move_toward(scale.y, targetScale, scaleSpeed * delta)
	else:
		targetScale = minScale
		scale.x = move_toward(scale.x, targetScale, scaleResetSpeed * delta)
		scale.y = move_toward(scale.y, targetScale, scaleResetSpeed * delta)
