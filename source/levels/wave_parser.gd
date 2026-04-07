# source/levels/wave_parser.gd
# Converts SPAWN and PATTERN tokens into SpawnCommand objects
class_name WaveParser
extends RefCounted

# ==============================================================================
# SPAWN COMMAND
# ==============================================================================

class SpawnCommand:
	var enemy_id:   StringName
	var lane:       String   ## "N","S","E","W"
	var lane_index: int
	var lane_offset: float
	var handedness: String   ## "L","R"
	var direction:  String   ## "N","S","E","W"
	var delay:      float
	var line:       int

# ==============================================================================
# REGEX — compiled once, reused for every line
# ==============================================================================

static var _rx: RegEx = null

static func _get_rx() -> RegEx:
	if _rx != null:
		return _rx
	_rx = RegEx.new()
	# Format after normalization:
	# EnemyId@LaneChar LaneIndex [+/-Offset] [:Hand] [>Dir] [|Delay]
	_rx.compile(
		r"^(?P<id>[A-Za-z0-9_]+)@(?P<lane>[NSEWnsew])(?P<idx>\d+)" +
		r"(?P<offset>[+\-]\d+\.?\d*)?(?::(?P<hand>[LRlr]))?(?:>(?P<dir>[NSEWnsew]))?(?:\|(?P<delay>\d+\.?\d*))?$"
	)
	return _rx

# ==============================================================================
# PUBLIC API
# ==============================================================================

## Parse a single SPAWN token. Returns null on failure
static func parse_spawn(token: WaveLexer.Token) -> SpawnCommand:
	var normalized := _normalize(token.raw)
	var result     := _get_rx().search(normalized)
	
	if result == null:
		push_error("WaveParser [line %d]: cannot parse '%s'" \
			% [token.line, token.raw])
		return null
	
	var cmd            := SpawnCommand.new()
	cmd.line            = token.line
	cmd.enemy_id        = StringName(result.get_string("id"))
	cmd.lane            = result.get_string("lane").to_upper()
	cmd.lane_index      = int(result.get_string("idx"))
	cmd.lane_offset     = float(result.get_string("offset")) \
		if result.get_string("offset") != "" else 0.0
	cmd.handedness      = result.get_string("hand").to_upper() \
		if result.get_string("hand") != "" else ""
	cmd.direction       = result.get_string("dir").to_upper() \
		if result.get_string("dir") != "" else ""
	cmd.delay           = float(result.get_string("delay")) \
		if result.get_string("delay") != "" else 0.0
	
	# Defaults
	if cmd.handedness == "": cmd.handedness = "R" if cmd.lane_index <= 3 else "L"
	if cmd.direction == "": cmd.direction = _opposite(cmd.lane)
	
	return cmd

## Expand a PATTERN token into an Array[SpawnCommand].
## Returns empty array on failure.
static func parse_pattern(
		token: WaveLexer.Token,
		lane_sizes: Dictionary) -> Array[SpawnCommand]:
	var raw   := token.raw
	var upper := raw.to_upper()
	
	if upper.begins_with("SWARM"): return _expand("SWARM", raw, lane_sizes, token.line)
	elif upper.begins_with("LADDER"): return _expand("LADDER", raw, lane_sizes, token.line)
	elif upper.begins_with("PARADE"): return _expand("PARADE", raw, lane_sizes, token.line)
	elif upper.begins_with("MIRROR"): return _expand("MIRROR", raw, lane_sizes, token.line)
	
	push_error("WaveParser [line %d]: unknown pattern '%s'" % [token.line, raw])
	return []

# ==============================================================================
# PATTERN EXPANSION
# ==============================================================================

static func _expand(
		pattern: String,
		raw: String,
		lane_sizes: Dictionary,
		ln: int) -> Array[SpawnCommand]:
	# Split: "SWARM(k=v,...) EnemyName@..."
	var paren_open  := raw.find("(")
	var paren_close := raw.find(")")
	var args := {}
	
	if paren_open != -1 and paren_close != -1:
		var raw_args := raw.substr(paren_open + 1, paren_close - paren_open - 1)
		for pair in raw_args.split(",", false):
			if "=" in pair:
				var kv := pair.split("=", false, 2)
				args[kv[0].strip_edges().to_lower()] = kv[1].strip_edges()
	
	# The rest after the closing paren is the base spawn line
	var base_raw := raw.substr(paren_close + 1).strip_edges()
	var base_token := WaveLexer.Token.new(WaveLexer.TokenType.SPAWN, base_raw, ln)
	var base := parse_spawn(base_token)
	if base == null: return []
	
	var lane_size: int = lane_sizes.get(base.lane, 7)
	
	match pattern:
		"SWARM":  return _pattern_swarm(base, args, lane_size, ln)
		"LADDER": return _pattern_ladder(base, args, lane_size, ln)
		"PARADE": return _pattern_parade(base, args, lane_size, ln)
		"MIRROR": return _pattern_mirror(base, args, lane_size, ln)
	
	return []

