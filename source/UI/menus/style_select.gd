extends Control

const GATOS: Array[Dictionary] = [{"name": "ZEBE", "style": "DAMAGE"}, {"name": "FUKU", "style": "RANGE"}, {"name": "SERGIO", "style": "CLASSIC"}]
const DOLLS: Array[Dictionary] = [{"name": "NOEL", "style": "STRONG"}, {"name": "ACTEA", "style": "SPEED"}, {"name": "PIRU", "style": "NEWBIE"}]

enum SelectEnum { GATO, DOLL }
@export var SelectStyle: SelectEnum = SelectEnum.GATO

@onready var cards: Array[VBoxContainer] = []
var STYLES: Array[Dictionary]
var nav: MenuNavigator
var active_tweens: Array[Tween] = []

@export var card_spacing: float = 200.0
@export var back_card_y_offset: float = 60.0
@export var back_card_scale: float = 0.85
@export var center_offset_x: float = -65.0
@export var center_offset_y: float = -50.0
@export var animation_speed: float = 0.15
@export var unselected_alpha: float = 0.75

func _ready() -> void:
	STYLES = GATOS if SelectStyle == SelectEnum.GATO else DOLLS

	for i in range(3):
		var vbox: VBoxContainer = get_child(i + 1)
		cards.append(vbox)
		var name_label: RichTextLabel = vbox.get_child(1)
		UIUtils.apply_menu_style(name_label, 15, Color(0,0,0,0.6), Vector2(2,2), 13, 13)
		name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_label.text = "[center]" + STYLES[i].name + "[/center]"
		vbox.modulate.a = 0

	nav = MenuNavigator.new()
	nav.option_count = STYLES.size()
	nav.is_horizontal = true
	nav.selected = 1 # Seleccionado del medio por defecto
	nav.selection_changed.connect(func(_idx): _update_selection())
	nav.confirmed.connect(_on_confirmed)
	nav.cancelled.connect(_go_back)
	add_child(nav)

	await get_tree().process_frame
	await get_tree().process_frame

	for card in cards:
		card.pivot_offset = card.size / 2
		card.scale = Vector2(2.0, 2.0)

	_update_selection(false)
	_animate_entry()

func _animate_entry() -> void:
	var final_positions: Array[Vector2] = []
	for card in cards:
		final_positions.append(card.position)
		card.position.x = GAME.CENTER.x + 600

	for i in cards.size():
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
		tween.tween_property(cards[i], "position:x", final_positions[i].x, 0.4).set_delay(i * 0.1)
		tween.tween_property(cards[i], "modulate:a", 1.0, 0.3).set_delay(i * 0.1)

	await get_tree().create_timer((cards.size() - 1) * 0.1 + 0.4).timeout
	nav.can_interact = true

func _update_selection(animate: bool = true) -> void:
	if animate: for t in active_tweens: if t and t.is_valid(): t.kill()
	active_tweens.clear()

	for i in cards.size():
		var card := cards[i]
		var offset := _get_card_offset(i)
		var is_center := (offset == 0)

		var target_scale_val := 2.0 if is_center else (2.0 * back_card_scale)
		var target_scale := Vector2(target_scale_val, target_scale_val)
		var target_x := GAME.CENTER.x + (offset * card_spacing) + center_offset_x
		var target_y := GAME.CENTER.y + center_offset_y + (0.0 if is_center else back_card_y_offset)

		card.z_index = 100 if is_center else 10 + offset
		var icon: TextureRect = card.get_child(0)
		var name_label: RichTextLabel = card.get_child(1)
		var color := Color.WHITE if is_center else Color(0.25, 0.25, 0.25, unselected_alpha)

		name_label.text = "[center]" + ("[wave amp=48 freq=5.0]" if is_center else "") + STYLES[i].name + ("[/wave]" if is_center else "") + "[/center]"

		if animate:
			var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel(true)
			tw.tween_property(card, "position", Vector2(target_x, target_y), animation_speed)
			tw.tween_property(card, "scale", target_scale, animation_speed)
			tw.tween_property(icon, "modulate", color, animation_speed * 0.66)
			tw.tween_property(name_label, "modulate", color, animation_speed * 0.66)
			active_tweens.append(tw)
		else:
			card.position = Vector2(target_x, target_y)
			card.scale = target_scale
			icon.modulate = color
			name_label.modulate = color

func _get_card_offset(card_index: int) -> int:
	var direct := card_index - nav.selected
	if direct == 2: return -1
	elif direct == -2: return 1
	return direct

func _animate_exit(callback: Callable) -> void:
	nav.can_interact = false
	for t in active_tweens: if t and t.is_valid(): t.kill()
	
	for card in cards:
		var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC).set_parallel(true)
		tw.tween_property(card, "position:x", GAME.CENTER.x + 600, 0.25)
		tw.tween_property(card, "modulate:a", 0.0, 0.2)
	
	await get_tree().create_timer(0.25).timeout
	callback.call()

func _on_confirmed(_index: int) -> void:
	nav.can_interact = false
	var card := cards[nav.selected]
	var tw = create_tween().set_loops(4)
	tw.tween_property(card, "modulate:a", 0.0, 0.08)
	tw.tween_property(card, "modulate:a", 1.0, 0.08)
	await tw.finished
	
	var chosenStyle = STYLES[nav.selected].style
	_animate_exit(func():
		if SelectStyle == SelectEnum.GATO:
			GAME.set_gato(chosenStyle)
			if FLOW.isCaravan:
				FLOW.inCaravan = true
				FLOW.begin_caravan()
			else: GLOBAL.raw_change_scene("DOLL")
		else:
			GAME.set_doll(chosenStyle)
			FLOW.begin_game())

func _go_back() -> void:
	_animate_exit(func():
		if SelectStyle == SelectEnum.GATO:
			GLOBAL.raw_change_scene("MENU") if FLOW.isCaravan else GLOBAL.raw_change_scene("MODE")
		else: GLOBAL.raw_change_scene("GATO"))
