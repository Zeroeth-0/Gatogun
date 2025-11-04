extends Area2D

# === TIPOS DE ITEM ===
enum ItemType { MEDAL, POWERUP, MAXPOWERUP, BOMB, ONEUP }

# === EXPORTABLES CONFIGURABLES ===
@export var itemEnum: ItemType = ItemType.MEDAL                                 # Tipo de item
@export var speed: float = 200.0                                                # Velocidad hacia jugador
@export var grav: float = 800.0                                                 # Gravedad
@export var launchForce: float = 200.0                                          # Fuerza de lanzamiento inicial
@export var delayBeforeFollow: float = 0.7                                      # Tiempo hasta ir a jugador
@export var medal_label: PackedScene = preload("res://scenes/UI/medal_val_label.tscn")              # Etiqueta de pts
@export var isMaxPowerUp: bool = false

# === ESTADO INTERNO ===
var velocity: Vector2 = Vector2.ZERO
var followingPlayer: bool = false
var oscillationTimer: float = 0.0
var isCollected := false
var powerupDir := Vector2(1, 1).normalized()
var powerUpFollowPlayer: bool = false

func _ready() -> void:
	# Lanzamiento inicial con fuerza aleatoria hacia arriba
	velocity = Vector2(0, randf_range(-launchForce * 0.5, -launchForce * 2))
	
	# Esperar antes de activar seguimiento
	await get_tree().create_timer(delayBeforeFollow).timeout
	followingPlayer = true

func _process(delta: float) -> void:
	match itemEnum:
		ItemType.MEDAL: _move_medal(delta) # Movimiento medalla
		_: _move_powerup(delta) # Movimiento potenciador

func _move_medal(delta):
		if followingPlayer: _move_towards_player(delta)
		else:
			velocity.y += grav * delta
			position += velocity * delta

func _move_powerup(delta):
	var moveSpeed := 150.0
	if !powerUpFollowPlayer: position += powerupDir * moveSpeed * delta

	# Obtener los límites de la pantalla
	var screenSize := get_viewport().get_visible_rect().size
	var halfSize := 16

	# Revisar colisiones con los bordes de la pantalla
	if position.x - halfSize <= 0 or position.x + halfSize >= screenSize.x:
		powerupDir.x *= -1
	if position.y - halfSize <= 0 or position.y + halfSize >= screenSize.y:
		powerupDir.y *= -1
	
	if GAME.get_player().y < 250: powerUpFollowPlayer = true
	if powerUpFollowPlayer:
		speed = 400
		_move_towards_player(delta)

func _show_label(scoreVal):
		var label = medal_label.instantiate()
		get_tree().current_scene.add_child(label)
		label.set_val(scoreVal)
		label.global_position = global_position

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
				GAME.innerMedalChain += 1
				SCORE.increase_mult()
			ItemType.POWERUP: WEAPON.lvl_up("ALL")
			ItemType.MAXPOWERUP: WEAPON.lvl_up("MAX")
			ItemType.BOMB: if GAME.bombCount < 6: GAME.bombCount += 1
			ItemType.ONEUP: if GAME.lives < 6: GAME.lives += 1
		queue_free()
