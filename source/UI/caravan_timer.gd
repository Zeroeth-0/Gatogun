# caravan_timer.gd
extends Control

@export var total_time:    float  = 180.0
@export var shadow_color:  Color   = Color(0, 0, 0, 0.9)
@export var shadow_offset: Vector2 = Vector2(6, 6)
@export var shadow_size:   int     = 5

@onready var countdown_label: RichTextLabel = $CountdownLabel
@onready var time_label:      RichTextLabel = $TimeLabel

signal countdown_finished

var _remaining: float = 0.0
var _running:   bool  = false

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = PROCESS_MODE_PAUSABLE
	_remaining              = total_time
	countdown_label.visible = true
	time_label.visible      = false

	await get_tree().process_frame
	await get_tree().process_frame

	var base_font := load("res://fonts/AprilGothicOne-R.ttf")

	var font := FontVariation.new()
	font.base_font = base_font
	font.opentype_features = {"kern": 0, "liga": 0, "calt": 0, "clig": 0}

	var font_tnum := FontVariation.new()
	font_tnum.base_font = base_font
	font_tnum.opentype_features = {"kern": 0, "liga": 0, "calt": 0, "clig": 0, "tnum": 1}

	_setup_rich_label(countdown_label, font)
	countdown_label.add_theme_font_size_override("normal_font_size", 100)

	_setup_rich_label(time_label, font_tnum)

	_refresh_display()
	_run_intro()

# ─────────────────────────────────────────────────────────────
func _setup_rich_label(label: RichTextLabel, font: Font) -> void:
	label.bbcode_enabled = true
	label.fit_content    = true
	label.scroll_active  = false
	label.autowrap_mode  = TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", 50)
	label.add_theme_color_override("default_color",      Color.WHITE)
	label.add_theme_color_override("font_shadow_color",  shadow_color)
	label.add_theme_constant_override("shadow_offset_x",     int(shadow_offset.x))
	label.add_theme_constant_override("shadow_offset_y",     int(shadow_offset.y))
	label.add_theme_constant_override("shadow_outline_size", shadow_size)

# ─────────────────────────────────────────────────────────────
func _run_intro() -> void:
	for n: int in [3, 2, 1]:
		countdown_label.text = str(n)
		await get_tree().create_timer(1.0, false).timeout
	countdown_label.visible = false
	time_label.visible      = true
	countdown_finished.emit()
	_running = true

# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _running:
		return
	_remaining = maxf(_remaining - delta, 0.0)
	_refresh_display()
	if _remaining <= 0.0:
		_running = false
		FLOW.notify_time_up()

# ─────────────────────────────────────────────────────────────
func _refresh_display() -> void:
	var total_cents: int = int(_remaining * 100)
	var minutes:     int = total_cents / 6000
	var seconds:     int = (total_cents % 6000) / 100
	var cents:       int = total_cents % 100
	time_label.text = "%02d:%02d:%02d" % [minutes, seconds, cents]
