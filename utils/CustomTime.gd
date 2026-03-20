# CUSTIME
extends Node

var time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	time += delta
	for node in get_tree().get_nodes_in_group("ShaderHolder"):
		var mat = null
		if node is CanvasItem:
			mat = node.material
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("custom_time", time)
