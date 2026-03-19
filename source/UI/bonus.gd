extends Control

# ═══════════════════════════════════════════════════════════
# SCENE REFERENCES
# ═══════════════════════════════════════════════════════════
@onready var title_label:   RichTextLabel    = $RichTextLabel
@onready var actea_render:  Node2D           = $ActeaRender
@onready var bell_sprite:   AnimatedSprite2D = $AnimatedSprite2D
@onready var border_top                      = $BorderTop
@onready var border_bottom                   = $BorderBottom

# ═══════════════════════════════════════════════════════════
# POSITIONS
# ═══════════════════════════════════════════════════════════
@export var title_label_position:  Vector2 = Vector2(320, 80)
@export var medal_label_offset:    Vector2 = Vector2(48, -12)
@export var no_miss_label_offset:  Vector2 = Vector2(-20, 52)

# ═══════════════════════════════════════════════════════════
# TIMINGS
# ═══════════════════════════════════════════════════════════
@export var delay_entry_to_band:    float = 0.40
@export var delay_band_to_medals:   float = 0.30
@export var delay_medals_to_nomiss: float = 0.35
@export var hold_time:              float = 2.50

# ═══════════════════════════════════════════════════════════
# STYLE
# ═══════════════════════════════════════════════════════════
@export var shadow_color:  Color   = Color(0, 0, 0, 0.6)
@export var shadow_offset: Vector2 = Vector2(2, 2)
@export var shadow_size:   int     = 20

# ═══════════════════════════════════════════════════════════
# INTERNALS
# ═══════════════════════════════════════════════════════════
var _base_font:   Font
var _shader_mat:  ShaderMaterial
var _shader_time: float = 0.0

var _medal_label:   RichTextLabel
var _no_miss_label: RichTextLabel
var _result_label:  RichTextLabel
var _no_miss_row:   HBoxContainer

var _orig_actea_x: float
var _orig_bell_x:  float


# ═══════════════════════════════════════════════════════════
# READY
# ═══════════════════════════════════════════════════════════
func _ready() -> void:
	_base_font = load("res://fonts/AprilGothicOne-R.ttf") as Font

	_orig_actea_x = actea_render.position.x
	_orig_bell_x  = bell_sprite.position.x

	title_label.position = title_label_position

	_setup_title_label()
	_create_bonus_labels()

	var sw := get_viewport_rect().size.x
	actea_render.modulate   = Color(1, 1, 1, 0)
	bell_sprite.modulate    = Color(1, 1, 1, 0)
	actea_render.position.x = -sw - 200.0
	bell_sprite.position.x  =  sw + 200.0

	title_label.modulate  = Color(1, 1, 1, 0)
	_medal_label.modulate = Color(1, 1, 1, 0)
	_no_miss_row.modulate = Color(1, 1, 1, 0)
	if border_top:    border_top.modulate    = Color(1, 1, 1, 0)
	if border_bottom: border_bottom.modulate = Color(1, 1, 1, 0)

	await get_tree().process_frame
	await get_tree().process_frame

	_position_bonus_labels()

	await get_tree().process_frame

	_medal_label.position.x = sw + 200.0
	_no_miss_row.position.x = sw + 200.0

	await get_tree().process_frame

	actea_render.modulate = Color.WHITE
	bell_sprite.modulate  = Color.WHITE

	_sequence_main()


# ═══════════════════════════════════════════════════════════
# MAIN SEQUENCE
# ═══════════════════════════════════════════════════════════
func _sequence_main() -> void:
	_enter_left_group()
	await get_tree().create_timer(delay_entry_to_band).timeout

	var tw_band := create_tween()
	if border_top:    tw_band.parallel().tween_property(border_top,    "modulate:a", 1.0, 0.30)
	if border_bottom: tw_band.parallel().tween_property(border_bottom, "modulate:a", 1.0, 0.30)
	await tw_band.finished

	await get_tree().create_timer(delay_band_to_medals).timeout

	_enter_medals_group()
	await get_tree().create_timer(0.40).timeout

	await get_tree().create_timer(delay_medals_to_nomiss).timeout

	_enter_nomiss_group()
	await get_tree().create_timer(0.38).timeout

	await get_tree().create_timer(hold_time).timeout

	await _do_exit()
	queue_free()


# ═══════════════════════════════════════════════════════════
# ENTRY ANIMATIONS
# ═══════════════════════════════════════════════════════════
func _enter_left_group() -> void:
	var tw_a := create_tween()
	tw_a.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw_a.tween_property(actea_render, "position:x", _orig_actea_x, 0.40)

	var tw_t := create_tween()
	tw_t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw_t.tween_property(title_label, "modulate:a", 1.0, 0.35).set_delay(0.08)


func _enter_medals_group() -> void:
	var tw_b := create_tween()
	tw_b.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw_b.tween_property(bell_sprite, "position:x", _orig_bell_x, 0.35)

	var medal_dest_x := _orig_bell_x + medal_label_offset.x
	var tw_m := create_tween()
	tw_m.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw_m.tween_property(_medal_label, "position:x", medal_dest_x, 0.35)
	tw_m.parallel().tween_property(_medal_label, "modulate:a", 1.0, 0.25)


