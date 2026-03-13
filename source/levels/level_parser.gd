extends Node2D

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
	"SWARM":  _pattern_swarm,
}

var _file: FileAccess = null

func _ready() -> void:
	DRNG.reset_rng(2004, false)
	_load_markers()
	FLOW._on_parser_ready(self)

func begin(wave_file: String) -> void:
	_parse_and_run(wave_file)

func _load_markers() -> void:
	lanes["N"] = get_node("North Lane").get_children()
	lanes["S"] = get_node("South Lane").get_children()
	lanes["E"] = get_node("East Lane").get_children()
	lanes["W"] = get_node("West Lane").get_children()

func _parse_and_run(path: String) -> void:
	_file = FileAccess.open(path, FileAccess.READ)
	if not _file:
		push_error("LevelParser: no se pudo abrir el wave file: " + path)
		return

	while not _file.eof_reached():
		var line: String = _file.get_line().strip_edges()
		if line.is_empty():
			continue

		if line.begins_with("[") and line.ends_with("]"):
			var marker: String = line.substr(1, line.length() - 2)
			FLOW.notify_marker(marker)
			await FLOW.resume_parsing
			continue

		var expanded := _expand_pattern_if_needed(line)
		for l in expanded:
			var data := _parse_wave_line(l)
			if data.is_empty():
				continue
			await get_tree().create_timer(data.delay, false).timeout
			_spawn_enemy(data)

	_file.close()
	_file = null

func _expand_pattern_if_needed(line: String) -> Array:
	var parts := line.split(" ", false)
	if parts.size() < 2:
		return [line]

	var prefix: String = parts[0]
	var rest: String = line.substr(prefix.length()).strip_edges()

	var pattern_name: String = ""
	var args: Dictionary = {}

	if prefix.find("(") != -1 and prefix.ends_with(")"):
		pattern_name = prefix.get_slice("(", 0).to_upper()
		var raw_args: String = prefix.get_slice("(", 1).trim_suffix(")")
		for pair in raw_args.split(",", false):
			if "=" in pair:
				var key: String = pair.get_slice("=", 0).strip_edges()
				var value: String = pair.get_slice("=", 1).strip_edges()
				args[key] = value
	else:
		pattern_name = prefix.to_upper()

	if pattern_definitions.has(pattern_name):
		return pattern_definitions[pattern_name].call(rest, args)

	return [line]

