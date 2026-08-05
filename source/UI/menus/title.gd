extends Control

@onready var title: Sprite2D = $LogoGatogun
@onready var start: RichTextLabel = $StartText

@export var breathing_enabled: bool = true
@export var breathing_speed: float = 1.2
@export var breathing_amount: float = 0.04
@export var bobbing_enabled: bool = true
@export var bobbing_speed: float = 0.8
@export var bobbing_amount: float = 6.0

var base_scale: Vector2
var base_y: float
var time: float = 0.0
var can_interact: bool = false
var _first_frame: bool = true

func _ready() -> void:
	base_scale = title.scale
	base_y = title.position.y
	
	UIUtils.apply_menu_style(start, 18)
	start.text = "[wave amp=48 freq=5.0]" + start.text + "[/wave]"
	can_interact = true

func _process(delta: float) -> void:
	if not can_interact: return
	time += delta

	if breathing_enabled: title.scale = base_scale * (1.0 + sin(time * breathing_speed * TAU) * breathing_amount)
	if bobbing_enabled: title.position.y = base_y + sin(time * bobbing_speed * TAU) * bobbing_amount

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
