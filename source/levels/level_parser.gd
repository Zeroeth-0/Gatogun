extends Node2D

@export_file var waveFile: String
@export var enemyScenes: Array[PackedScene] = []
var lives = 2
var playing = true

const LANE_GAP: int = 87

var lanes := {
	"N": [],
	"S": [],
	"E": [],
	"W": []
}

var pattern_definitions := {
	"LADDER": _pattern_ladder,
	"PARADE": _pattern_parade,
	"MIRROR": _pattern_mirror,
	"SWARM": _pattern_swarm,
}

func _ready() -> void:
	DRNG.reset_rng(2004, false)
	_load_markers()
	await _load_wave_data(waveFile)
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

		var expanded_lines = _expand_pattern_if_needed(line)
		for l in expanded_lines:
			var data = _parse_wave_line(l)
			if data.is_empty(): continue
			await get_tree().create_timer(data.delay, false).timeout
			_spawn_enemy(data)

	file.close()

func _expand_pattern_if_needed(line: String) -> Array:
	var pattern_match := line.split(" ", false)
	if pattern_match.size() < 2:
		return [line]

	var prefix = pattern_match[0]
	var rest = line.substr(prefix.length()).strip_edges()

	var pattern_name = ""
	var args = {}

	if prefix.find("(") != -1 and prefix.ends_with(")"):
		pattern_name = prefix.get_slice("(", 0).to_upper()
		var raw_args = prefix.get_slice("(", 1).trim_suffix(")")
		for pair in raw_args.split(",", false):
			if "=" in pair:
				var key = pair.get_slice("=", 0).strip_edges()
				var value = pair.get_slice("=", 1).strip_edges()
				args[key] = value
	else:
		pattern_name = prefix.to_upper()

	if pattern_definitions.has(pattern_name):
		return pattern_definitions[pattern_name].call(rest, args)
	else:
		return [line]

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
	return "S"

func _spawn_enemy(data: Dictionary) -> void:
	if data.type == "END_MARKER":
		return
	
	if not data.has("type") or not data.has("lane") or not data.has("index"):
		return
	
	var scene = _get_enemy_scene_by_name(data.type)
	if not scene: return
	
	if not lanes.has(data.lane) or data.index >= lanes[data.lane].size(): return
	
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
	
	GLOBAL.add_to_game(enemy)

func _get_enemy_scene_by_name(enemyName: String) -> PackedScene:
	for scene in enemyScenes:
		var baseName = scene.resource_path.get_file().get_basename()
		if baseName == enemyName:
			return scene
	return null

# ========================
#  PATRONES
# ========================

func _pattern_ladder(base: String, args: Dictionary) -> Array:
	var steps = int(args.get("steps", 4))
	var direction = str(args.get("direction", "right")).to_lower()
	var jump = int(args.get("jump", 1))
	var warmup = float(args.get("warmup", 0.2))  # tiempo entre spawns

	var dir_mod = 1 if direction in ["r", "right"] else -1

	var parsed = _parse_wave_line(base)
	if parsed.is_empty(): return []

	var lane = parsed["lane"]
	var index = parsed["index"]
	var offset = parsed["offset"]
	var _base_delay = parsed["delay"]
	var type = parsed["type"]
	var hand = parsed["hand"]
	var move_dir = parsed["dir"]

	var lane_size = lanes[lane].size()
	var lines: Array = []

	var current_index = index
	var moving_dir = dir_mod

	for i in range(steps):
		# Rebote: si estamos fuera, invertir sentido y saltar
		if current_index < 0:
			current_index = jump  # entrar al carril 0 + jump
			moving_dir = 1
		elif current_index >= lane_size:
			current_index = lane_size - 1 - jump
			moving_dir = -1

		# Clamp de seguridad
		current_index = clamp(current_index, 0, lane_size - 1)

		# Generar línea con delay relativo al primero
		var delay = warmup if i > 0 else _base_delay
		var line = "%s@%s%d+%.2f:%s>%s|%.3f" % [
			type, lane, current_index, offset,
			hand, move_dir, delay
		]
		lines.append(line)
		current_index += moving_dir * jump

	return lines

