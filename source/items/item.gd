extends Area2D

# === ENUM DE TIPOS DE ÍTEMS ===
enum ItemType { MEDAL}

# === EXPORTABLES CONFIGURABLES ===
@export var itemEnum: ItemType = ItemType.MEDAL                                 # Tipo de item
@export var speed: float = 200.0                                                # Velocidad hacia jugador
@export var grav: float = 800.0                                                 # Gravedad
@export var launchForce: float = 200.0                                          # Fuerza de lanzamiento inicial
@export var delayBeforeFollow: float = 0.7                                      # Tiempo hasta ir a jugador
@export var medal_label: PackedScene = preload("res://scenes/UI/medal_val_label.tscn")              # Etiqueta de pts

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
	if followingPlayer: _move_towards_player(delta)
	else:
		velocity.y += grav * delta
		position += velocity * delta

func _show_label(scoreVal):
		var label = medal_label.instantiate()
		get_tree().current_scene.add_child(label)
		label.set_val(scoreVal)
		label.global_position = global_position

func _move_towards_player(delta: float) -> void:
	var playerPos = GAME.get_player()
	var direction = (playerPos - position).normalized()
	position += direction * speed * delta

func _handle_power_up():
	if _current_medal_level() == 1 and GAME.optionCounter < 1:
		GAME.optionCounter += 1
		GAME.rOptActive = true
	elif _current_medal_level() == 2 and GAME.optionCounter < 2:
		GAME.optionCounter += 1
		GAME.lOptActive = true
	elif GAME.weaponLvl < 3 and GAME.optionCounter >= 2:
		match _current_medal_level():
			3: GAME.weaponLvl = 2.0
			4: GAME.weaponLvl = 3.0

func _current_medal_level():
	if GAME.innerMedalChain >= 64: return 4
	elif GAME.innerMedalChain >= 32: return 3
	elif GAME.innerMedalChain >= 16: return 2
	elif GAME.innerMedalChain >= 8: return 1
	else: return 0

func _on_area_entered(area: Node) -> void:
	if isCollected: return
	if area.is_in_group("Collect"):
		isCollected = true  # Bloquea múltiples ejecuciones
		if itemEnum == ItemType.MEDAL:
			GAME.innerMedalChain += 1
			SCORE.increase_mult()
			_handle_power_up()
		queue_free()
