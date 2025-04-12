extends HBoxContainer

@export var heart_texture: Texture2D                                            # Textura de la vida extra
var current_lives

# Actualiza la cantidad de vidas extra visibles
func _process(_delta):
	current_lives = GAME.lives
	# Limpia las vidas extra actuales antes de volver a crearlas
	for child in get_children(): child.queue_free()
	
	# Crea un corazón por cada vida restante
	for i in range(current_lives):
		var heart = TextureRect.new()
		heart.texture = heart_texture
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT  # Mantiene la proporción
		add_child(heart)

