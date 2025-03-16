extends Area2D

# Variables configurables
@export var speed: float = 1000.0 # Velocidad en píxeles por segundo
@export var damage: int = 1
@export var lifeTime: float = 10.0
@export var isBomb: bool = false
var direction: Vector2 = Vector2(0, -1)
var deviationAngle: float = 0.0 # Desviación en grados (0, 30 o -30)

# Convertir la desviación a radianes
var deviationRadians: float = 0.0

# Llamado en cada cuadro. 'delta' es el tiempo transcurrido desde el cuadro anterior.
func _process(delta: float):
	# Mover el nodo en la dirección calculada
	position += direction * speed * delta
	
	lifeTime -= delta
	if lifeTime <= 0: queue_free()

func set_dir(newDir, devAngle):
	deviationAngle = devAngle
	deviationRadians = deg_to_rad(deviationAngle)
	direction = newDir.rotated(deviationRadians)
	
	# Rotar el nodo para que apunte en la dirección inicial
	rotation = direction.angle()

func _on_area_entered(area):
	if area.is_in_group("Enemy") and !isBomb:
		SCORE.increase_combo(damage)
		queue_free()

func _on_area_exited(area):
	if area.is_in_group("Free"): queue_free()
