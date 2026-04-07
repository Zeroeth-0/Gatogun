extends Control

@onready var title: RichTextLabel = $Title
@onready var start: RichTextLabel = $Start

# === BLINK / CONFIRM ===
@export var blink_count: int = 3
@export var blink_speed: float = 0.07

# === SOMBRA ===
@export var shadowColor: Color = Color(0, 0, 0, 0.6)
@export var shadowOffset: Vector2 = Vector2(2, 2)
@export var shadowSize: int = 20

var first_frame: bool = true
var can_interact: bool = false
var is_exiting: bool = false

func _ready() -> void:
	var base_font := load("res://fonts/AprilGothicOne-R.ttf")
	var font := FontVariation.new()
	font.base_font = base_font
	font.opentype_features = {"kern": 0, "liga": 0, "calt": 0, "clig": 0}

	for label in [title, start]:
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.add_theme_font_override("normal_font", font)
		label.add_theme_constant_override("outline_size", 20)
		label.add_theme_color_override("outline_color", Color.BLACK)
		label.add_theme_color_override("font_shadow_color", shadowColor)
		label.add_theme_constant_override("shadow_offset_x", int(shadowOffset.x))
		label.add_theme_constant_override("shadow_offset_y", int(shadowOffset.y))
		label.add_theme_constant_override("shadow_outline_size", shadowSize)

	title.add_theme_font_size_override("normal_font_size", 36)
	title.text = "[wave amp=48 freq=5.0]GAME OVER[/wave]"

	start.add_theme_font_size_override("normal_font_size", 18)
	start.text = "[wave amp=48 freq=5.0]PUSH SHOOT BUTTON[/wave]"

	can_interact = true

func _process(_delta: float) -> void:
	if is_exiting:
		return
	if !first_frame:
		if can_interact and (Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A")):
			blink_and_confirm()
	else:
		first_frame = false

func blink_and_confirm() -> void:
	can_interact = false
	for i in blink_count:
		start.modulate = Color(1, 1, 1, 0)
		await get_tree().create_timer(blink_speed).timeout
		start.modulate = Color.WHITE
		await get_tree().create_timer(blink_speed).timeout
	animate_exit()

func animate_exit() -> void:
	is_exiting = true
	var screen_width := get_viewport_rect().size.x

	var t1 := create_tween()
	t1.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t1.tween_property(title, "position:x", screen_width + 200, 0.35)

	var t2 := create_tween()
	t2.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t2.tween_property(start, "position:x", screen_width + 200, 0.35).set_delay(0.05)

	await get_tree().create_timer(0.40).timeout
	GLOBAL.change_scene("MENU")
