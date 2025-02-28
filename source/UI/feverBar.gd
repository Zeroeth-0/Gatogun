extends TextureProgressBar

@export var max_width: float = 400  # Ancho máximo de la barra
@export var max_fever: int = 100  # Valor máximo de fever

@export var normal_color: Color
@export var fever_color: Color

func _ready():
	min_value = 0
	max_value = max_fever
	value = 0  # Inicia en cero

func _process(delta):
	value = SCORE.fever  # Actualizar el valor de la barra
	
	# Cambiar el color dependiendo de SCORE.isFever
	if SCORE.isFever:
		modulate = fever_color
	else:
		modulate = normal_color
