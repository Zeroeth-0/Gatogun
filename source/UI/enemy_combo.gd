extends RichTextLabel

var display_time := 1.5
var timer := 0.0
var is_showing := false

func show_combo():
	text = "+" + str(SCORE.combo)
	visible = true
	is_showing = true
	timer = 0.0

func _process(delta: float) -> void:
	if is_showing:
		timer += delta
		if timer >= display_time:
			visible = false
			is_showing = false
