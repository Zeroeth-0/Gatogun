extends Control

@onready var band: ColorRect          = $ColorRect
@onready var label: RichTextLabel     = $RichTextLabel
@onready var border_top: ColorRect    = $BorderTop
@onready var border_bottom: ColorRect = $BorderBottom

@export var BORDER_COLOR:  Color
const BORDER_HEIGHT: float = 32.0
const FONT_SIZE:     int   = 72

func _ready() -> void:
	process_mode = PROCESS_MODE_PAUSABLE
	await get_tree().process_frame
	await get_tree().process_frame

	band.add_to_group("ShaderHolder")

	var font := load("res://fonts/AprilGothicOne-R.ttf")
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE

	# ── Bordes ──
	border_top.color    = BORDER_COLOR
	border_top.size     = Vector2(band.size.x, BORDER_HEIGHT)
	border_top.position = Vector2(band.position.x, band.position.y - BORDER_HEIGHT)

	border_bottom.color    = BORDER_COLOR
	border_bottom.size     = Vector2(band.size.x, BORDER_HEIGHT)
	border_bottom.position = Vector2(band.position.x, band.position.y + band.size.y)

	# ── Label ──
	label.bbcode_enabled = true
	label.fit_content    = true
	label.scroll_active  = false
	label.autowrap_mode  = TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	label.add_theme_color_override("default_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 6)
	label.add_theme_constant_override("shadow_offset_y", 6)
	label.add_theme_constant_override("shadow_outline_size", 5)
	label.text = "[wave amp=48 freq=5.0] READY? [/wave]"

	await get_tree().process_frame

	label.position.y = band.position.y + (band.size.y - label.size.y) / 2.0
	label.position.x = -label.size.x - 20.0

	_animate()

func _animate() -> void:
	var vp     := get_viewport_rect().size
	var center := vp.x / 2.0 - label.size.x / 2.0
	var exit   := vp.x + 20.0

	# ── Banda entra ──
	var band_target_x   := band.position.x
	var border_target_x := border_top.position.x
	band.position.x          = -(band.size.x + 40.0)
	border_top.position.x    = -(band.size.x + 40.0)
	border_bottom.position.x = -(band.size.x + 40.0)

	var tin := create_tween().set_parallel(true)
	tin.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tin.tween_property(band,          "position:x", band_target_x,   0.2)
	tin.tween_property(border_top,    "position:x", border_target_x, 0.2)
	tin.tween_property(border_bottom, "position:x", border_target_x, 0.2)
	await tin.finished

	# ── Entra rápido, frena en el centro ──
	var t1 := create_tween()
	t1.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t1.tween_property(label, "position:x", center, 1.0)
	await t1.finished

	# ── Sale lento y se dispara ──
	var t2 := create_tween()
	t2.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t2.tween_property(label, "position:x", exit, 1.0)
	await t2.finished

	# ── Banda sale ──
	var tout := create_tween().set_parallel(true)
	tout.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tout.tween_property(band,          "position:x", -(band.size.x + 40.0), 0.18)
	tout.tween_property(border_top,    "position:x", -(band.size.x + 40.0), 0.18)
	tout.tween_property(border_bottom, "position:x", -(band.size.x + 40.0), 0.18)
	await tout.finished

	FLOW.notify_ui_done("READY")
	queue_free()
