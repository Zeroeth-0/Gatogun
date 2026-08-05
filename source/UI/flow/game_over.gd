extends Control

@onready var title: RichTextLabel = $Title
@onready var start: RichTextLabel = $Start

var can_interact: bool = false
var _first_frame: bool = true

func _ready() -> void:
	UIUtils.apply_menu_style(title, 36)
	UIUtils.apply_menu_style(start, 18)
	title.text = "[wave amp=48 freq=5.0]GAME OVER[/wave]"
	start.text = "[wave amp=48 freq=5.0]PUSH SHOOT BUTTON[/wave]"
	can_interact = true

func _process(_delta: float) -> void:
	if not can_interact: return
	if not _first_frame and (Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A") or Input.is_action_just_pressed("Start")):
		_confirm()
	_first_frame = false

func _confirm() -> void:
	can_interact = false
	await UIUtils.blink_node(start, get_tree())
	
	var sw := get_viewport_rect().size.x
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC).set_parallel(true)
	tw.tween_property(title, "position:x", sw + 200, 0.35)
	tw.tween_property(start, "position:x", sw + 200, 0.35).set_delay(0.05)
	await tw.finished
	
	GLOBAL.change_scene("MENU")
