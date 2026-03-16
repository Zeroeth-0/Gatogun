extends Sprite2D

@export var compensation: float = 0.05

var last_player_x: float

func _ready() -> void:
	# Registrar en el grupo para que CUSTIME inyecte custom_time automáticamente.
	add_to_group("ShaderHolder")
	# Pausable: el scroll se detiene con el juego igual que el tiempo de CUSTIME.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	last_player_x = GAME.get_player().x

func _process(_delta: float) -> void:
	var player_x := GAME.get_player().x
	var delta_x  := player_x - last_player_x
	position.x   += delta_x * compensation
	last_player_x = player_x

func _enter_tree() -> void:
	CAMERA.tracked_nodes.append(self)

func _exit_tree() -> void:
	CAMERA.tracked_nodes.erase(self)
