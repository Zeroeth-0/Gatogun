extends Node2D

# === CONFIGURACIÓN EXPORTADA ===
@export var bulletScene: PackedScene                                            # Tipo de bala
@export var optFocusBullet: PackedScene                                         # Bala options concentrado
@export var fireRate: float = 0.05                                              # Cadencia de tiro
@export_range(-20, 20, 5) var deviationAngle: float = 0.0                       # Ángulo de desviación
@export var MAX_BULLETS: int = 3                                                # Balas máximas en pantalla
@export_range(0, 3, 1) var baseLvl: int = 1                                     # Cantidad de balas paralelas
@export var targetPos: Vector2 = Vector2.ZERO                                   # Objetivo a seguir
@export_range(0, 20, 1) var followDelay: int = 15                               # Mayor valor -> Mayor seguimiento
@export var focusTarget: Vector2 = Vector2.ZERO                                 # Objetivo en modo enfoque
@export var isOption: bool = false                                              # Determina si es o no un Option

# === ESTADO INTERNO ===
var canFire: bool = true 
var prevParentPos: Vector2

func _ready():
	prevParentPos = get_parent().global_position

# === LOOP PRINCIPAL ===
func _process(delta) -> void:
	var activeBullets = get_tree().get_nodes_in_group("BulletCount").size()
	var maxBullets = MAX_BULLETS * get_parent().get_child_count()
	
	if INPUT.firing and canFire and activeBullets < maxBullets:
		await _fire_burst(INPUT.fireDir, bulletScene)
	if INPUT.fireHold and canFire and activeBullets < maxBullets and isOption:
		await _fire_burst(INPUT.fireDir, optFocusBullet)
	
	# Comportamiento options
	if followDelay > 0 and isOption: options(delta)

func options(delta):
	var parentDelta = get_parent().global_position - prevParentPos
	global_position -= parentDelta
	prevParentPos = get_parent().global_position
	
	if INPUT.fireHold: position = position.lerp(focusTarget, followDelay * delta)
	else: position = position.lerp(targetPos, followDelay * delta)

# === DISPARO EN RÁFAGA ===
func _fire_burst(direction: Vector2, scene: PackedScene) -> void:
	canFire = false
	var delay := fireRate
	
	for i in MAX_BULLETS:
		await get_tree().create_timer(0.05).timeout
		_fire_bullet(direction, scene)
	
	if direction != INPUT.fireDir: delay = 0.0
	
	await get_tree().create_timer(delay).timeout
	canFire = true

# === DISPARO INDIVIDUAL ===
func _fire_bullet(direction: Vector2, scene: PackedScene) -> void:
	var orthogonal = direction.orthogonal().normalized()
	var spacing = 30
	var totalLvl = baseLvl + int(GAME.weaponLvl)
	
	for i in totalLvl:
		var offset = (i - (totalLvl - 1) / 2.0) * spacing
		
		var bullet = scene.instantiate()
		bullet.position = global_position + orthogonal * offset
		bullet.set_dir(direction, deviationAngle)
		get_tree().current_scene.add_child(bullet)
