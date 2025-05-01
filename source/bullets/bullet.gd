extends Area2D

# === EXPORTS ===
@export var sprite: Sprite2D                                                    # Aspecto de la bala
@export var revenge: bool = false                                               # ¿Devuelta al morir?
@export var medal: PackedScene = preload("res://scenes/items/medal.tscn")       # Item que recompensa

# === PROPIEDADES INTERNAS ===
var speed := 250
var direction := Vector2.ZERO
var rotationSpeed := 360
var revHealth := 10

# === CONFIGURACIÓN DE DIRECCIÓN ===
enum DirectionType { NONE, AIM, GRAVITY, LEFT, RIGHT, RANDOM }
var directionType := DirectionType.NONE
var gravIntensity := 0.0
var deviationAngle := 0
var dirStartTime := 0.0
var dirDuration := 1.0

# === CONFIGURACIÓN DE VELOCIDAD TEMPORAL ===
var modifySpeed := false
var fstNewSpeed := speed
var fstStartTime := 0.0
var sndNewSpeed := speed
var sndStartTime := 0.0

# === ESTADO INTERNO ===
var elapsedTime := 0.0
var velocity := Vector2.ZERO
var useGravity := false
var acceleration := Vector2.ZERO
var isCancelled := false


# === FUNCIONES PRINCIPALES ===

func _ready() -> void:
	# Si está en modo "venganza", apunta al jugador directamente
	if revenge: direction = (GAME.get_player() - position).normalized()
	
	velocity = direction * speed
	sndStartTime += fstStartTime

func _process(delta: float) -> void:
	elapsedTime += delta
	
	# Actualiza velocidad base o con gravedad
	velocity = direction * speed if !useGravity else velocity
	if useGravity: _apply_gravity()
	
	_update_direction(delta)
	if modifySpeed: _update_speed()
	
	# Movimiento de la bala
	if useGravity: velocity += acceleration * delta
	position += velocity * delta
	sprite.rotation_degrees -= rotationSpeed * delta

# === CONFIGURACIÓN EXTERNA ===

# Asigna dirección y velocidad inicial
func set_properties(newDirection: Vector2, newSpeed: int) -> void:
	direction = newDirection
	speed = newSpeed

# Configura el comportamiento de dirección con el tiempo
func modify_direction(newType: DirectionType, newGravIntensity: float, newDeviationAngle: int,
					  newStartTime: float, newDuration: float) -> void:
	directionType = newType
	gravIntensity = newGravIntensity
	deviationAngle = newDeviationAngle
	dirStartTime = newStartTime
	dirDuration = newDuration

# Configura los cambios de velocidad en dos fases
func modify_speed(firstSpeed: int, firstStart: float, secondSpeed: int, secondStart: float) -> void:
	modifySpeed = true
	fstNewSpeed = firstSpeed
	fstStartTime = firstStart
	sndNewSpeed = secondSpeed
	sndStartTime = secondStart

# === LÓGICA DE COMPORTAMIENTO ===

# Aplica fuerza gravitatoria si está habilitada
func _apply_gravity() -> void:
	acceleration.y = gravity * gravIntensity

# Actualiza la dirección en función del tipo de comportamiento asignado
func _update_direction(delta: float) -> void:
	if elapsedTime < dirStartTime or elapsedTime > dirStartTime + dirDuration: return
	
	match directionType:
		DirectionType.AIM: direction = (GAME.get_player() - global_position).normalized()
		DirectionType.GRAVITY: useGravity = true
		DirectionType.LEFT: direction = direction.rotated(deg_to_rad(deviationAngle) * delta)
		DirectionType.RIGHT: direction = direction.rotated(deg_to_rad(-deviationAngle) * delta)
		DirectionType.RANDOM:
			var angle = randf_range(-deviationAngle, deviationAngle)
			direction = direction.rotated(deg_to_rad(angle) * delta)

# Aplica las fases de velocidad si están activas
func _update_speed() -> void:
	if elapsedTime >= fstStartTime and elapsedTime <= sndStartTime: speed = fstNewSpeed
	elif elapsedTime >= sndStartTime: speed = sndNewSpeed

# === INTERACCIÓN Y FINALIZACIÓN ===

# Muestra la medalla y elimina la bala
func _cancel() -> void:
	var item = medal.instantiate()
	get_tree().current_scene.call_deferred("add_child", item)
	item.position = global_position
	queue_free()

# Al salir de un área, si es del grupo "Free", elimina la bala
func _on_area_exited(area) -> void:
	if area.is_in_group("Free"): queue_free()

# Al entrar en contacto con fuego, reduce vida o destruye con condiciones
func _on_area_entered(area) -> void:
	if area.is_in_group("Fire") and revenge:
		revHealth -= 1
		if revHealth <= 0 and not isCancelled:
			isCancelled = true  # Bloquea ejecuciones futuras
			var playerPos = GAME.get_player()
			if position.distance_to(playerPos) < 200 or SCORE.medalCountdown >0: _cancel()
			else: queue_free()
