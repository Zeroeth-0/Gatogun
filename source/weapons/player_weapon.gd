extends Node2D

# === CONFIGURACIÓN EXPORTADA ===
@export var bulletScene: PackedScene                                            # Tipo de bala
@export var fireRate: float = 0.05                                              # Cadencia de tiro
@export_range(-20, 20, 5) var deviationAngle: float = 0.0                       # Ángulo de desviación
@export var MAX_BULLETS: int = 3                                                # Balas máximas en pantalla

# === ESTADO INTERNO ===
var canFire: bool = true

# === LOOP PRINCIPAL ===
func _process(_delta: float) -> void:
	var activeBullets = get_tree().get_nodes_in_group("Fire").size()
	var maxBullets = MAX_BULLETS * get_parent().get_child_count()
	
	if INPUT.firing and canFire and activeBullets < maxBullets and not INPUT.fireHold:
		await _fire_burst(INPUT.fireDir)

# === DISPARO EN RÁFAGA ===
func _fire_burst(direction: Vector2) -> void:
	canFire = false
	var delay := fireRate
	
	for i in MAX_BULLETS:
		await get_tree().create_timer(0.05).timeout
		_fire_bullet(direction)
	
	# Si la dirección cambió, ignora el delay de enfriamiento
	if direction != INPUT.fireDir: delay = 0.0
	
	await get_tree().create_timer(delay).timeout
	canFire = true

# === DISPARO INDIVIDUAL ===
func _fire_bullet(direction: Vector2) -> void:
	var bullet = bulletScene.instantiate()
	bullet.position = global_position
	bullet.set_dir(direction, deviationAngle)
	get_tree().current_scene.add_child(bullet)
