extends Control

const OPTIONS := ["RESUME", "RESTART", "BACK TO TITLE", "SETTINGS", "EXIT"]

@onready var vbox: VBoxContainer = $VBoxContainer
var labels: Array[RichTextLabel] = []
var original_positions: Array[float] = []
var nav: MenuNavigator
var active_tweens: Array[Tween] = []

@export var diagonal_offset: float = 0.0
@export var unselected_alpha: float = 0.75

func _ready() -> void:
	GLOBAL.pause_game()
	vbox.clip_contents = false
	mouse_filter = MOUSE_FILTER_STOP

	for option_text in OPTIONS:
		var label := RichTextLabel.new()
		label.custom_minimum_size = Vector2(400, 30)
		UIUtils.apply_menu_style(label, 20)
		vbox.add_child(label)
		labels.append(label)

	nav = MenuNavigator.new()
	nav.option_count = OPTIONS.size()
	nav.selection_changed.connect(_update_selection)
	nav.confirmed.connect(_on_confirmed)
	nav.cancelled.connect(_resume)
	nav.start_pressed.connect(_resume)
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
	nav.can_interact = true

func _animate_exit(callback: Callable) -> void:
	nav.can_interact = false
	for t in active_tweens: if t and t.is_valid(): t.kill()
	
	UIUtils.animate_list_exit(labels, get_viewport_rect().size.x)
	await get_tree().create_timer((labels.size() - 1) * 0.04 + 0.25).timeout
	callback.call()

func _on_confirmed(index: int) -> void:
	nav.can_interact = false
	await UIUtils.blink_node(labels[index], get_tree())
	match index:
		0: _resume()
		1: _animate_exit(func():
			for node in get_tree().get_nodes_in_group("PauseOverlay"): node.queue_free()
			GLOBAL.resume_game()
			GAME.set_lives()
			await get_tree().process_frame
			FLOW.restart_level())
		2: _animate_exit(func():
			GAME.playing = false
			GLOBAL.resume_game()
			SCORE.reset()
			SCORE.reset_game_score()
			GAME.store()
			GAME.set_lives()
			GLOBAL.change_scene("MENU"))
		4: _animate_exit(func(): GLOBAL.resume_game(); get_tree().quit())
		_: nav.can_interact = true

func _resume() -> void:
	_animate_exit(func(): GLOBAL.resume_game(); queue_free())
