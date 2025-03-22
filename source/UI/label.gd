extends RichTextLabel

# Dirección
enum LabelType { GSCORE, COMBO, RANK }
@export var labelEnum: LabelType

@export var move_duration: float = 1.0  # Duración en segundos

var tween: Tween

# Llamado cada frame
func _process(delta):
	var outTxt: String
	match labelEnum:
		LabelType.GSCORE: 
			outTxt = "Score: " + str(SCORE.GeneralGameScore)
		LabelType.COMBO:
			add_to_group("Combo")
			outTxt = "+" + str(SCORE.combo)
		LabelType.RANK:
			add_to_group("Rank")
			outTxt = "x" + str(SCORE.rank)
	
	if labelEnum == LabelType.COMBO: _update_combo_size(SCORE.combo)  # Ajustar el tamaño
	self.text = outTxt

# Mueve la etiqueta a (35, 160)
func label_in():
	_start_tween(Vector2(35, 160))

# Mueve la etiqueta a (-165, 160)
func label_out():
	_start_tween(Vector2(-165, 160))

# Configura y ejecuta el Tween
func _start_tween(target_position: Vector2):
	if tween:  # Si ya hay un Tween en ejecución, lo eliminamos
		tween.kill()

	tween = create_tween()
	tween.tween_property(self, "position", target_position, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Ajusta el tamaño del texto según el combo
func _update_combo_size(combo_value: int):
	var new_scale = clamp(1.0 + (combo_value * 0.0001), 1.0, 2.0)  # Escala entre 1.0 y 3.0
	self.scale = Vector2(new_scale, new_scale)
