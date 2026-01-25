extends SubViewport

@onready var playerCam = $PlayerCamera

func _physics_process(_delta):
	playerCam.position = GAME.get_player()
