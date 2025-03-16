extends Node2D

# Variables para el CSV y la lista de enemigos
@export_file var csv_file: String
@export var enemy_scenes: Array[PackedScene] = []
const laneGap: int = 87;

# Markers por cada lado
var lanes = {
	"N": [],
	"S": [],
	"E": [],
	"W": []
}

# Ejecutar en _ready para cargar el archivo y empezar la lógica
func _ready():
	load_markers()
	load_csv_data(csv_file)
	GAME.spawn()

# Carga los Marker2D en las listas correspondientes por lado (N, S, E, W)
func load_markers():
	lanes["N"] = get_node("North Lane").get_children()
	lanes["S"] = get_node("South Lane").get_children()
	lanes["E"] = get_node("East Lane").get_children()
	lanes["W"] = get_node("West Lane").get_children()

# Leer y parsear el CSV
func load_csv_data(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		file.get_line()  # Saltar la primera línea (encabezados)
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line == "":
				continue  # Saltar líneas vacías
			var data = line.split(",")
			# Instanciar enemigo usando la data del CSV con espera
			await get_tree().create_timer(float(data[6])).timeout
			spawn_enemy(data)
		file.close()

# Función para instanciar el enemigo
func spawn_enemy(data: Array) -> void:
	var enemy_type = data[0] # Nombre del tipo de enemigo
	var lane_side = data[1]  # N, S, E, W
	var lane_number = int(data[2])  # Carril (0-6)
	var lane_offset = float(data[3])
	var handedness = data[4]  # R o L
	var direction = data[5]  # Dirección N, S, E, W
	
	# Buscar la escena del enemigo por nombre
	var enemy_scene = get_enemy_scene_by_name(enemy_type)
	
	var enemy_instance = enemy_scene.instantiate()
	
	# Obtener el Marker2D correspondiente y ubicar al enemigo
	var spawn_position = lanes[lane_side][lane_number].global_position
	if lane_side == "N" or lane_side == "S": spawn_position.x += lane_offset * laneGap
	if lane_side == "W" or lane_side == "E": spawn_position.y += lane_offset * laneGap
	enemy_instance.position = spawn_position
	
	match handedness:
		"R": enemy_instance.handedness = enemy_instance.Handedness.RIGHT
		"L": enemy_instance.handedness = enemy_instance.Handedness.LEFT
	
	match direction:
		"N": enemy_instance.directionEnum = enemy_instance.Direction.NORTH
		"S": enemy_instance.directionEnum = enemy_instance.Direction.SOUTH
		"W": enemy_instance.directionEnum = enemy_instance.Direction.WEST
		"E": enemy_instance.directionEnum = enemy_instance.Direction.EAST
	
	get_tree().current_scene.add_child(enemy_instance)

# Obtener el PackedScene basado en el nombre
func get_enemy_scene_by_name(enemyName: String) -> PackedScene:
	for scene in enemy_scenes:
		# Obtener el nombre del archivo sin la extensión (.tscn)
		var scene_name = scene.resource_path.get_file().get_basename()
		# Compara con el nombre pasado como argumento
		if scene_name == enemyName:
			return scene
	return null
