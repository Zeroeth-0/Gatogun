extends TextureProgressBar

# === TIPOS DE BARRA ===
enum BarType { FEVER, MEDALCTD }
@export var barEnum: BarType                                                    # Tipo de barra

# === VALORES INTERNOS ===
var max_fever: float = SCORE.feverSize                                          # Valor máximo de fever
var max_medalctd: float = 5                                                     # Valor máximo del contador de medallas

func _ready():
	match barEnum:
		BarType.FEVER: set_vals(max_fever)
		BarType.MEDALCTD: set_vals(max_medalctd)

func set_vals(max):
	min_value = 0
	max_value = max
	value = 0  # Inicia en cero

func _process(_delta):
	# Modo Fever: Comportamiento normal
	match barEnum:
		BarType.FEVER: value = SCORE.fever
		BarType.MEDALCTD: value = SCORE.medalCountdown
