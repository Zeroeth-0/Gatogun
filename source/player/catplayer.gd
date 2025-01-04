extends CharacterBody2D

@export_category("MOVEMENT")
@export_range(150, 350, 50) var speed: int
@export var screenMargin: int
var direction: Vector2 = Vector2.UP

func _process(_delta):
	movement()
	screen_clamp(get_viewport().get_visible_rect().size)
	speed = 200 if INPUT.fireHold else 350

# Limita la posición del personaje a los márgenes de la pantalla
func screen_clamp(screen_size):
	position.x = clamp(position.x, screenMargin, screen_size.x - screenMargin)
	position.y = clamp(position.y, screenMargin, screen_size.y - screenMargin)

# Maneja el movimiento del personaje
func movement():
	direction = Vector2(INPUT.xAxis, INPUT.yAxis)
	velocity = direction.normalized() * speed
	move_and_slide()

# Detecta si el hurtbox entra en un Area2D
func _on_hurtbox_area_entered(area):
	if area.is_in_group("Ground"): area.get_parent().canShoot = false
	if area.is_in_group("Damage"): get_tree().reload_current_scene()

func _on_hurtbox_area_exited(area):
	if area.is_in_group("Ground"): area.get_parent().canShoot = true