func _pattern_parade(base: String, args: Dictionary) -> Array:
	var thickness = int(args.get("thickness", 3))
	var length = int(args.get("length", 3))
	var warmup = float(args.get("warmup", 0.2))

	var lines: Array = []
	var parsed = _parse_wave_line(base)
	if parsed.is_empty():
		return []

	var lane = parsed["lane"]
	var start_index = parsed["index"]
	var offset = parsed["offset"]
	var _base_delay = parsed["delay"]
	var type = parsed["type"]
	var hand = parsed["hand"]
	var move_dir = parsed["dir"]

	for row in range(length):
		var row_delay = warmup
		for col in range(thickness):
			var current_index = start_index + col
			if current_index < 0 or current_index >= lanes[lane].size():
				continue  # fuera de rango

			var line = "%s@%s%d+%.2f:%s>%s|%.3f" % [
				type, lane, current_index, offset,
				hand, move_dir, row_delay
			]
			lines.append(line)
			row_delay = 0

	return lines

func _pattern_mirror(base: String, args: Dictionary) -> Array:
	var parsed = _parse_wave_line(base)
	if parsed.is_empty():
		return []

	var lane = parsed["lane"]
	var index = parsed["index"]
	var offset = parsed["offset"]
	var _base_delay = parsed["delay"]
	var type = parsed["type"]
	var hand = parsed["hand"]
	var move_dir = parsed["dir"]

	var delay_mirror = float(args.get("warmup", 0.2))
	var lane_size = lanes[lane].size()
	var mirror_index = lane_size - 1 - index

	var lines = []

	# Línea original
	var line_original = "%s@%s%d+%.2f:%s>%s|%.3f" % [
		type, lane, index, offset,
		hand, move_dir, _base_delay
	]
	lines.append(line_original)

	# Línea espejo
	if mirror_index != index and mirror_index >= 0 and mirror_index < lane_size:
		var mirror_line = "%s@%s%d+%.2f:%s>%s|%.3f" % [
			type, lane, mirror_index, offset,
			hand, move_dir, _base_delay + delay_mirror
		]
		lines.append(mirror_line)

	return lines

func _pattern_swarm(base: String, args: Dictionary) -> Array:
	var thickness = int(args.get("thickness", 3))
	var length = int(args.get("length", 4))
	var warmup = float(args.get("warmup", 0.3))

	var lines: Array = []
	var parsed = _parse_wave_line(base)
	if parsed.is_empty():
		return []

	var lane = parsed["lane"]
	var start_index = parsed["index"]
	var base_offset = parsed["offset"]
	var _base_delay = parsed["delay"]
	var type = parsed["type"]
	var hand = parsed["hand"]
	var move_dir = parsed["dir"]

	var lane_size = lanes[lane].size()

	for row in range(length):
		var row_delay = warmup

		var current_thickness = thickness if row % 2 == 0 else thickness - 1
		var offset_shift = 0.0 if row % 2 == 0 else 0.5

		for i in range(current_thickness):
			var current_index = start_index + i
			if current_index < 0 or current_index >= lane_size:
				continue

			var line = "%s@%s%d+%.2f:%s>%s|%.3f" % [
				type, lane, current_index, base_offset + offset_shift,
				hand, move_dir, row_delay
			]
			lines.append(line)
			row_delay = 0

	return lines

# How to use:
# EnemyName at DirectionNumber+offset (N0+0.5) with Handedness (R/L) to Direction (N/S/E/W) after Time (1)
# EnemyName @ DirectionNumber+offset (N0+0.5) : Handedness (R/L) > Direction (N/S/E/W) | Time (1)
# SWARM(thickness,length,warmup) Std
# LADDER(step,direction,jump,warmup) Std
# MIRROR(warmup) Std
# PARADE(thickness,length,warmup) Std
