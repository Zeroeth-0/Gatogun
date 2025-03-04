extends TextureProgressBar

@export var max_width: float = 400  # Ancho máximo de la barra
@export var max_fever: int = 100  # Valor máximo de fever

@export var normal_color: Color
@export var fever_color: Color

@export var mode_extend: bool = false  # Activa el modo extendido

var fever_offset: int = 0  # Para el modo extendido

func _ready():
	min_value = 0
	max_value = max_fever
	value = 0  # Inicia en cero

func _process(delta):
	if mode_extend:
		# Modo Extend: Ajusta el offset si se supera un múltiplo de max_fever
		if SCORE.fever >= fever_offset + max_fever:
			fever_offset += max_fever

		if SCORE.rank < 6: value = SCORE.fever - fever_offset
		else: value = 0
	else:
		# Modo Fever: Comportamiento normal
		value = SCORE.fever

	# Cambiar el color dependiendo de SCORE.isFever
	if SCORE.isFever:
		modulate = fever_color
	else:
		modulate = normal_color
