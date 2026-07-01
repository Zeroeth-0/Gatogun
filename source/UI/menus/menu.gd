extends Control

const OPTIONS: Array[String] = ["GAME START", "CARAVAN", "PRACTICE", "LEADERBOARDS", "GALLERY", "SETTINGS", "EXIT"]

@onready var vbox: VBoxContainer = $VBoxContainer
@export var icons: Sprite2D

var labels: Array[RichTextLabel] = []
var original_positions: Array[float] = []
var nav: MenuNavigator
var active_tweens: Array[Tween] = []

@export var diagonal_offset: float = 10.0
@export var unselected_alpha: float = 0.75

var _icons_original_x: float

func _ready() -> void:
	FLOW.isCaravan = false
	FLOW.inCaravan = false
	FLOW._is_first_level = false
	GAME.lives = GAME.liveCount

	if icons:
		_icons_original_x = icons.position.x
		icons.visible = false

	vbox.clip_contents = false
	for option_text in OPTIONS:
		var label := RichTextLabel.new()
		label.custom_minimum_size = Vector2(400, 40)
		UIUtils.apply_menu_style(label, 20)
		vbox.add_child(label)
		labels.append(label)

	nav = MenuNavigator.new()
	nav.option_count = OPTIONS.size()
	nav.selection_changed.connect(_update_selection)
	nav.confirmed.connect(_on_confirmed)
	nav.cancelled.connect(func(): _animate_exit(func(): GLOBAL.change_scene("TITLE")))
	add_child(nav)

	_update_selection(0)
	vbox.modulate.a = 0

	await get_tree().process_frame
	await get_tree().process_frame
	_animate_entry()

func _update_selection(index: int) -> void:
	for i in labels.size():
		if i == index:
			labels[i].modulate = Color.WHITE
			labels[i].text = "[wave amp=48 freq=5.0]" + OPTIONS[i] + "[/wave]"
			if not original_positions.is_empty(): UIUtils.shake_x(labels[i], original_positions[i])
		else:
			labels[i].modulate = Color(0.25, 0.25, 0.25, unselected_alpha)
			labels[i].text = OPTIONS[i]

func _animate_entry() -> void:
	var screen_w := get_viewport_rect().size.x
	original_positions.clear()
	for i in labels.size(): original_positions.append(labels[i].position.x + (i * diagonal_offset))
	
	vbox.modulate.a = 1
	active_tweens = UIUtils.animate_list_entry(labels, original_positions, screen_w)
	
	if icons:
		icons.position.x = -screen_w - 200
		icons.visible = true
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(icons, "position:x", _icons_original_x, 0.40)
		await tw.finished
		
	nav.can_interact = true

func _animate_exit(callback: Callable) -> void:
	nav.can_interact = false
	for t in active_tweens: if t and t.is_valid(): t.kill()
	
	var screen_w := get_viewport_rect().size.x
	UIUtils.animate_list_exit(labels, screen_w)
	
	if icons:
		var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(icons, "position:x", -screen_w - 200, 0.28)

	await get_tree().create_timer((labels.size() - 1) * 0.04 + 0.25).timeout
	callback.call()

func _on_confirmed(index: int) -> void:
	nav.can_interact = false
	await UIUtils.blink_node(labels[index], get_tree())
	match index:
		0: _animate_exit(func(): GLOBAL.raw_change_scene("MODE"))
		1: 
			RANK.DifficultyStyle = RANK.DifficultyEnum.ORIGINAL
			FLOW.isCaravan = true
			GAME.DollStyle = GAME.DollEnum.CARAVAN
			_animate_exit(func(): GLOBAL.raw_change_scene("GATO"))
		6: _animate_exit(func(): get_tree().quit())
		_: nav.can_interact = true # Para los menús no implementados