func _parse_wave_line(line: String) -> Dictionary:
	line = line\
		.replace(" at ", "@")\
		.replace(" with ", ":")\
		.replace(" to ", ">")\
		.replace(" after ", "|")

	if line.strip_edges().begins_with(";") or line.strip_edges() == "":
		return {}

	var delay := 0.0
	if "|" in line:
		var parts := line.split("|", false, 2)
		if parts.size() < 2:
			return {}
		line = parts[0]
		delay = float(parts[1])

	if not "@" in line or line.begins_with("@"):
		return {}

	var type: String = line.get_slice("@", 0)
	var rest: String = line.get_slice("@", 1)

	if rest.length() < 2:
		return {}

	var lane_side: String = rest[0]
	var i := 1
	var digits := ""
	while i < rest.length() and rest[i].is_valid_int():
		digits += rest[i]
		i += 1
	if digits == "":
		return {}
	var lane_index: int = int(digits)

	var lane_offset := 0.0
	if i < rest.length() and (rest[i] == "+" or rest[i] == "-"):
		var offset_str := ""
		while i < rest.length() and (rest[i].is_valid_float() or rest[i] in ["+", "-", "."]):
			offset_str += rest[i]
			i += 1
		if offset_str != "":
			lane_offset = float(offset_str)

	var handed = null
	if i < rest.length() and rest[i] == ":" and i + 1 < rest.length():
		handed = rest[i + 1]
		i += 2

	var dir = null
	if i < rest.length() and rest[i] == ">" and i + 1 < rest.length():
		dir = rest[i + 1]
		i += 2

	if handed == null:
		handed = "R" if lane_index <= 3 else "L"
	if dir == null:
		dir = _get_opposite_dir(lane_side)

	return {
		"type":   type,
		"lane":   lane_side,
		"index":  lane_index,
		"offset": lane_offset,
		"hand":   handed,
		"dir":    dir,
		"delay":  delay,
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

	var scene := _get_enemy_scene_by_name(data.type)
	if not scene:
		return

	if not lanes.has(data.lane) or data.index >= lanes[data.lane].size():
		return

	var enemy = scene.instantiate()
	var spawn_pos: Vector2 = lanes[data.lane][data.index].global_position

	if data.lane in ["N", "S"]:
		spawn_pos.x += data.offset * LANE_GAP
	else:
		spawn_pos.y += data.offset * LANE_GAP

	enemy.position = spawn_pos
	enemy.handedness = enemy.Handedness.RIGHT if data.hand == "R" else enemy.Handedness.LEFT

	match data.dir:
		"N": enemy.directionEnum = enemy.Direction.NORTH
		"S": enemy.directionEnum = enemy.Direction.SOUTH
		"E": enemy.directionEnum = enemy.Direction.EAST
		"W": enemy.directionEnum = enemy.Direction.WEST

	GLOBAL.add_to_game(enemy)

func _get_enemy_scene_by_name(enemy_name: String) -> PackedScene:
	for scene in enemyScenes:
		var base_name: String = scene.resource_path.get_file().get_basename()
		if base_name == enemy_name:
			return scene
	return null

# ========================
#  PATRONES
# ========================

func _pattern_ladder(base: String, args: Dictionary) -> Array:
	var steps: int        = int(args.get("steps", 4))
	var direction: String = str(args.get("direction", "right")).to_lower()
	var jump: int         = int(args.get("jump", 1))
	var warmup: float     = float(args.get("warmup", 0.2))
	var dir_mod: int      = 1 if direction in ["r", "right"] else -1

	var parsed := _parse_wave_line(base)
	if parsed.is_empty():
		return []

	var lane: String      = parsed["lane"]
	var index: int        = parsed["index"]
	var offset: float     = parsed["offset"]
	var base_delay: float = parsed["delay"]
	var type: String      = parsed["type"]
	var hand: String      = parsed["hand"]
	var move_dir: String  = parsed["dir"]
	var lane_size: int    = lanes[lane].size()

	var lines: Array = []
	var current: int = index
	var moving: int  = dir_mod

	for i in range(steps):
		if current < 0:
			current = jump
			moving = 1
		elif current >= lane_size:
			current = lane_size - 1 - jump
			moving = -1

		current = clamp(current, 0, lane_size - 1)

		var delay: float = warmup if i > 0 else base_delay
		lines.append("%s@%s%d+%.2f:%s>%s|%.3f" % [
			type, lane, current, offset, hand, move_dir, delay
		])
		current += moving * jump

	return lines

func _pattern_parade(base: String, args: Dictionary) -> Array:
	var thickness: int  = int(args.get("thickness", 3))
	var length: int     = int(args.get("length", 3))
	var warmup: float   = float(args.get("warmup", 0.2))

	var parsed := _parse_wave_line(base)
	if parsed.is_empty():
		return []

	var lane: String      = parsed["lane"]
	var start_index: int  = parsed["index"]
	var offset: float     = parsed["offset"]
	var base_delay: float = parsed["delay"]
	var type: String      = parsed["type"]
	var hand: String      = parsed["hand"]
	var move_dir: String  = parsed["dir"]

	var lines: Array = []

	for _row in range(length):
		var row_delay: float = warmup
		for col in range(thickness):
			var current_index: int = start_index + col
			if current_index < 0 or current_index >= lanes[lane].size():
				continue
			lines.append("%s@%s%d+%.2f:%s>%s|%.3f" % [
				type, lane, current_index, offset, hand, move_dir, row_delay
			])
			row_delay = 0.0

	return lines

func _pattern_mirror(base: String, args: Dictionary) -> Array:
	var parsed := _parse_wave_line(base)
	if parsed.is_empty():
		return []

	var lane: String        = parsed["lane"]
	var index: int          = parsed["index"]
	var offset: float       = parsed["offset"]
	var base_delay: float   = parsed["delay"]
	var type: String        = parsed["type"]
	var hand: String        = parsed["hand"]
	var move_dir: String    = parsed["dir"]
	var delay_mirror: float = float(args.get("warmup", 0.2))
	var lane_size: int      = lanes[lane].size()
	var mirror_index: int   = lane_size - 1 - index

	var lines: Array = []

	lines.append("%s@%s%d+%.2f:%s>%s|%.3f" % [
		type, lane, index, offset, hand, move_dir, base_delay
	])

	if mirror_index != index and mirror_index >= 0 and mirror_index < lane_size:
		lines.append("%s@%s%d+%.2f:%s>%s|%.3f" % [
			type, lane, mirror_index, offset, hand, move_dir, base_delay + delay_mirror
		])

	return lines

func _pattern_swarm(base: String, args: Dictionary) -> Array:
	var thickness: int   = int(args.get("thickness", 3))
	var length: int      = int(args.get("length", 4))
	var warmup: float    = float(args.get("warmup", 0.3))

	var parsed := _parse_wave_line(base)
	if parsed.is_empty():
		return []

	var lane: String       = parsed["lane"]
	var start_index: int   = parsed["index"]
	var base_offset: float = parsed["offset"]
	var base_delay: float  = parsed["delay"]
	var type: String       = parsed["type"]
	var hand: String       = parsed["hand"]
	var move_dir: String   = parsed["dir"]
	var lane_size: int     = lanes[lane].size()

	var lines: Array = []

	for row in range(length):
		var row_delay: float    = warmup
		var current_thick: int  = thickness if row % 2 == 0 else thickness - 1
		var offset_shift: float = 0.0 if row % 2 == 0 else 0.5

		for i in range(current_thick):
			var current_index: int = start_index + i
			if current_index < 0 or current_index >= lane_size:
				continue
			lines.append("%s@%s%d+%.2f:%s>%s|%.3f" % [
				type, lane, current_index, base_offset + offset_shift,
				hand, move_dir, row_delay
			])
			row_delay = 0.0

	return lines

# ========================
#  CÓMO USAR
# ========================
# Línea estándar:
#   EnemyName at LaneSide+LaneIndex+offset with Hand to Dir after Delay
#   EnemyName @ LaneSideIndex+offset : Hand > Dir | Delay
#
# Ejemplos:
#   sorro at N2 after 1.0
#   torro at E1+0.5 with L to S after 2.0
#
# Marcadores de fase (pausan el parser hasta que FLOW lo reanuda):
#   [INTRO_END]   — fin de la intro, empieza sección A
#   [MIDBOSS]     — para el parser, FLOW spawnea el midboss
#   [BOSS]        — para el parser, FLOW muestra Warning y spawnea el boss
#
# Patrones:
#   SWARM(thickness=3,length=4,warmup=0.3)  EnemyName at N0 after 1
#   LADDER(steps=4,direction=right,jump=1,warmup=0.2)  EnemyName at N0 after 1
#   MIRROR(warmup=0.5)  EnemyName at N2 after 1
#   PARADE(thickness=3,length=7,warmup=0.7)  EnemyName at N0 after 1
#
# Comentarios:
#   ; esto es un comentario y se ignora
