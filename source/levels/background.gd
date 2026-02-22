extends Sprite2D

@export var compensation: float = 0.05

var tracked_nodes: Array = []
var last_player_x: float

func _ready() -> void:
	last_player_x = GAME.get_player().x

func _process(_delta: float) -> void:
	var player_x: float = GAME.get_player().x
	var delta_x: float = player_x - last_player_x
	var move: float = delta_x * compensation
	
	position.x += move
	last_player_x = player_x

# Compensación movimiento cámara
func _enter_tree():
	CAMERA.tracked_nodes.append(self)

func _exit_tree():
	CAMERA.tracked_nodes.erase(self)
