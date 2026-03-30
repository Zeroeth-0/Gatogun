# utils/CameraManager.gd
# Name: CAMERA
extends Node2D

@export var compensation: float = 0.3

## Array containing every affected node
var tracked_nodes: Array[Node] = []

var _last_player_x: float = 0.0
var _cleanup_timer: float = 0.0
const CLEANUP_INTERVAL: float = 2.0 # Purges dead references every 2sec

func _process(delta: float) -> void:
	var player_x := GAME.get_player().x
	var delta_x := player_x - _last_player_x
	var move := delta_x * compensation
	
	for node in tracked_nodes:
		if is_instance_valid(node): node.position.x -= move
	
	_last_player_x = player_x
	
	# Periodic purge to remove dead references
	_cleanup_timer += delta
	if _cleanup_timer >= CLEANUP_INTERVAL:
		_cleanup_timer = 0.0
		_purge_dead_references()

func _purge_dead_references() -> void:
	var before := tracked_nodes.size()
	tracked_nodes = tracked_nodes.filter(
		func(n: Node) -> bool: return is_instance_valid(n)
	)
	
	var removed := before - tracked_nodes.size()
	if removed > 0:
		push_warning(
			"CAMERA: %d dead references purged. "\
			+ "Some node didn't erase itself."\
			% removed
		)
