extends Control

const OPTIONS: Array[String] = ["NOVICE", "ORIGINAL", "MANIAC"]

@onready var vbox: VBoxContainer = $VBoxContainer
var labels: Array[RichTextLabel] = []
var original_positions: Array[float] = []
var nav: MenuNavigator
var active_tweens: Array[Tween] = []

@export var diagonal_offset: float = 0.0
@export var vertical_spacing: int = 80
@export var unselected_alpha: float = 0.75

func _ready() -> void:
	vbox.clip_contents = false
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", vertical_spacing)
	RANK.reset_all()

	for option_text in OPTIONS:
		var label := RichTextLabel.new()
		label.custom_minimum_size = Vector2(400, 50)
		UIUtils.apply_menu_style(label, 30, Color(0,0,0,0.6), Vector2(2,2), 27, 27)
		vbox.add_child(label)
		labels.append(label)

	nav = MenuNavigator.new()
	nav.option_count = OPTIONS.size()
	nav.selection_changed.connect(_update_selection)
	nav.confirmed.connect(_on_confirmed)
	nav.cancelled.connect(func(): _animate_exit(func(): GLOBAL.raw_change_scene("MENU")))
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
			labels[i].text = "[center][wave amp=48 freq=5.0]" + OPTIONS[i] + "[/wave][/center]"
			if not original_positions.is_empty(): UIUtils.shake_x(labels[i], original_positions[i])
		else:
			labels[i].modulate = Color(0.25, 0.25, 0.25, unselected_alpha)
			labels[i].text = "[center]" + OPTIONS[i] + "[/center]"

func _animate_entry() -> void:
	var screen_w := get_viewport_rect().size.x
	original_positions.clear()
	for i in labels.size(): original_positions.append(labels[i].position.x + (i * diagonal_offset))
	
	vbox.modulate.a = 1
	active_tweens = UIUtils.animate_list_entry(labels, original_positions, screen_w)
	nav.can_interact = true

func _animate_exit(callback: Callable) -> void:
	nav.can_interact = false
	for t in active_tweens: if t and t.is_valid(): t.kill()
	
	UIUtils.animate_list_exit(labels, get_viewport_rect().size.x)
	await get_tree().create_timer((labels.size() - 1) * 0.04 + 0.25).timeout
	callback.call()

func _on_confirmed(index: int) -> void:
	nav.can_interact = false
	match index:
		0: RANK.set_difficulty(RANK.DifficultyEnum.NOVICE)
		1: RANK.set_difficulty(RANK.DifficultyEnum.ORIGINAL)
		2: RANK.set_difficulty(RANK.DifficultyEnum.MANIAC)
	
	await UIUtils.blink_node(labels[index], get_tree())
	_animate_exit(func(): GLOBAL.raw_change_scene("GATO"))
