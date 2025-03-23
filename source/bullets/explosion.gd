extends AnimatedSprite2D

@export var sfx: AudioStreamPlayer2D

func _ready():
	var audio = AudioStreamPlayer2D.new()
	audio.stream = sfx.stream
	audio.global_position = global_position  # Mantener la posición del sonido
	get_tree().current_scene.add_child(audio)  # Agregar a la escena actual
	
	audio.pitch_scale = randf_range(0.5, 1.5)
	audio.volume_db = -10
	audio.play()
	# Eliminar el nodo de sonido después de que termine
	audio.connect("finished", audio.queue_free)

func _on_animation_finished():
	queue_free()
