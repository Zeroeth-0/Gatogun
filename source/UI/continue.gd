extends Control

@export var countdown_start := 9
var countdown := countdown_start

@onready var timerLabel: RichTextLabel = $Timer
@onready var continueLabel: RichTextLabel = $Continue

# === SOMBRA ===
@export var shadowColor: Color = Color(0, 0, 0, 0.6)
@export var shadowOffset: Vector2 = Vector2(2, 2)
@export var shadowSize: int = 20

# === PULSO ===
@export var pulse_scale: float = 1.4
@export var pulse_duration: float = 0.12

var last_tick: int = 0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	var base_font := load("res://fonts/AprilGothicOne-R.ttf")
	var font := FontVariation.new()
	font.base_font = base_font
	font.opentype_features = {"kern": 0, "liga": 0, "calt": 0, "clig": 0}

	for label in [timerLabel, continueLabel]:
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

	timerLabel.add_theme_font_size_override("normal_font_size", 60)
	timerLabel.pivot_offset = timerLabel.size / 2.0

	continueLabel.add_theme_font_size_override("normal_font_size", 25)
	continueLabel.text = "[wave amp=48 freq=5.0]CONTINUE?[/wave]"

	countdown = countdown_start
	_update_timer_label()
	last_tick = Time.get_ticks_msec()

	GLOBAL.pause_game()

func _update_timer_label() -> void:
	timerLabel.text = str(countdown)
	# Espera un frame para que el label recalcule su tamaño antes de centrar el pivot
	_pulse()

func _pulse() -> void:
	timerLabel.pivot_offset = timerLabel.size / 2.0
	timerLabel.scale = Vector2.ONE
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(timerLabel, "scale", Vector2.ONE * pulse_scale, pulse_duration)
	tw.tween_property(timerLabel, "scale", Vector2.ONE, pulse_duration)

func _process(_delta: float) -> void:
	var current_tick := Time.get_ticks_msec()
	if current_tick - last_tick >= 1000:
		countdown -= 1
		_update_timer_label()
		last_tick = current_tick
		if countdown <= 0:
			GLOBAL.resume_game()
			GAME.game_over()
			queue_free()

	if Input.is_action_just_pressed("A") or \
	   Input.is_action_just_pressed("B") or \
	   Input.is_action_just_pressed("C"):
		countdown = max(countdown - 1, 0)
		_update_timer_label()

	if Input.is_action_just_pressed("Start"):
		GLOBAL.resume_game()
		GAME.lives = 2
		SCORE.reset_game_score()
		GAME.store(GAME.CENTER, true)
		GAME.spawn()
		queue_free()
