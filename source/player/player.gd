extends CharacterBody2D

# === EXPORTS GENERALES ===
@export var sprite: Sprite2D                                                    # Aspecto del jugador
@export var bomb: PackedScene                                                   # Bomba
@export var hitbox: Node2D                                                      # Colisión

# === MOVIMIENTO ===
@export_category("MOVEMENT")
@export_range(150, 350, 50) var speed: int                                      # Velocidad de movimiento
@export var screenMargin: int                                                   # Bordes de la pantalla
var direction := Vector2.UP                                                     # Dirección de movimiento

# === ESTADO INTERNO ===
var playable := false
var goPoint: Vector2
var canDie := true

# === INICIO ===
func _ready() -> void:
	playable = false
	goPoint = GAME.goPoint

# === LOOP PRINCIPAL ===
func _process(_delta: float) -> void:
	if playable:
		_handle_movement()
		_clamp_to_screen(get_viewport().get_visible_rect().size)
		_handle_bombing()
		speed = 150 if INPUT.fireHold else 350
	else:
		# Movimiento automático antes de habilitar control
		activate_shield(2.5)
		_auto_move_to_go_point()

# === MOVIMIENTO PRE-JUGABLE ===
func _auto_move_to_go_point() -> void:
	var toTarget = (goPoint - position).normalized()
	velocity = toTarget * speed
	move_and_slide()
	
	if position.distance_to(goPoint) < 5: playable = true

# === MOVIMIENTO MANUAL ===
func _handle_movement() -> void:
	direction = Vector2(INPUT.xAxis, INPUT.yAxis)
	velocity = direction.normalized() * speed
	move_and_slide()

# === BOMBA ===
func _handle_bombing() -> void:
	if INPUT.bombing:
		var bombInstance = bomb.instantiate()
		bombInstance.position = Vector2(340, 1000)
		get_tree().current_scene.add_child.call_deferred(bombInstance)
		activate_shield(3)

# === ESCUDO TEMPORAL ===
func activate_shield(duration: float) -> void:
	canDie = false
	sprite.modulate = Color.RED
	await get_tree().create_timer(duration).timeout
	canDie = true
	sprite.modulate = Color.GREEN

# === CLAMP A PANTALLA ===
func _clamp_to_screen(screenSize: Vector2) -> void:
	position.x = clamp(position.x, screenMargin, screenSize.x - screenMargin)
	position.y = clamp(position.y, screenMargin, screenSize.y - screenMargin)

# === COLISIONES ===
func _on_hurtbox_area_entered(area: Node) -> void:
	if canDie and area.is_in_group("Damage"):
		GAME.lives -= 0.5
		SCORE.reset()
		GAME.spawn()
		queue_free()

func _on_hurtbox_area_exited(area: Node) -> void:
	if area.is_in_group("Ground"): area.get_parent().canShoot = true
