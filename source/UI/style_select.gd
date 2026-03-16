extends Control

# === CONFIGURACIÓN ===
const GATOS: Array[Dictionary] = [
	{"name": "ZEBE",   "style": "DAMAGE"},
	{"name": "FUKU",   "style": "RANGE"},
	{"name": "SERGIO", "style": "CLASSIC"},
]
const DOLLS: Array[Dictionary] = [
	{"name": "NOEL", "style": "STRONG"},
	{"name": "ACTEA",  "style": "SPEED"},
	{"name": "PIRARU", "style": "NEWBIE"},
]

var STYLES: Array[Dictionary]
enum SelectEnum { GATO, DOLL }
@export var SelectStyle: SelectEnum = SelectEnum.GATO

# === NODOS ===
@onready var desc_label: Label = $Label
@onready var cards: Array[VBoxContainer] = []

# === ESTADO ===
var selected: int = 1
var initDelay: float = 0.30
var repDelay: float = 0.15
var deadzone: float = 0.1
var repTimer: float = 0.0
var lastDir: int = 0

# === CONFIGURACIÓN BARAJA ===
@export var card_spacing: float = 200.0
@export var back_card_y_offset: float = 60.0
@export var back_card_scale: float = 0.85
@export var center_offset_x: float = -65.0
@export var center_offset_y: float = -50.0
@export var animation_speed: float = 0.15

# === CONFIGURACIÓN DE SELECCIÓN ===
@export var unselected_alpha: float = 0.75
var blink_count: int = 4
var blink_speed: float = 0.08

# === ANIMACIONES ===
var active_tweens: Array[Tween] = []
var can_interact: bool = false

func _ready() -> void:
	match SelectStyle:
		SelectEnum.GATO: STYLES = GATOS
		SelectEnum.DOLL: STYLES = DOLLS

	var font := load("res://fonts/AprilGothicOne-R.ttf")
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE

	for i in range(3):
		var vbox: VBoxContainer = get_child(i + 1)
		cards.append(vbox)

		var name_label: Label = vbox.get_child(1)
		name_label.text = STYLES[i].name
		name_label.add_theme_font_override("font", font)
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_constant_override("outline_size", 13)
		name_label.add_theme_color_override("outline_color", Color.BLACK)

		vbox.modulate.a = 0

	await get_tree().process_frame
	await get_tree().process_frame

	for card in cards:
		card.pivot_offset = card.size / 2
		card.scale = Vector2(2.0, 2.0)

	await get_tree().process_frame

	update_selection(false)

	if desc_label:
		desc_label.text = STYLES[selected].style + " STYLE"

	var final_positions: Array[Vector2] = []
	for card in cards:
		final_positions.append(card.position)
		card.position.x = GAME.CENTER.x + 600

	for i in cards.size():
		var card = cards[i]
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_parallel(true)
		tween.tween_property(card, "position:x", final_positions[i].x, 0.4).set_delay(i * 0.1)
		tween.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(i * 0.1)

	await get_tree().create_timer((cards.size() - 1) * 0.1 + 0.4).timeout
	can_interact = true

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A"):
		confirm_selection()
	if Input.is_action_just_pressed("B"):
		go_back()

	if not can_interact:
		return

	var xAxis := INPUT.xAxis
	var direction: int = 0

	if xAxis > deadzone: direction = 1
	elif xAxis < -deadzone: direction = -1

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

func move_selection(is_right: bool) -> void:
	if is_right:
		selected = (selected + 1) % STYLES.size()
	else:
		selected = (selected - 1 + STYLES.size()) % STYLES.size()
	update_selection()

func get_card_offset(card_index: int) -> int:
	var direct_offset := card_index - selected
	if direct_offset == 2: return -1
	elif direct_offset == -2: return 1
	else: return direct_offset

func kill_active_tweens() -> void:
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	active_tweens.clear()

func update_selection(animate: bool = true) -> void:
	if animate:
		kill_active_tweens()

	var screen_center := GAME.CENTER

	for i in cards.size():
		var card := cards[i]
		var offset := get_card_offset(i)
		var is_center := (offset == 0)

		var target_scale_value := 2.0 if is_center else (2.0 * back_card_scale)
		var target_scale := Vector2(target_scale_value, target_scale_value)
		var target_x := screen_center.x + (offset * card_spacing) + center_offset_x
		var target_y := screen_center.y + center_offset_y
		if not is_center:
			target_y += back_card_y_offset

		card.z_index = 100 if is_center else 10 + offset

		var icon: TextureRect = card.get_child(0)
		var name_label: Label = card.get_child(1)
		var content_color := Color.WHITE if is_center else Color(0.25, 0.25, 0.25, unselected_alpha)

		if animate:
			var tween := create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_parallel(true)
			tween.tween_property(card, "position:x", target_x, animation_speed)
			tween.tween_property(card, "position:y", target_y, animation_speed)
			tween.tween_property(card, "scale", target_scale, animation_speed)
			tween.tween_property(icon, "modulate", content_color, animation_speed * 0.66)
			tween.tween_property(name_label, "modulate", content_color, animation_speed * 0.66)
			active_tweens.append(tween)
		else:
			card.position = Vector2(target_x, target_y)
			card.scale = target_scale
			icon.modulate = content_color
			name_label.modulate = content_color

		name_label.add_theme_font_size_override("font_size", 20)

	if desc_label:
		desc_label.text = STYLES[selected].style + " STYLE"

func blink_and_confirm(callback: Callable) -> void:
	can_interact = false
	var card := cards[selected]
	var icon: TextureRect = card.get_child(0)
	var name_label: Label = card.get_child(1)

	for i in blink_count:
		icon.modulate = Color(1.0, 1.0, 1.0, 0.0)
		name_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		await get_tree().create_timer(blink_speed).timeout
		icon.modulate = Color.WHITE
		name_label.modulate = Color.WHITE
		await get_tree().create_timer(blink_speed).timeout

	callback.call()

func animate_exit(callback: Callable) -> void:
	can_interact = false
	kill_active_tweens()

	for card in cards:
		var tween := create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_parallel(true)
		tween.tween_property(card, "position:x", GAME.CENTER.x + 600, 0.25)
		tween.tween_property(card, "modulate:a", 0.0, 0.2)

	await get_tree().create_timer(0.25).timeout
	callback.call()

func confirm_selection() -> void:
	var chosenStyle = STYLES[selected].style
	blink_and_confirm(func():
		animate_exit(func():
			match SelectStyle:
				SelectEnum.GATO:
					GAME.set_gato(chosenStyle)
					GLOBAL.raw_change_scene("DOLL")
				SelectEnum.DOLL:
					GAME.set_doll(chosenStyle)
					FLOW.begin_game()
		)
	)

func go_back() -> void:
	animate_exit(func():
		match SelectStyle:
			SelectEnum.GATO: GLOBAL.raw_change_scene("MODE")
			SelectEnum.DOLL: GLOBAL.raw_change_scene("GATO")
	)
