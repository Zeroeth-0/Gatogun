extends Sprite2D

# === BREATHING (escala) ===
@export var breathing_enabled: bool = true
@export var breathing_speed: float = 1.2
@export var breathing_amount: float = 0.04

# === BOBBING (flotación vertical) ===
@export var bobbing_enabled: bool = true
@export var bobbing_speed: float = 0.8
@export var bobbing_amount: float = 6.0

var base_scale: Vector2
var time: float = 0.0
var base_y: float

func _ready():
	base_scale = scale
	base_y = position.y

func _process(delta):
	time += delta

	if breathing_enabled:
		var breath := 1.0 + sin(time * breathing_speed * TAU) * breathing_amount
		scale = base_scale * breath

	if bobbing_enabled:
		position.y = base_y + sin(time * bobbing_speed * TAU) * bobbing_amount
