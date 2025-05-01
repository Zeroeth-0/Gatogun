extends Area2D

# === ENUM DE TIPOS DE ÍTEMS ===
enum ItemType { MEDAL, POWER }

# === EXPORTABLES CONFIGURABLES ===
@export var itemEnum: ItemType = ItemType.MEDAL                                 # Tipo de item
@export var speed: float = 200.0                                                # Velocidad hacia jugador
@export var grav: float = 800.0                                                 # Gravedad
@export var launchForce: float = 200.0                                          # Fuerza de lanzamiento inicial
@export var delayBeforeFollow: float = 0.7                                      # Tiempo hasta ir a jugador

# === ESTADO INTERNO ===
var velocity: Vector2 = Vector2.ZERO
var followingPlayer: bool = false
var oscillationTimer: float = 0.0
var isCollected := false


func _ready() -> void:
	# Lanzamiento inicial con fuerza aleatoria hacia arriba
	velocity = Vector2(0, randf_range(-launchForce * 0.5, -launchForce * 2))
	
	# Esperar antes de activar seguimiento
	await get_tree().create_timer(delayBeforeFollow).timeout
	followingPlayer = true

func _process(delta: float) -> void:
		# Movimiento medalla
	if followingPlayer:
		if itemEnum == ItemType.POWER:
			# Movimiento potenciador
			oscillationTimer += delta
			var amplitude = 160.0  # Ancho de la oscilación
			var frequency = 5.0   # Frecuencia de la oscilación
			var offsetX = sin(oscillationTimer * frequency) * amplitude
			var velocityY = grav / 5
			position += Vector2(offsetX, velocityY) * delta
		else: _move_towards_player(delta) # Movimiento medallacccccccccccccccd
	else:
		velocity.y += grav * delta
		position += velocity * delta

func _move_towards_player(delta: float) -> void:
	var playerPos = GAME.get_player()
	var direction = (playerPos - position).normalized()
	position += direction * speed * delta

func _on_area_entered(area: Node) -> void:
	if isCollected: return
	if area.is_in_group("Collect"):
		isCollected = true  # Bloquea múltiples ejecuciones
		match itemEnum:
			ItemType.MEDAL:
				SCORE.add_score(SCORE.medalChain)
				if SCORE.medalCountdown > 0: SCORE.increase_medal_chain()
			ItemType.POWER:
				if GAME.optionCounter < 1:
					GAME.optionCounter += 1
					GAME.rOptActive = true
				elif GAME.optionCounter < 2:
					GAME.optionCounter += 1
					GAME.lOptActive = true
				elif GAME.weaponLvl < 3 and GAME.optionCounter >= 2: GAME.weaponLvl += 1
				else: pass # Bonus de puntos
		queue_free()
