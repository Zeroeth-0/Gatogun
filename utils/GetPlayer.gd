extends Node

var player: Node2D

func get_player():
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		player = null
		return GAME.spawnPoint
	else:
		player = players[0]
		return player.global_position
