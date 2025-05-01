extends Area2D

# === CONFIGURACIÓN EXPORTADA ===
@export var speed: float = 1000.0                                               # Velocidad en píxeles por segundo
@export var damage: int = 1                                                     # Daño que inflige
@export var lifeTime: float = 10.0                                              # Duración de la bala
@export var isBomb: bool = false                                                # ¿Es bomba?
@export var isFocus: bool = false                                               # ¿Es disparo concentrado?
@export var isFollow: bool = false                                              # ¿Persigue al enemigo?
@export var isWide: bool = false                                                # ¿Es disparo ancho?

# === ESTADO INTERNO ===
var direction: Vector2 = Vector2.UP
var deviationAngle: float = 0.0
var deviationRadians: float = 0.0

# === ACTUALIZACIÓN CADA FRAME ===
func _process(delta: float) -> void:
	if isFollow: _update_follow_direction(delta)
	
	position += direction * speed * delta
	
	lifeTime -= delta
	if lifeTime <= 0:
		queue_free()
		return
	
	if isBomb:
		for bullet in get_tree().get_nodes_in_group("Enemy Bullet"):
			if bullet.has_method("cancel"): bullet.cancel()

# === INICIALIZACIÓN ===
func _ready() -> void:
	if isFocus:
		var fullScale := 0.5 + (GAME.weaponLvl * 0.25)
		damage = GAME.weaponLvl + 1
		scale = Vector2(fullScale, fullScale)

# === CONFIGURAR DIRECCIÓN INICIAL ===
func set_dir(newDirection: Vector2, devAngle: float) -> void:
	deviationAngle = devAngle
	deviationRadians = deg_to_rad(deviationAngle)
	direction = newDirection.rotated(deviationRadians)
	rotation = direction.angle()

# === ACTUALIZAR DIRECCIÓN SI isFollow ===
func _update_follow_direction(delta: float) -> void:
	var target = _get_closest_enemy()
	if target == null: return
	
	var toTarget = (target.global_position - global_position).normalized()
	var turnRate = 10.0  # Cuanto más alto, más rápido gira el misil
	# Interpolamos suavemente entre la dirección actual y la nueva
	direction = direction.lerp(toTarget, turnRate * delta).normalized()
	rotation = direction.angle()

# === OBTENER ENEMIGO MÁS CERCANO ===
func _get_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var closest
	var minDist := INF
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < minDist:
			minDist = dist
			closest = enemy
	return closest

# === COLISIONES ===
func _on_area_entered(area: Node) -> void:
	if area.is_in_group("Enemy") and not isBomb:
		SCORE.increase_combo(damage)
		if INPUT.fireHold: SCORE.keep_fever()
		else: SCORE.increase_fever(damage)
		
		queue_free()

func _on_area_exited(area: Node) -> void:
	if area.is_in_group("Free"): queue_free()
