extends Node2D

# Variable que será true si todos los hijos pueden disparar
var canFire = true

func _process(delta):
	# Obtenemos todos los hijos del nodo
	var children = get_children()
	canFire = true
	
	# Iteramos sobre cada hijo
	for child in children:
		# Comprobamos si el hijo tiene la variable 'can_fire' y si es true
		if not child.can_fire:
			canFire = false
			break
	
	if canFire: rotate_weapon()

func rotate_weapon():
	match INPUT.buttonActive:
		INPUT.Buttons.A: rotation = deg_to_rad(90)
		INPUT.Buttons.B: rotation = deg_to_rad(180)
		INPUT.Buttons.Y: rotation = deg_to_rad(270)
		INPUT.Buttons.X: rotation = deg_to_rad(0)
