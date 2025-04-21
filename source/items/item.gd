extends Area2D

# === ENUM DE TIPOS DE ÍTEMS ===
enum ItemType { MEDAL, OTHER }

# === EXPORTABLES CONFIGURABLES ===
@export var itemEnum: ItemType = ItemType.MEDAL                                 # Tipo de item
@export var speed: float = 200.0                                                # Velocidad hacia jugador
@export var grav: float = 800.0                                                 # Gravedad
@export var launchForce: float = 200.0                                          # Fuerza de lanzamiento inicial
@export var delayBeforeFollow: float = 0.7                                      # Tiempo hasta ir a jugador

# === ESTADO INTERNO ===
var velocity: Vector2 = Vector2.ZERO
var followingPlayer: bool = false
var oscillationTimer: float = 0.0                                               # Contador movimiento sinusoidal

func _ready() -> void:
	# Lanzamiento inicial con fuerza aleatoria hacia arriba
	velocity = Vector2(0, randf_range(-launchForce * 0.5, -launchForce * 2))
	
	# Esperar antes de activar seguimiento
	await get_tree().create_timer(delayBeforeFollow).timeout
	followingPlayer = true

func _process(delta: float) -> void:
	if itemEnum == ItemType.OTHER:
		# Movimiento sinusoidal hacia abajo
		oscillationTimer += delta
		var amplitude = 160.0  # Ancho de la oscilación
		var frequency = 5.0   # Frecuencia de la oscilación
		var offsetX = sin(oscillationTimer * frequency) * amplitude
		var velocityY = grav / 5
		position += Vector2(offsetX, velocityY) * delta
	else:
		# Movimiento medalla
		if followingPlayer: _move_towards_player(delta)
		else:
			velocity.y += grav * delta
			position += velocity * delta

func _move_towards_player(delta: float) -> void:
	var playerPos = GAME.get_player()
	var direction = (playerPos - position).normalized()
	position += direction * speed * delta

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("Collect"):
		SCORE.add_score(SCORE.combo / 2)
		queue_free()
