extends RichTextLabel

var displayTime := 1.5
var timer := 0.0
var isShowing := false
var freeSet := false

var freeDuration := 0.5 # Tiempo de vida
var finalScale := Vector2(1, 1) # Tamaño final
var offset := 0.0

func show_combo():
	text = "+" + str(SCORE.combo)
	visible = true
	isShowing = true
	timer = 0.0
	
	scale = Vector2.ONE
	modulate = Color.WHITE

func _process(delta: float) -> void:
	if isShowing:
		timer += delta
		if timer >= displayTime: isShowing = false
	
	if freeSet: position += Vector2(delta * 100, delta * -100)

func free_label(enemType: String):
	match enemType:
		"STD":
			finalScale = Vector2(2, 2)
			offset = 50
		"MID":
			finalScale = Vector2(4, 4)
			offset = 150
		"ELITE":
			finalScale = Vector2(6, 6)
			offset = 300
	
	reparent(get_tree().current_scene)
	if !freeSet: text = "+" + str(SCORE.combo * SCORE.mult)
	freeSet = true
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	
	# 1. Crece suavemente hasta el tamaño final
	tween.tween_property(self, "scale", finalScale, freeDuration)
	position.x -= offset
	# 3. Se destruye completamente cuando termina todo
	tween.tween_callback(queue_free).set_delay(freeDuration)
