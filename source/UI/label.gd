extends RichTextLabel

# === TIPOS DE TEXTO ===
enum LabelType { GSCORE, COMBO, MULT }
@export var labelEnum: LabelType                                                # Tipo de etiqueta
var yValue

# === ANIMACIÓN ===
@export var moveDuration: float = 1.0                                           # Duración animación
var tween: Tween

func _process(_delta: float) -> void:
	var output: String
	match labelEnum:
		LabelType.GSCORE:
			output = "Score: " + str(SCORE.GeneralGameScore)
		LabelType.COMBO:
			add_to_group("Combo")
			output = "+" + str(SCORE.combo)
			_update_combo_scale(SCORE.combo, 0.001)
		LabelType.MULT:
			output = "x" + str(SCORE.mult)
			_update_combo_scale(SCORE.mult, 0.05)

	text = output

# === ANIMACIONES ===

func label_in() -> void:
	_start_tween(Vector2(35, 160))

func label_out() -> void:
	_start_tween(Vector2(-165, 160))

func _start_tween(targetPos: Vector2) -> void:
	if tween: tween.kill()  # Evita conflictos si hay uno corriendo
	
	tween = create_tween()
	tween.tween_property(self, "position", targetPos, moveDuration)\
		 .set_trans(Tween.TRANS_SINE)\
		 .set_ease(Tween.EASE_IN_OUT)

# === AJUSTE DE ESCALA PARA EL COMBO ===
func _update_combo_scale(combo: int, factor) -> void:
	var scaleValue = clamp(1.0 + combo * factor, 1.0, 2.5)
	scale = Vector2(scaleValue, scaleValue)
