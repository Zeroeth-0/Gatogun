extends HBoxContainer

@export var heart_texture: Texture2D  # Textura del corazón
var current_lives

# Actualiza la cantidad de corazones visibles
func _process(delta):
	current_lives = GAME.lives
	# Limpia los corazones actuales antes de volver a crearlos
	for child in get_children():
		child.queue_free()
	
	# Crea un corazón por cada vida restante
	for i in range(current_lives):
		var heart = TextureRect.new()
		heart.texture = heart_texture
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT  # Mantiene la proporción
		add_child(heart)

