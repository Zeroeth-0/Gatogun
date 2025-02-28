extends Node2D

@export var bullet_scene: PackedScene # Escena de la bala a instanciar
@export var fire_rate: float = 0.01 # Tiempo entre ráfagas
var rate = fire_rate

var canFire: bool = true

func _process(delta):
	# Obtenemos todos los hijos del nodo
	var children = get_children()
	canFire = true
	rate -= delta
	
	# Iteramos sobre cada hijo
	for child in children:
		# Comprobamos si el hijo tiene la variable 'can_fire' y si es true
		if not child.can_fire:
			canFire = false
			break
	
	if canFire: rotate_weapon()
	
	if INPUT.fireHold: await fire_burst(INPUT.fireDir)
	

func fire_burst(dir):
	if rate <= 0:
		fire_bullet(dir, global_position)
		rate = fire_rate

# Instancia y dispara una bala en la dirección actual
func fire_bullet(direction, pos):
	var bullet_instance = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet_instance) # Agregar la bala a la escena
	# Posicionar la bala en la posición del nodo actual
	bullet_instance.position = pos
	
	# Establecer la dirección enumerada de la bala
	bullet_instance.set_dir(direction, 0)

func rotate_weapon():
	match INPUT.buttonActive:
		INPUT.Buttons.A: rotation = deg_to_rad(90)
		INPUT.Buttons.B: rotation = deg_to_rad(180)
		INPUT.Buttons.Y: rotation = deg_to_rad(270)
		INPUT.Buttons.X: rotation = deg_to_rad(0)
