extends HBoxContainer

# === ENUM DE TIPOS DE ÍTEMS ===
enum ResourceType { LIVES, BOMBS }

# === EXPORTABLES CONFIGURABLES ===
@export var resourceEnum: ResourceType = ResourceType.LIVES                     # Tipo de item
@export var resource_texture: Texture2D                                         # Textura a mostrar
var currentLives
var currentBombs
var printCount

# Actualiza la cantidad de vidas extra visibles
func _process(_delta):
	currentLives = GAME.lives
	currentBombs = GAME.bombCount
	# Limpia las vidas extra actuales antes de volver a crearlas
	for child in get_children(): child.queue_free()
	
	match resourceEnum:
		ResourceType.LIVES: printCount = currentLives
		ResourceType.BOMBS: printCount = currentBombs
	
	# Crea un corazón por cada vida restante
	for i in range(printCount):
		var resource = TextureRect.new()
		resource.texture = resource_texture
		resource.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT  # Mantiene la proporción
		add_child(resource)
