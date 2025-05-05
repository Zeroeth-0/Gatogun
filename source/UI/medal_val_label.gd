extends RichTextLabel

@export var display_time := 1.5 # Tiempo visible en segundos
var timer := 0.0

func set_val(medalVal) -> void:
	text = "+" + str(medalVal)
	visible = true

func _process(delta: float) -> void:
	timer += delta
	if timer >= display_time: queue_free()
