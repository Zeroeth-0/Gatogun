extends SubViewport

@onready var playerCam: Camera2D = $PlayerCamera
@export var screenMargin: int
@export var smooth_factor: float = 0.1

func _physics_process(_delta: float) -> void:
	var target = GAME.get_player()
	# Lerp con factor fijo (estilo easing suave)
	playerCam.position = playerCam.position.lerp(target, smooth_factor)
	_clamp_to_screen(get_tree().get_first_node_in_group("Game").get_visible_rect().size)

func _clamp_to_screen(screenSize: Vector2) -> void:
	playerCam.position.x = clamp(playerCam.position.x, screenMargin, screenSize.x - screenMargin)
	playerCam.position.y = clamp(playerCam.position.y, screenMargin, screenSize.y - screenMargin)
