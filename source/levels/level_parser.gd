# source/levels/level_parser.gd
# Reads a wave .txt file and spawns enemies using WaveLexer + WaveParser
extends Node2D

# ==============================================================================
# CONSTANTS
# ==============================================================================

const LANE_GAP: int = 87

# ==============================================================================
# EXPORTS
# ==============================================================================

## Maps enemy id strings to PackedScenes
@export var registry: EnemyRegistry

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var playing: bool = true

## Key: "N","S","E","W" → Array of Marker2D
var _lanes: Dictionary = {}

# Lane sizes pre-computed for pattern expansion
var _lane_sizes: Dictionary = {}

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	if registry == null:
		push_error("LevelParser '%s': no EnemyRegistry assigned." % name)
		return
	DRNG.reset_rng(2004, false)
	_load_lanes()
	FLOW._on_parser_ready(self)

# ==============================================================================
# PUBLIC API
# ==============================================================================

func begin(wave_file: String) -> void:
	_run(wave_file)

# ==============================================================================
# INTERNAL
# ==============================================================================

func _load_lanes() -> void:
	for pair in [["N","North"], ["S","South"], ["E","East"], ["W","West"]]:
		var key     = pair[0]
		var node_nm = pair[1] + " Lane"
		var node    := get_node_or_null(node_nm)
		if node == null:
			push_error("LevelParser: node '%s' not found." % node_nm)
			_lanes[key]      = []
			_lane_sizes[key] = 0
		else:
			_lanes[key]      = node.get_children()
			_lane_sizes[key] = _lanes[key].size()

func _run(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LevelParser: cannot open '%s'" % path)
		return
	
	var source := file.get_as_text()
	file.close()
	
	var tokens := WaveLexer.tokenize(source)
	await _execute(tokens)
	FLOW.notify_marker("LEVEL_END")

func _execute(tokens: Array) -> void:
	for token: WaveLexer.Token in tokens:
		if not playing: return
	
		match token.type:
			WaveLexer.TokenType.EMPTY,\
			WaveLexer.TokenType.COMMENT,\
			WaveLexer.TokenType.ERROR: pass
			WaveLexer.TokenType.WAIT:
				while get_tree().get_nodes_in_group("Enemy").size() > 0: await get_tree().process_frame
			WaveLexer.TokenType.MARKER:
				var name := token.raw.substr(1, token.raw.length() - 2)\
					.strip_edges().to_upper()
				FLOW.notify_marker(name)
				await FLOW.resume_parsing
			WaveLexer.TokenType.SPAWN:
				var cmd := WaveParser.parse_spawn(token)
				if cmd:
					if cmd.delay > 0.0:
						await get_tree().create_timer(cmd.delay, false).timeout
					_spawn(cmd)
			WaveLexer.TokenType.PATTERN:
				var cmds := WaveParser.parse_pattern(token, _lane_sizes)
				for cmd: WaveParser.SpawnCommand in cmds:
					if cmd.delay > 0.0: await get_tree().create_timer(cmd.delay, false).timeout
					_spawn(cmd)

func _spawn(cmd: WaveParser.SpawnCommand) -> void:
	var scene := registry.get_scene(cmd.enemy_id)
	if scene == null: return
	
	var lane_arr: Array = _lanes.get(cmd.lane, [])
	if cmd.lane_index >= lane_arr.size():
		push_error("LevelParser [line %d]: lane '%s'[%d] out of range." \
			% [cmd.line, cmd.lane, cmd.lane_index])
		return
	
	var enemy: Node = scene.instantiate()
	var spawn_pos: Vector2 = lane_arr[cmd.lane_index].global_position
	
	if cmd.lane in ["N", "S"]: spawn_pos.x += cmd.lane_offset * LANE_GAP
	else: spawn_pos.y += cmd.lane_offset * LANE_GAP
	
	enemy.position  = spawn_pos
	enemy.handedness = BaseEnemy.Handedness.RIGHT \
		if cmd.handedness == "R" else BaseEnemy.Handedness.LEFT
	
	match cmd.direction:
		"N": enemy.direction_enum = BaseEnemy.Direction.NORTH
		"S": enemy.direction_enum = BaseEnemy.Direction.SOUTH
		"E": enemy.direction_enum = BaseEnemy.Direction.EAST
		"W": enemy.direction_enum = BaseEnemy.Direction.WEST
	
	GLOBAL.add_to_game(enemy)
