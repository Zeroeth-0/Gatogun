# utils/CustomTime.gd
# Name: CUSTIME
extends Node

## Pausable game time. Inyected in asking shaders
var time: float = 0.0

## Registered materials who get custom_time
var _materials: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	time += delta
	for mat in _materials: mat.set_shader_parameter("custom_time", time)
	
	for node in get_tree().get_nodes_in_group("ShaderHolder"):
		if node is CanvasItem:
			var mat = node.material
			if mat is ShaderMaterial:
				mat.set_shader_parameter("custom_time", time)

# === REGISTRATION API ===
func register(mat: ShaderMaterial) -> void:
	if mat == null:
		push_error("CUSTIME.register(): null material")
		return
	_materials[mat] = true

func unregister(mat: ShaderMaterial) -> void:
	if mat == null: return
	_materials.erase(mat)

func register_node(node: Node) -> void:
	if node is CanvasItem:
		var mat = node.material
		if mat is ShaderMaterial: register(mat as ShaderMaterial)
	for child in node.get_children(): register_node(child)

func unregister_node(node: Node) -> void:
	if node is CanvasItem:
		var mat = node.material
		if mat is ShaderMaterial: unregister(mat as ShaderMaterial)
	for child in node.get_children(): unregister_node(child)
