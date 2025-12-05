extends Area2D

# === EXPORTABLES CONFIGURABLES ===
@export var speed: float = 200.0                                                # Velocidad hacia jugador
@export var grav: float = 800.0                                                 # Gravedad
@export var launchForce: float = 200.0                                          # Fuerza de lanzamiento inicial
@export var delayBeforeFollow: float = 0.7                                      # Tiempo hasta ir a jugador

# === ESTADO INTERNO ===
var velocity: Vector2 = Vector2.ZERO
var followingPlayer: bool = false
var isCollected := false
var powerupDir := Vector2(1, 1).normalized()
var powerUpFollowPlayer: bool = false
var randSign: int = 1

# === CONSTANTES ===
const POWERUP_MOVE_SPEED: float = 250
const POWERUP_FOLLOW_SPEED: float = 400
const ITEM_HALF_SIZE: float = 16

func _ready() -> void:
	# Lanzamiento inicial con fuerza aleatoria hacia arriba
	velocity = Vector2(0, randf_range(-launchForce * 0.5, -launchForce * 2))
	
	randSign = -1 if randf() > 0.5 else 1
	
	# Esperar antes de activar seguimiento
	await get_tree().create_timer(delayBeforeFollow, false).timeout
	followingPlayer = true

func _move_medal(delta):
	if followingPlayer: _move_towards_player(delta)
	else:
		velocity.y += grav * delta
		position += velocity * delta

func _move_powerup(delta):
	if powerUpFollowPlayer:
		speed = POWERUP_FOLLOW_SPEED
		_move_towards_player(delta)
	else:
		if velocity.y < POWERUP_MOVE_SPEED:
			velocity.y += grav * delta
		else: position.x += sin((Time.get_ticks_msec() / 1000.0) * TAU * 1) * delta * 100 * randSign
		position += velocity * delta

func _move_towards_player(delta: float) -> void:
	var playerPos = GAME.get_player()
	var direction = (playerPos - position).normalized()
	position += direction * speed * delta

# === RECOGER BASE ===
#func _on_area_entered(area: Node) -> void:
#	if isCollected: return
#	if area.is_in_group("Collect"):
#		isCollected = true  # Bloquea múltiples ejecuciones
#		queue_free()
