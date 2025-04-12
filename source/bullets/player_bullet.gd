extends Area2D

# === CONFIGURACIÓN EXPORTADA ===
@export var speed: float = 1000.0                                               # Velocidad en píxeles por segundo
@export var damage: int = 1                                                     # Daño que inflige
@export var lifeTime: float = 10.0                                              # Duración de la bala
@export var isBomb: bool = false                                                # ¿Es bomba?
@export var isFocus: bool = false                                               # ¿Es disparo concentrado?

# === ESTADO INTERNO ===
var direction: Vector2 = Vector2.UP
var deviationAngle: float = 0.0
var deviationRadians: float = 0.0


# === ACTUALIZACIÓN CADA FRAME ===
func _process(delta: float) -> void:
	# Movimiento constante en la dirección asignada
	position += direction * speed * delta
	
	# Vida útil
	lifeTime -= delta
	if lifeTime <= 0:
		queue_free()
		return
	
	# Si es bomba, cancela todas las balas enemigas
	if isBomb:
		for bullet in get_tree().get_nodes_in_group("Enemy Bullet"):
			if bullet.has_method("cancel"): bullet.cancel()

# === INICIALIZACIÓN DE DIRECCIÓN Y ROTACIÓN ===
func set_dir(newDirection: Vector2, devAngle: float) -> void:
	deviationAngle = devAngle
	deviationRadians = deg_to_rad(deviationAngle)
	direction = newDirection.rotated(deviationRadians)
	
	# Rota el nodo para que apunte en la dirección del movimiento
	rotation = direction.angle()

# === COLISIÓN CON ÁREAS ===
func _on_area_entered(area: Node) -> void:
	if area.is_in_group("Enemy") and not isBomb:
		SCORE.increase_combo(damage)
		
		if isFocus: SCORE.keep_fever()
		else: SCORE.increase_fever(damage)
		
		queue_free()

func _on_area_exited(area: Node) -> void:
	if area.is_in_group("Free"): queue_free()
