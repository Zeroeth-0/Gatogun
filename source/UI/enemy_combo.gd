extends RichTextLabel

var displayTime := 1.5
var timer := 0.0
var isShowing := false
var freeSet := false

var freeDuration := 0.5    # Tiempo de vida
var finalScale := Vector2(1.5, 1.5)  # Tamaño final

# Parpadeo
var blinkCount := 3      # Parpadeos
var offTime := 0.07   # Tiempo apagado
var onTime := 0.07   # Tiempo encendido
var startDelay := 0.3   # Retraso parpadeo

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
		if timer >= displayTime:
			isShowing = false
			free_label()

func free_label():
	reparent(get_tree().current_scene)
	if !freeSet: text = "+" + str(SCORE.combo * SCORE.mult)
	freeSet = true
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	
	# 1. Crece suavemente hasta el tamaño final
	tween.tween_property(self, "scale", finalScale, freeDuration)
	# 2. Parpadeos controlados con bucle (¡fácil de ajustar!)
	_do_blinks(tween)
	# 3. Se destruye completamente cuando termina todo
	tween.tween_callback(queue_free).set_delay(freeDuration)

func _do_blinks(tween: Tween):
	var time := startDelay
	
	for i in blinkCount:
		# Apagado
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.001).set_delay(time)
		time += offTime
		# Encendido
		tween.parallel().tween_property(self, "modulate:a", 1.0, 0.001).set_delay(time)
		time += onTime