func _enter_nomiss_group() -> void:
	var no_miss_dest_x := _orig_bell_x + no_miss_label_offset.x
	_no_miss_row.scale = Vector2(0.8, 0.8)

	var tw_n := create_tween()
	tw_n.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw_n.tween_property(_no_miss_row, "position:x", no_miss_dest_x, 0.30)
	tw_n.parallel().tween_property(_no_miss_row, "modulate:a", 1.0, 0.22)
	tw_n.parallel().tween_property(_no_miss_row, "scale", Vector2(1.0, 1.0), 0.30)


# ═══════════════════════════════════════════════════════════
# EXIT ANIMATION
# ═══════════════════════════════════════════════════════════
func _do_exit() -> void:
	# Añadir puntos
	SCORE.add_score(100000 * FLOW.medal_counter) if FLOW.missed else SCORE.add_score(FLOW.medal_counter)
	
	var sw := get_viewport_rect().size.x

	var tw_f := create_tween()
	tw_f.parallel().tween_property(_medal_label, "modulate:a", 0.0, 0.18)
	tw_f.parallel().tween_property(_no_miss_row, "modulate:a", 0.0, 0.18)
	if border_top:    tw_f.parallel().tween_property(border_top,    "modulate:a", 0.0, 0.22)
	if border_bottom: tw_f.parallel().tween_property(border_bottom, "modulate:a", 0.0, 0.22)

	var tw_t := create_tween()
	tw_t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw_t.tween_property(title_label, "modulate:a", 0.0, 0.25)

	var tw_a := create_tween()
	tw_a.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw_a.tween_property(actea_render, "position:x", -sw - 200.0, 0.28).set_delay(0.04)

	var tw_b := create_tween()
	tw_b.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw_b.tween_property(bell_sprite, "position:x", sw + 200.0, 0.28)

	var tw_m := create_tween()
	tw_m.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw_m.tween_property(_medal_label, "position:x", sw + 200.0, 0.28)

	var tw_n := create_tween()
	tw_n.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw_n.tween_property(_no_miss_row, "position:x", sw + 200.0, 0.25).set_delay(0.05)

	await get_tree().create_timer(0.35).timeout


# ═══════════════════════════════════════════════════════════
# TITLE LABEL SETUP
# ═══════════════════════════════════════════════════════════
func _setup_title_label() -> void:
	title_label.bbcode_enabled = true
	title_label.fit_content    = true
	title_label.scroll_active  = false
	title_label.autowrap_mode  = TextServer.AUTOWRAP_OFF
	title_label.clip_contents  = false
	_apply_rtl_style(title_label, 44)
	title_label.add_theme_color_override("default_color", Color.WHITE)
	title_label.text = "[wave amp=48 freq=5.0]VICTORY![/wave]"


# ═══════════════════════════════════════════════════════════
# DYNAMIC LABELS
# ═══════════════════════════════════════════════════════════
func _create_bonus_labels() -> void:
	_medal_label = _make_rtl("+" + str(FLOW.medal_counter), 28, Color.WHITE)
	add_child(_medal_label)

	_no_miss_row = HBoxContainer.new()
	_no_miss_row.clip_contents = false
	_no_miss_row.add_theme_constant_override("separation", 12)
	add_child(_no_miss_row)

	_no_miss_label = _make_rtl("", 20, Color(1.0, 0.92, 0.2))
	_no_miss_label.text = "[wave amp=48 freq=5.0]NO MISS[/wave]"
	_no_miss_row.add_child(_no_miss_label)

	if FLOW.missed:
		_result_label = _make_rtl("FAILED", 20, Color(1.0, 0.28, 0.28))
	else:
		_result_label = _make_rtl("x100000", 20, Color.from_string("5b8de8", Color.WHITE))
	_no_miss_row.add_child(_result_label)


func _position_bonus_labels() -> void:
	var bx := _orig_bell_x
	var by := bell_sprite.position.y
	_medal_label.position = Vector2(bx + medal_label_offset.x,   by + medal_label_offset.y)
	_no_miss_row.position = Vector2(bx + no_miss_label_offset.x, by + no_miss_label_offset.y)


# ═══════════════════════════════════════════════════════════
# STYLE HELPERS
# ═══════════════════════════════════════════════════════════
func _make_rtl(text_content: String, font_size: int, color: Color) -> RichTextLabel:
	var label               := RichTextLabel.new()
	label.bbcode_enabled     = true
	label.fit_content        = true
	label.scroll_active      = false
	label.autowrap_mode      = TextServer.AUTOWRAP_OFF
	label.clip_contents      = false
	label.custom_minimum_size = Vector2(10, 30)
	_apply_rtl_style(label, font_size)
	label.add_theme_color_override("default_color", color)
	label.text = text_content
	return label


func _apply_rtl_style(label: RichTextLabel, font_size: int = 20) -> void:
	var font              := FontVariation.new()
	font.base_font         = _base_font
	font.opentype_features = {"kern": 0, "liga": 0, "calt": 0, "clig": 0}
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_constant_override("outline_size", 20)
	label.add_theme_color_override("outline_color", Color.BLACK)
	label.add_theme_color_override("font_shadow_color", shadow_color)
	label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
	label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
	label.add_theme_constant_override("shadow_outline_size", shadow_size)
