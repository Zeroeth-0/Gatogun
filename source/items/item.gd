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

func _ready() -> void:
	# Lanzamiento inicial con fuerza aleatoria hacia arriba
	velocity = Vector2(0, randf_range(-launchForce * 0.5, -launchForce * 2))
	
	# Esperar antes de activar seguimiento
	await get_tree().create_timer(delayBeforeFollow).timeout
	followingPlayer = true

func _process(delta: float) -> void:
	if followingPlayer: _move_towards_player(delta)
	else:
		# Simula caída con gravedad hasta que empieza a seguir
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
