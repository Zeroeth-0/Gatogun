 # source/UI/continue.gd

extends Control

# === Settings ===
@export var countdown_start: int = 9
@export var pulse_scale: float = 1.4
@export var pulse_duration: float = 0.12

# === Shadow ===
@export var shadow_color: Color = Color(0, 0, 0, 0.6)
@export var shadow_offset: Vector2 = Vector2(2, 2)
@export var shadow_size: int = 20

# === Nodes ===
@onready var timer_label: RichTextLabel = $Timer
@onready var continue_label: RichTextLabel = $Continue

# === Internal State ===
var countdown: int
var _tick_accumulator: float = 0.0
var _can_interact: bool = false

# === Setup ===
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	countdown = countdown_start
	
	var base_font := load("res://fonts/AprilGothicOne-R.ttf")
	var font := FontVariation.new()
	font.base_font = base_font
	font.opentype_features = {"kern": 0, "liga": 0, "calt": 0, "clig": 0}
	
	for label: RichTextLabel in [timer_label, continue_label]:
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.add_theme_font_override("normal_font", font)
		label.add_theme_constant_override("outline_size", 20)
		label.add_theme_color_override("outline_color", Color.BLACK)
		label.add_theme_color_override("font_shadow_color", shadow_color)
		label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
		label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
		label.add_theme_constant_override("shadow_outline_size", shadow_size)
	
	timer_label.add_theme_font_size_override("normal_font_size", 60)
	timer_label.pivot_offset = timer_label.size / 2.0
	
	continue_label.add_theme_font_size_override("normal_font_size", 25)
	continue_label.text = "[wave amp=48 freq=5.0]CONTINUE?[/wave]"
	
	_update_timer_label()
	GLOBAL.pause_game()
	
	await get_tree().process_frame
	_can_interact = true

# === Loop ===
func _process(delta: float) -> void:
	_tick_accumulator += delta
	if _tick_accumulator >= 1.0:
		_tick_accumulator -= 1.0
		countdown -= 1
		_update_timer_label()
		if countdown <= 0:
			_game_over()
			return
	
	if !_can_interact: return
	
	if Input.is_action_just_pressed("A") or \
	   Input.is_action_just_pressed("B") or \
	   Input.is_action_just_pressed("C"):
		countdown = max(countdown - 1, 0)
		_update_timer_label()
		if countdown <= 0:
			_game_over()
			return
	
	if Input.is_action_just_pressed("Start"): _continue()

# === Actions ===
func _continue() -> void:
	GLOBAL.resume_game()
	GAME.lives = 2
	SCORE.reset_game_score()
	GAME.store(GAME.CENTER, true)
	GAME.spawn()
	queue_free()

func _game_over() -> void:
	GLOBAL.resume_game()
	GAME.game_over()
	queue_free()

# === UI ===
func _update_timer_label() -> void:
	timer_label.text = str(countdown)
	_pulse()

func _pulse() -> void:
	timer_label.pivot_offset = timer_label.size / 2.0
	timer_label.scale = Vector2.ONE

	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(timer_label, "scale",
			Vector2.ONE * pulse_scale, pulse_duration)
	tw.tween_property(timer_label, "scale",
			Vector2.ONE, pulse_duration)

func blink_and_confirm(callback: Callable) -> void:
	_can_interact = false
	timer_label.modulate = Color(1, 1, 1, 0)
	await get_tree().create_timer(0.07, false).timeout
	timer_label.modulate = Color.WHITE
	await get_tree().create_timer(0.07, false).timeout
	callback.call()
