extends Control

const OPTIONS: Array[String] = [
	"NOVICE",
	"DOUJIN",
	"MANIAC"
]

@onready var labels: Array[RichTextLabel] = []
var vbox: VBoxContainer

# === ESTADO INTERNO ===
var selected: int = 0
var initDelay: float = 0.20
var repDelay: float = 0.08
var deadzone: float = 0.12
var repTimer: float = 0.0
var lastDir: int = 0
var first_frame: bool = true

# === ANIMACIONES ===
var can_interact: bool = false
var active_tweens: Array[Tween] = []
var original_positions: Array[float] = []

# === CONFIGURACIÓN DIAGONAL ===
@export var diagonal_offset: float = 0.0
@export var vertical_spacing: int = 80

# === CONFIGURACIÓN DE SELECCIÓN ===
@export var unselected_alpha: float = 0.75
@export var blink_count: int = 3
@export var blink_speed: float = 0.07

# === SOMBRA ===
@export var shadowColor: Color = Color(0, 0, 0, 0.6)
@export var shadowOffset: Vector2 = Vector2(2, 2)
@export var shadowSize: int = 27

func _ready() -> void:
	vbox = $VBoxContainer
	vbox.clip_contents = false
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", vertical_spacing)

	RANK.reset_all()

	var base_font := load("res://fonts/AprilGothicOne-R.ttf")
	var font := FontVariation.new()
	font.base_font = base_font
	font.opentype_features = {"kern": 0, "liga": 0, "calt": 0, "clig": 0}

	for option_text in OPTIONS:
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size = Vector2(400, 50)
		label.clip_contents = false

		label.add_theme_font_override("normal_font", font)
		label.add_theme_font_size_override("normal_font_size", 30)
		label.add_theme_constant_override("outline_size", 27)
		label.add_theme_color_override("outline_color", Color.BLACK)
		label.add_theme_color_override("font_shadow_color", shadowColor)
		label.add_theme_constant_override("shadow_offset_x", int(shadowOffset.x))
		label.add_theme_constant_override("shadow_offset_y", int(shadowOffset.y))
		label.add_theme_constant_override("shadow_outline_size", shadowSize)

		label.text = "[center]" + option_text + "[/center]"

		vbox.modulate.a = 0
		vbox.add_child(label)
		labels.append(label)

	update_selection()

	await get_tree().process_frame
	await get_tree().process_frame
	animate_entry()

func animate_entry() -> void:
	can_interact = true
	var screen_width := get_viewport_rect().size.x

	await get_tree().process_frame

	original_positions.clear()
	for i in labels.size():
		var base_x := labels[i].position.x
		var diagonal_x := base_x + (i * diagonal_offset)
		original_positions.append(diagonal_x)

	vbox.modulate.a = 1

	for i in labels.size():
		var label := labels[i]
		label.position.x = screen_width + 100

		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(label, "position:x", original_positions[i], 0.35).set_delay(i * 0.05)
		active_tweens.append(tween)

func animate_exit(callback: Callable) -> void:
	can_interact = false

	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	active_tweens.clear()

	var screen_width := get_viewport_rect().size.x

	for i in labels.size():
		var tween := create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(labels[i], "position:x", screen_width + 100, 0.25).set_delay((labels.size() - 1 - i) * 0.04)

	await get_tree().create_timer((labels.size() - 1) * 0.04 + 0.25).timeout
	callback.call()

func _process(delta: float) -> void:
	if not can_interact:
		return

	var yAxis = Input.get_axis("ui_up", "ui_down") if Input.get_axis("ui_up", "ui_down") != 0 else INPUT.yAxis

	var direction: int = 0
	if yAxis > deadzone: direction = 1
	elif yAxis < -deadzone: direction = -1

	if direction != lastDir:
		if direction != 0:
			move_selection(direction == 1)
			repTimer = initDelay
		else:
			repTimer = 0.0
		lastDir = direction

	if direction != 0 and repTimer > 0:
		repTimer -= delta
		if repTimer <= 0:
			move_selection(direction == 1)
			repTimer = repDelay

	if not first_frame:
		if Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A"):
			confirm_selection()
		if Input.is_action_just_pressed("B"):
			animate_exit(func(): GLOBAL.raw_change_scene("MENU"))
	else:
		first_frame = false

func move_selection(is_down: bool) -> void:
	if is_down:
		selected = (selected + 1) % OPTIONS.size()
	else:
		selected = (selected - 1 + OPTIONS.size()) % OPTIONS.size()
	update_selection()

func update_selection() -> void:
	for i in labels.size():
		if i == selected:
			labels[i].modulate = Color.WHITE
			labels[i].text = "[center][wave amp=48 freq=5.0]" + OPTIONS[i] + "[/wave][/center]"
			shake_label(labels[i])
		else:
			labels[i].modulate = Color(0.25, 0.25, 0.25, unselected_alpha)
			labels[i].text = "[center]" + OPTIONS[i] + "[/center]"

func shake_label(label: RichTextLabel) -> void:
	if original_positions.is_empty():
		return

	var label_index := labels.find(label)
	if label_index == -1:
		return

	var shake_tween := create_tween()
	shake_tween.set_ease(Tween.EASE_IN_OUT)
	shake_tween.set_trans(Tween.TRANS_SINE)

	var original_x := original_positions[label_index]
	var shake_amount := 4.0

	shake_tween.tween_property(label, "position:x", original_x + shake_amount, 0.04)
	shake_tween.tween_property(label, "position:x", original_x - shake_amount, 0.04)
	shake_tween.tween_property(label, "position:x", original_x + shake_amount, 0.04)
	shake_tween.tween_property(label, "position:x", original_x, 0.04)

func blink_and_confirm(callback: Callable) -> void:
	can_interact = false
	var label := labels[selected]

	for i in blink_count:
		label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		await get_tree().create_timer(blink_speed).timeout
		label.modulate = Color.WHITE
		await get_tree().create_timer(blink_speed).timeout

	callback.call()

func confirm_selection() -> void:
	match selected:
		0:
			RANK.DifficultyStyle = RANK.DifficultyEnum.NOVICE
		1:
			RANK.DifficultyStyle = RANK.DifficultyEnum.DOUJIN
		2:
			RANK.DifficultyStyle = RANK.DifficultyEnum.MANIAC

	blink_and_confirm(func(): animate_exit(func(): GLOBAL.raw_change_scene("GATO")))
