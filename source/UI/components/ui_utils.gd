# source/UI/ui_utils.gd
class_name UIUtils
extends RefCounted

const FONT_PATH = "res://fonts/AprilGothicOne-R.ttf"

## Aplica tu estilo estandarizado a cualquier RichTextLabel
static func apply_menu_style(label: RichTextLabel, font_size: int, shadow_color: Color = Color(0, 0, 0, 0.6), shadow_offset: Vector2 = Vector2(2, 2), shadow_size: int = 20, outline_size: int = 20) -> void:
	var font := FontVariation.new()
	font.base_font = load(FONT_PATH) as Font
	font.opentype_features = {"kern": 0, "liga": 0, "calt": 0, "clig": 0}

	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_contents = false
	
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_color_override("outline_color", Color.BLACK)
	label.add_theme_color_override("font_shadow_color", shadow_color)
	label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
	label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
	label.add_theme_constant_override("shadow_outline_size", shadow_size)

## Parpadeo universal para confirmaciones
static func blink_node(node: CanvasItem, tree: SceneTree, count: int = 3, speed: float = 0.07) -> void:
	for i in count:
		node.modulate.a = 0.0
		await tree.create_timer(speed).timeout
		node.modulate.a = 1.0
		await tree.create_timer(speed).timeout

## Temblor lateral para el elemento seleccionado
static func shake_x(node: Control, original_x: float, amount: float = 4.0, duration: float = 0.04) -> void:
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position:x", original_x + amount, duration)
	tween.tween_property(node, "position:x", original_x - amount, duration)
	tween.tween_property(node, "position:x", original_x + amount, duration)
	tween.tween_property(node, "position:x", original_x, duration)

## Transición de entrada estandarizada para listas de menú
static func animate_list_entry(labels: Array[RichTextLabel], original_xs: Array[float], screen_width: float) -> Array[Tween]:
	var tweens: Array[Tween] = []
	for i in labels.size():
		var label = labels[i]
		label.position.x = screen_width + 100
		var tween := label.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(label, "position:x", original_xs[i], 0.35).set_delay(i * 0.05)
		tweens.append(tween)
	return tweens

## Transición de salida estandarizada para listas de menú
static func animate_list_exit(labels: Array[RichTextLabel], screen_width: float) -> void:
	for i in labels.size():
		var label = labels[i]
		var tween := label.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(label, "position:x", screen_width + 100, 0.25).set_delay((labels.size() - 1 - i) * 0.04)