static func _make_cmd(base: SpawnCommand, index: int,
		offset: float, delay: float) -> SpawnCommand:
	var cmd        := SpawnCommand.new()
	cmd.enemy_id   = base.enemy_id
	cmd.lane       = base.lane
	cmd.lane_index = index
	cmd.lane_offset = offset
	cmd.handedness = base.handedness
	cmd.direction  = base.direction
	cmd.delay      = delay
	cmd.line       = base.line
	return cmd

static func _pattern_swarm(
		base: SpawnCommand,
		args: Dictionary,
		lane_size: int,
		_ln: int) -> Array[SpawnCommand]:
	var thickness := int(args.get("thickness", 3))
	var length    := int(args.get("length",    4))
	var warmup    := float(args.get("warmup",  0.3))
	var cmds: Array[SpawnCommand] = []
	
	for row in length:
		var thick  := thickness if row % 2 == 0 else thickness - 1
		var offset := 0.0 if row % 2 == 0 else 0.5
		var d      := warmup if row > 0 else base.delay
		for i in thick:
			var idx := base.lane_index + i
			if idx < 0 or idx >= lane_size: continue
			cmds.append(_make_cmd(base, idx, base.lane_offset + offset, d))
			d = 0.0
	return cmds

static func _pattern_ladder(
		base: SpawnCommand,
		args: Dictionary,
		lane_size: int,
		_ln: int) -> Array[SpawnCommand]:
	var steps     := int(args.get("steps",     4))
	var direction := str(args.get("direction", "right")).to_lower()
	var jump      := int(args.get("jump",      1))
	var warmup    := float(args.get("warmup",  0.2))
	var dir_mod   := 1 if direction in ["r", "right"] else -1
	var cmds: Array[SpawnCommand] = []
	
	var current := base.lane_index
	var moving  := dir_mod
	for i in steps:
		if current < 0:
			current = jump
			moving  = 1
		elif current >= lane_size:
			current = lane_size - 1 - jump
			moving  = -1
		current = clampi(current, 0, lane_size - 1)
		cmds.append(_make_cmd(base, current, base.lane_offset, warmup if i > 0 else base.delay))
		current += moving * jump
	return cmds

static func _pattern_parade(
		base: SpawnCommand,
		args: Dictionary,
		lane_size: int,
		_ln: int) -> Array[SpawnCommand]:
	var thickness := int(args.get("thickness", 3))
	var length    := int(args.get("length",    3))
	var warmup    := float(args.get("warmup",  0.2))
	var cmds: Array[SpawnCommand] = []
	
	for _row in length:
		var d := warmup
		for col in thickness:
			var idx := base.lane_index + col
			if idx < 0 or idx >= lane_size: continue
			cmds.append(_make_cmd(base, idx, base.lane_offset, d))
			d = 0.0
	return cmds

static func _pattern_mirror(
		base: SpawnCommand,
		args: Dictionary,
		lane_size: int,
		_ln: int) -> Array[SpawnCommand]:
	var warmup  := float(args.get("warmup", 0.2))
	var mirror  := lane_size - 1 - base.lane_index
	var cmds: Array[SpawnCommand] = []
	cmds.append(_make_cmd(base, base.lane_index, base.lane_offset, base.delay))
	if mirror != base.lane_index and mirror >= 0 and mirror < lane_size:
		cmds.append(_make_cmd(base, mirror, base.lane_offset, base.delay + warmup))
	return cmds

# ==============================================================================
# HELPERS
# ==============================================================================

static func _normalize(line: String) -> String:
	return line\
		.replace(" at ", "@")\
		.replace(" with ", ":")\
		.replace(" to ", ">")\
		.replace(" after ", "|")\
		.replace(" ", "")

static func _opposite(dir: String) -> String:
	match dir:
		"N": return "S"
		"S": return "N"
		"E": return "W"
		"W": return "E"
	return "S"
