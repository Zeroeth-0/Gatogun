extends Area2D

@export var speed: float = 200.0
@export var direction: Vector2 = Vector2.DOWN
@export var rotationSpeed: float = 360
@export var sprite: Sprite2D

# Asigna propiedades de dirección y velocidad a la bala
func set_properties(newDirection: Vector2, newSpeed: float) -> void:
	direction = newDirection
	speed = newSpeed

func _process(delta: float) -> void:
	position += direction * speed * delta
	sprite.rotation_degrees -= rotationSpeed * delta
