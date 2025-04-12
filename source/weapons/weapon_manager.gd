extends Node2D

# === CONFIGURACIÓN ===
@export var bulletScene: PackedScene                                            # Tipo de bala
@export var fireRate: float = 0.015                                             # Cadencia de tiro

# === ESTADO INTERNO ===
var cooldown := 0.0
var children: Array = []

func _process(delta: float) -> void:
	cooldown -= delta
	children = get_children()
	
	# Verificamos si todos los hijos están listos para disparar
	var allReady = true
	for child in children:
		if !child.canFire:
			allReady = false
			break
	
	# Se mantiene presionado disparo, cooldown terminado, y todos los hijos pueden disparar
	if INPUT.fireHold and cooldown <= 0.0 and allReady: _fire_burst(Vector2.UP)

# === DISPARO EN RÁFAGA SIMPLE ===
func _fire_burst(direction: Vector2) -> void:
	_fire_bullet(direction)
	cooldown = fireRate

# === DISPARO INDIVIDUAL ===
func _fire_bullet(direction: Vector2) -> void:
	var bullet = bulletScene.instantiate()
	bullet.position = global_position
	bullet.set_dir(direction, 0)  # Sin desviación
	get_tree().current_scene.add_child(bullet)
