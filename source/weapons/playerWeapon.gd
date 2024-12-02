extends Node2D

@export var bullet_scene: PackedScene # Escena de la bala a instanciar
@export var fire_rate: float = 0.05 # Tiempo entre ráfagas
@export_range(-15, 15, 5) var deviationAngle: float = 0.0 # Desviación en grados (0, 30 o -30)

var can_fire: bool = true # Controla si se puede disparar
const MAX_BULLETS: int = 4 # Máximo de balas permitidas en el grupo

# Llamado cada cuadro
func _process(delta: float):
	# Contar las balas activas en el grupo "Player Bullet"
	var active_bullets = get_tree().get_nodes_in_group("Fire").size()
	var maxBullets = MAX_BULLETS * get_parent().get_child_count()
	
	# Verificar si se puede disparar en función del número de balas activas
	if INPUT.firing and can_fire and active_bullets < maxBullets and !INPUT.fireHold:
		await fire_burst(INPUT.fireDir)

# Dispara una ráfaga de 4 balas en la misma dirección
func fire_burst(dir):
	can_fire = false
	var newRate = fire_rate
	
	# Dispara 4 balas seguidas en la misma dirección
	for i in range(4):
		await get_tree().create_timer(0.05).timeout # Intervalo entre balas en la ráfaga
		fire_bullet(dir, global_position)
	
	if dir != INPUT.fireDir: newRate = 0 # Si se cambia de dirección, no hay refresco
	await get_tree().create_timer(newRate).timeout # Tiempo antes de permitir otra ráfaga
	can_fire = true

# Instancia y dispara una bala en la dirección actual
func fire_bullet(direction, pos):
	var bullet_instance = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet_instance) # Agregar la bala a la escena
	# Posicionar la bala en la posición del nodo actual
	bullet_instance.position = pos
	
	# Establecer la dirección enumerada de la bala
	bullet_instance.set_dir(direction, deviationAngle)
