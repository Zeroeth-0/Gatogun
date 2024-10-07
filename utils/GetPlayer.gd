extends Node

var player: Node2D

func get_player():
	player = get_tree().get_nodes_in_group("Player")[0]
	
	if player: return player.position
	else: return Vector2.ZERO
