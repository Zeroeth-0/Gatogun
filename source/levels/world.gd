extends Node2D

# === EXPORTS ===
@export_file var csvFile: String                                                # Información del nivel
@export var enemyScenes: Array[PackedScene] = []                                # Enemigos disponibles

# === CONSTANTES ===
const LANE_GAP: int = 87

# === LÍNEAS DE APARICIÓN ===
var lanes := {
	"N": [],
	"S": [],
	"E": [],
	"W": []
}

# === FLUJO PRINCIPAL ===
func _ready() -> void:
	_load_markers()
	await _load_csv_data(csvFile)
	GAME.lives = 2
	GAME.spawn()

# === INICIALIZACIÓN DE MARCADORES ===
func _load_markers() -> void:
	lanes["N"] = get_node("North Lane").get_children()
	lanes["S"] = get_node("South Lane").get_children()
	lanes["E"] = get_node("East Lane").get_children()
	lanes["W"] = get_node("West Lane").get_children()

# === CARGA Y PROCESAMIENTO DEL CSV ===
func _load_csv_data(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return
	
	# Saltar encabezado
	file.get_line()
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "": continue
		
		var data = line.split(",")
		var delay = float(data[6])
		await get_tree().create_timer(delay).timeout
		_spawn_enemy(data)
	
	file.close()

# === INSTANCIACIÓN DE ENEMIGOS ===
func _spawn_enemy(data: Array) -> void:
	var enemyType = data[0]
	var laneSide = data[1]
	var laneIndex = int(data[2])
	var laneOffset = float(data[3])
	var handed = data[4]
	var dir = data[5]
	
	var scene = _get_enemy_scene_by_name(enemyType)
	var enemy = scene.instantiate()
	var spawnPos = lanes[laneSide][laneIndex].global_position
	
	# Aplicar offset según dirección
	if laneSide in ["N", "S"]: spawnPos.x += laneOffset * LANE_GAP
	else: spawnPos.y += laneOffset * LANE_GAP
	enemy.position = spawnPos
	
	# Configurar handedness y dirección
	if handed == "R": enemy.handedness = enemy.Handedness.RIGHT
	elif handed == "L": enemy.handedness = enemy.Handedness.LEFT
	
	match dir:
		"N": enemy.directionEnum = enemy.Direction.NORTH
		"S": enemy.directionEnum = enemy.Direction.SOUTH
		"E": enemy.directionEnum = enemy.Direction.EAST
		"W": enemy.directionEnum = enemy.Direction.WEST
	
	get_tree().current_scene.add_child(enemy)

# === SELECCIÓN DE ESCENA DE ENEMIGO ===
func _get_enemy_scene_by_name(enemyName: String) -> PackedScene:
	for scene in enemyScenes:
		var baseName = scene.resource_path.get_file().get_basename()
		if baseName == enemyName: return scene
	return null
