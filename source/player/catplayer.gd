extends CharacterBody2D

@export var sprite: Sprite2D
@export var bomb: PackedScene

@export_category("MOVEMENT")
@export_range(150, 350, 50) var speed: int
@export var screenMargin: int
var direction: Vector2 = Vector2.UP

@export_category("WEAPONS")
@export var normalWeapon: Node2D
@export var heavyWeapon: Node2D
@export var hitbox: Node2D

var playable: bool = false  # Controla si el jugador puede moverse
var go_point: Vector2  # Punto al que debe llegar antes de ser jugable
var canDie: bool = true
var bombed: bool = false

func _ready():
	# Desactivar controles al inicio
	playable = false
	go_point = GAME.goPoint
	
	# Desactivar el arma pesada al inicio
	normalWeapon.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	heavyWeapon.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func _process(_delta):
	if playable:
		movement()
		screen_clamp(get_viewport().get_visible_rect().size)
		if GAME.selected_character == GAME.characters_scenes[0]: big_mode()
		if GAME.selected_character == GAME.characters_scenes[1]: bombing()
		speed = 200 if INPUT.fireHold else 350

		if SCORE.isFever:
			normalWeapon.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
			heavyWeapon.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
		else:
			normalWeapon.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
			heavyWeapon.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	else:
		# Movimiento automático hasta `go_point`
		shield(1.5)
		move_to_go_point()

# Mueve al personaje automáticamente hacia `go_point`
func move_to_go_point():
	var direction_to_point = (go_point - position).normalized()
	velocity = direction_to_point * speed
	move_and_slide()

	# Si el personaje ha llegado al punto de destino, activar jugabilidad
	if position.distance_to(go_point) < 5:  # Umbral de distancia para considerarlo "llegado"
		playable = true

# Limita la posición del personaje a los márgenes de la pantalla
func screen_clamp(screen_size):
	position.x = clamp(position.x, screenMargin, screen_size.x - screenMargin)
	position.y = clamp(position.y, screenMargin, screen_size.y - screenMargin)

# Maneja el movimiento del personaje cuando es jugable
func movement():
	direction = Vector2(INPUT.xAxis, INPUT.yAxis)
	velocity = direction.normalized() * speed
	move_and_slide()

func big_mode():
	if INPUT.bigMode:
		scale = Vector2(5, 5)
		hitbox.scale = Vector2(0.8, 0.8)
		z_index = 6
	else:
		shield(1.5)
		scale = Vector2(1, 1)
		hitbox.scale = Vector2(1, 1)
		z_index = 3

func bombing():
	if INPUT.bigMode and !bombed:
		var bomb_instance = bomb.instantiate()
		bomb_instance.position = Vector2(340, 1000)
		get_tree().current_scene.add_child.call_deferred(bomb_instance)
		bombed = true
		shield(3)
	if !INPUT.bigMode: bombed = false

func shield(duration):  # Duración ajustable (1.5 segundos por defecto)
	canDie = false
	sprite.modulate = Color.RED
	await get_tree().create_timer(duration).timeout  # Espera el tiempo definido
	canDie = true
	sprite.modulate = Color.GREEN

# Detecta si el hurtbox entra en un Area2D
func _on_hurtbox_area_entered(area):
	if area.is_in_group("Ground"): area.get_parent().canShoot = false
	if !INPUT.bigMode and canDie and area.is_in_group("Damage"):
		SCORE.reset()
		GAME.spawn()
		queue_free()

func _on_hurtbox_area_exited(area):
	if area.is_in_group("Ground"): area.get_parent().canShoot = true
