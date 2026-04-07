extends SubViewport

@onready var playerCam: Camera2D = $PlayerCamera
@onready var textureRect: TextureRect = $TextureRect
@onready var gameViewport = get_tree().get_first_node_in_group("Game").get_viewport()
@export var smoothFactor: float = 0.1
@export var scaleFactor: int = 3

func _physics_process(_delta: float) -> void:
	var target = GAME.get_player() * scaleFactor + textureRect.position
	playerCam.position = playerCam.position.lerp(target, smoothFactor)
	_clamp_to_screen()

func _clamp_to_screen() -> void:
	var half = Vector2(size) / 2.0 / playerCam.zoom
	var min_pos = textureRect.position + half
	var max_pos = textureRect.position + Vector2(gameViewport.size) - half
	playerCam.position.x = clamp(playerCam.position.x, min_pos.x, max_pos.x)
	playerCam.position.y = clamp(playerCam.position.y, min_pos.y, max_pos.y)
