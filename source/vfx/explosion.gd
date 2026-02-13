extends ColorRect

@export var explosion_duration: float = 2.0
@export var explosion_size: float = 5.0

var elapsed_time: float = 0.0
var shader_material: ShaderMaterial

func _ready():
	if material:
		shader_material = material.duplicate()
		material = shader_material
		
		# NUEVO: Semilla aleatoria para cada explosión
		var random_seed = randf() * 1000.0
		
		shader_material.set_shader_parameter("duration", explosion_duration)
		shader_material.set_shader_parameter("size", explosion_size)
		shader_material.set_shader_parameter("custom_time", 0.0)
		shader_material.set_shader_parameter("seed", random_seed)

func _process(delta):
	if shader_material:
		elapsed_time += delta
		shader_material.set_shader_parameter("custom_time", elapsed_time)
		
		if elapsed_time >= explosion_duration:
			if get_parent() is Node2D:
				get_parent().queue_free()
			else:
				queue_free()
