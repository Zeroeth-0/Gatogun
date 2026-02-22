extends Node2D

@export var compensation: float = 0.3

var tracked_nodes: Array = []
var last_player_x: float

func _ready() -> void:
	last_player_x = GAME.get_player().x

func _process(_delta: float) -> void:
	var player_x: float = GAME.get_player().x
	var delta_x: float = player_x - last_player_x
	var move: float = delta_x * compensation

	for node in tracked_nodes:
		node.position.x -= move

	last_player_x = player_x
