extends CharacterBody2D

# === ESTILOS ===
enum StyleEnum { SPEED, STRONG, NEWBIE }

# === EXPORTS GENERALES ===
@export var DollStyle: StyleEnum = StyleEnum.SPEED
@export var sprite: Sprite2D                                                    # Aspecto del jugador
@export var bomb: PackedScene                                                   # Bomba
@export var hitbox: Node2D                                                      # Colisión

# === MOVIMIENTO ===
@export_category("MOVEMENT")
@export_range(150, 400, 50) var speed: int                                      # Velocidad de movimiento
@export var screenMargin: int                                                   # Bordes de la pantalla
var direction := Vector2.UP                                                     # Dirección de movimiento

# === ESTADO INTERNO ===
var playable := false
var goPoint: Vector2
var canDie := true
var shielded = false
var maxBombs = 4
var bombCount = 2

# === INICIO ===
func _ready() -> void:
	playable = false
	goPoint = GAME.goPoint
	
	match DollStyle:
		StyleEnum.SPEED:
			maxBombs = 4
			bombCount = 2
		StyleEnum.STRONG:
			WEAPON.lvl_up("MAX")
			maxBombs = 2
			bombCount = 1
		StyleEnum.NEWBIE:
			maxBombs = 6
			bombCount = 3

# === LOOP PRINCIPAL ===
func _process(_delta: float) -> void:
	if playable:
		_handle_movement()
		_clamp_to_screen(get_viewport().get_visible_rect().size)
		if Input.is_action_just_pressed("B") and GAME.bombCount > 0 and canDie: _handle_bombing()
		if DollStyle == StyleEnum.SPEED: speed = 150 if INPUT.fireHold else 350
		else: speed = 150 if INPUT.fireHold else 300
	else:
		# Movimiento automático antes de habilitar control
		if not shielded:
			shielded = true
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
	var bombInstance = bomb.instantiate()
	bombInstance.position = Vector2(340, 1000)
	get_tree().current_scene.add_child.call_deferred(bombInstance)
	bombCount -= 1
	for bullet in get_tree().get_nodes_in_group("Fire"): bullet.queue_free()
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
		if DollStyle == StyleEnum.NEWBIE and GAME.bombCount > 0: _handle_bombing()
		else:
			get_parent().lives -= 1
			GAME.store(global_position, false)
			queue_free()
	
func _on_hurtbox_area_exited(area: Node) -> void: # Enemy cutoff
	if area.is_in_group("Ground"): area.get_parent().canShoot = true
