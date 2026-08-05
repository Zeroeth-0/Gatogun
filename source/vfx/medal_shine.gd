extends AnimatedSprite2D

var elapsed_time: float = 0.0

func _ready():
	# Asegurarse de que el material es único
	if material:
		material = material.duplicate()
		
		# Asignar offset aleatorio entre 0 y el ciclo completo
		var shine_duration = material.get_shader_parameter("shine_duration")
		if shine_duration:
			var random_offset = randf() * shine_duration
			material.set_shader_parameter("time_offset", random_offset)
		
		# Inicializar custom_time
		material.set_shader_parameter("custom_time", 0.0)

func _process(delta):
	if material:
		# CLAVE: Solo actualizar tiempo si el juego NO está pausado
		if not get_tree().paused:
			elapsed_time += delta
			material.set_shader_parameter("custom_time", elapsed_time)
