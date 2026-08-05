extends Node2D

# Compensación movimiento cámara
func _enter_tree():
	CAMERA.tracked_nodes.append(self)

func _exit_tree():
	CAMERA.tracked_nodes.erase(self)
