extends RichTextLabel

var displayTime := 1.5
var timer := 0.0
var isShowing := false
var freeSet := false
var freeDuration := 0.5
var finalScale := Vector2(1, 1)
var offset := 0.0

func _ready() -> void:
	_apply_style()

func _apply_style() -> void:
	# Cargar fuente
	var font = load("res://fonts/AprilGothicOne-R.ttf")
	
	# Crear FontVariation para poder añadir el shadow
	var font_var = FontVariation.new()
	font_var.base_font = font
	
	# Crear el drop shadow
	var shadow = font_var.opentype_features  # no usado, shadow va en el theme
	
	# Aplicar fuente vía theme override
	add_theme_font_override("normal_font", font)
	add_theme_font_size_override("normal_font_size", 15) # ajusta el tamaño

	# Drop shadow vía theme
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	add_theme_constant_override("shadow_offset_x", 3)
	add_theme_constant_override("shadow_offset_y", 3)
	add_theme_constant_override("shadow_outline_size", 2) # blur del shadow

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
	
	reparent(GLOBAL.get_subtree())
	if !freeSet: text = "+" + str(SCORE.combo * SCORE.mult)
	freeSet = true

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "scale", finalScale, freeDuration)
	position.x -= offset
	tween.tween_callback(queue_free).set_delay(freeDuration)
