extends Node2D

# === CONFIGURACIÓN EXPORTADA ===
@export var bulletScene: PackedScene                                            # Tipo de bala
@export var fireRate: float = 0.05                                              # Cadencia de tiro
@export_range(-20, 20, 5) var deviationAngle: float = 0.0                       # Ángulo de desviación
@export var MAX_BULLETS: int = 3                                                # Balas máximas en pantalla
@export_range(1, 8, 1) var weaponLvl: int = 1                                   # Cantidad de balas paralelas
@export var targetPos: Vector2 = Vector2.ZERO                                   # Objetivo a seguir
@export_range(0, 10, 1) var followDelay: int = 0                                # Retardo del seguimiento

# === ESTADO INTERNO ===
var canFire: bool = true 
var prevParentPos: Vector2

func _ready():
	prevParentPos = get_parent().global_position

# === LOOP PRINCIPAL ===
func _process(delta) -> void:
	var activeBullets = get_tree().get_nodes_in_group("Fire").size()
	var maxBullets = MAX_BULLETS * get_parent().get_child_count()
	
	if INPUT.firing and canFire and activeBullets < maxBullets and not INPUT.fireHold:
		await _fire_burst(INPUT.fireDir)
	
	# Comportamiento options
	if followDelay > 0: options(delta)

func options(delta):
	var parentDelta = get_parent().global_position - prevParentPos
	global_position -= parentDelta  # Cancelamos el movimiento del padre
	prevParentPos = get_parent().global_position
	position = position.lerp(targetPos, followDelay * delta)

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
	var orthogonal = direction.orthogonal().normalized()
	var spacing = 30  # Espaciado entre balas, ajústalo si querés
	
	for i in weaponLvl:
		var bullet = bulletScene.instantiate()
		
		# Centrar el patrón (offset va de -n/2 a +n/2)
		var offset = (i - (weaponLvl - 1) / 2.0) * spacing
		bullet.position = global_position + orthogonal * offset
		
		bullet.set_dir(direction, deviationAngle)
		get_tree().current_scene.add_child(bullet)
