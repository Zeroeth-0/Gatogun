extends Node2D

@export_file var waveFile: String
@export var enemyScenes: Array[PackedScene] = []

const LANE_GAP: int = 87

var lanes := {
	"N": [],
	"S": [],
	"E": [],
	"W": []
}

func _ready() -> void:
	_load_markers()
	await _load_wave_data(waveFile)
	GAME.lives = 2
	GAME.spawn()

func _load_markers() -> void:
	lanes["N"] = get_node("North Lane").get_children()
	lanes["S"] = get_node("South Lane").get_children()
	lanes["E"] = get_node("East Lane").get_children()
	lanes["W"] = get_node("West Lane").get_children()

func _load_wave_data(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty(): continue
		var data = _parse_wave_line(line)
		if data.is_empty(): continue
		await get_tree().create_timer(data.delay).timeout
		_spawn_enemy(data)

	file.close()

func _parse_wave_line(line: String) -> Dictionary:
	line = line.replace(" at ", "@").replace(" with ", ":").replace(" to ", ">").replace(" after ", "|")

	if line.strip_edges().begins_with(";") or line.strip_edges() == "":
		return {}

	var delay := 0.0
	if "|" in line:
		var parts = line.split("|", false, 2)
		if parts.size() < 2:
			return {}
		line = parts[0]
		delay = float(parts[1])

	# Normal parsing below
	if not "@" in line or line.begins_with("@"):
		return {}

	var type = line.get_slice("@", 0)
	var rest = line.get_slice("@", 1)

	if rest.length() < 2:
		return {}

	var laneSide = rest[0]
	var i := 1
	var digits := ""
	while i < rest.length() and rest[i].is_valid_int():
		digits += rest[i]
		i += 1
	if digits == "":
		return {}
	var laneIndex = int(digits)

	var laneOffset := 0.0
	if i < rest.length() and (rest[i] == "+" or rest[i] == "-"):
		var offsetStr := ""
		while i < rest.length() and (rest[i].is_valid_float() or rest[i] in ["+", "-", "."]):
			offsetStr += rest[i]
			i += 1
		if offsetStr != "":
			laneOffset = float(offsetStr)

	var handed = null
	if i < rest.length() and rest[i] == ":" and i + 1 < rest.length():
		handed = rest[i + 1]
		i += 2

	var dir = null
	if i < rest.length() and rest[i] == ">" and i + 1 < rest.length():
		dir = rest[i + 1]
		i += 2

	if handed == null:
		handed = "R" if laneIndex <= 3 else "L"
	if dir == null:
		dir = _get_opposite_dir(laneSide)

	return {
		"type": type,
		"lane": laneSide,
		"index": laneIndex,
		"offset": laneOffset,
		"hand": handed,
		"dir": dir,
		"delay": delay
	}

func _get_opposite_dir(dir: String) -> String:
	match dir:
		"N": return "S"
		"S": return "N"
		"E": return "W"
		"W": return "E"
	return "S"  # Fallback

func _spawn_enemy(data: Dictionary) -> void:
	if data.type == "END_MARKER":
		return  # No hacer nada, es solo para forzar delay

	# Validaciones normales
	if not data.has("type") or not data.has("lane") or not data.has("index"):
		return

	var scene = _get_enemy_scene_by_name(data.type)
	if not scene: return

	if not lanes.has(data.lane) or data.index >= lanes[data.lane].size():
		return

	var enemy = scene.instantiate()
	var spawnPos = lanes[data.lane][data.index].global_position

	if data.lane in ["N", "S"]:
		spawnPos.x += data.offset * LANE_GAP
	else:
		spawnPos.y += data.offset * LANE_GAP

	enemy.position = spawnPos

	enemy.handedness = enemy.Handedness.RIGHT if data.hand == "R" else enemy.Handedness.LEFT

	match data.dir:
		"N": enemy.directionEnum = enemy.Direction.NORTH
		"S": enemy.directionEnum = enemy.Direction.SOUTH
		"E": enemy.directionEnum = enemy.Direction.EAST
		"W": enemy.directionEnum = enemy.Direction.WEST

	get_tree().current_scene.add_child(enemy)

func _get_enemy_scene_by_name(enemyName: String) -> PackedScene:
	for scene in enemyScenes:
		var baseName = scene.resource_path.get_file().get_basename()
		if baseName == enemyName:
			return scene
	return null
