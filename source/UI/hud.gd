extends Control
# === CONTADORES ===
@export var gameScore: RichTextLabel
@export var highScore: RichTextLabel
@export var comboLabel: RichTextLabel
@export var multLabel: RichTextLabel
# === BARRAS ===
@export var hotBar: TextureProgressBar
@export var medalCountdown: TextureProgressBar
# === CONTENEDORES ===
@export var heartContainer: HBoxContainer
@export var currBombContainer: HBoxContainer
@export var maxBombContainer: HBoxContainer
@export var resource_texture: Texture2D                                         # Textura contenedor
# === VALORES INTERNOS ===
var maxHot: float = SCORE.hotSize
var maxMedalCountdown: float = SCORE.MAX_MEDAL_COUNTDOWN
var currentLives
var currentBombs
var currMaxBombs
# === VARIABLES SHADER ===
var hot_shader_material: ShaderMaterial
# === VARIABLES ANIMACIONES COMBO ===
@export var moveDuration: float = 1.0
var tween: Tween
# === CONSTANTES ESCALA HOT BAR ===
const HOT_BASE_SCALE  := Vector2(0.6, 0.6)
const HOT_PULSE_SCALE := Vector2(0.7, 0.7)
const HOT_PULSE_IN_DURATION  : float = 0.08
const HOT_PULSE_OUT_DURATION : float = 0.18
const HOT_ACTIVE_HOLD        : float = 0.15
# === VARIABLES HOT BAR ANIMATION ===
var hot_pulse_tween: Tween
var hot_active_timer: float = 0.0
var hot_at_base: bool = true
var hot_pulsing: bool = false

func _ready():
	set_bar_vals(hotBar, maxHot)
	set_bar_vals(medalCountdown, maxMedalCountdown)
	hot_shader_material = hotBar.material as ShaderMaterial
	hotBar.scale = HOT_BASE_SCALE

func _process(_delta):
	# Contadores
	gameScore.text = str(SCORE.GeneralGameScore)
	highScore.text = str(SCORE.GeneralGameScore) # Temporal
	comboLabel.text = "+" + str(SCORE.combo)
	multLabel.text = "x" + str(SCORE.mult)
	
	# Ajuste de escala
	_update_label_scale(comboLabel, SCORE.combo, 0.001)
	_update_label_scale(multLabel, SCORE.mult, 0.05)
	
	# Barras
	hotBar.value = SCORE.hot
	medalCountdown.value = SCORE.medalCountdown
	
	# Actualizar shader del hotBar
	_update_hot_shader()
	
	# Contenedores
	currentLives = GAME.lives
	currentBombs = GAME.bombCount
	currMaxBombs = GAME.maxBombs
	
	for child in heartContainer.get_children(): child.queue_free()
	for child in currBombContainer.get_children(): child.queue_free()
	for child in maxBombContainer.get_children(): child.queue_free()
	print_container(heartContainer, currentLives)
	print_container(currBombContainer, currentBombs)
	print_container(maxBombContainer, currMaxBombs)
	
	# Timer inactividad hot bar
	if hot_active_timer > 0.0:
		hot_active_timer -= _delta
		if hot_active_timer <= 0.0:
			_hot_return_to_base()

# === SHADER HOT BAR ===
func _update_hot_shader() -> void:
	if hot_shader_material == null:
		return
	var normalized: float = (SCORE.hot / maxHot) * 2.0 - 1.0
	hot_shader_material.set_shader_parameter("fill_value", normalized)

# === ANIMACIONES HOT BAR ===
func pulse_hot_bar() -> void:
	if hot_pulsing: return
	hot_pulsing = true
	hot_at_base = false
	if hot_pulse_tween: hot_pulse_tween.kill()
	hot_pulse_tween = create_tween()
	hot_pulse_tween.tween_property(hotBar, "scale", HOT_PULSE_SCALE, HOT_PULSE_IN_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hot_pulse_tween.tween_property(hotBar, "scale", HOT_BASE_SCALE, HOT_PULSE_OUT_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	hot_pulse_tween.tween_callback(func():
		hot_pulsing = false
		hot_at_base = true
	)

func keep_hot_bar() -> void:
	hot_active_timer = HOT_ACTIVE_HOLD
	hot_at_base = false
	hot_pulsing = false
	if hot_pulse_tween: hot_pulse_tween.kill()
	hotBar.scale = HOT_PULSE_SCALE

func _hot_return_to_base() -> void:
	if hot_at_base: return
	hot_at_base = true
	hot_pulsing = false
	if hot_pulse_tween: hot_pulse_tween.kill()
	hot_pulse_tween = create_tween()
	hot_pulse_tween.tween_property(hotBar, "scale", HOT_BASE_SCALE, HOT_PULSE_OUT_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

# === IMPRIMIR CONTENEDORES ===
func print_container(container, printCount):
	for i in range(printCount):
		var resource = TextureRect.new()
		resource.texture = resource_texture
		resource.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		container.add_child(resource)

# === VALORES BARRAS ===
func set_bar_vals(currentBar, maxim):
	currentBar.min_value = 0
	currentBar.max_value = maxim
	currentBar.value = 0

# === AJUSTE DE ESCALA ===
func _update_label_scale(label, value: int, factor) -> void:
	var scaleValue = clamp(1.0 + value * factor, 1.0, 2.5)
	label.scale = Vector2(scaleValue, scaleValue)

# === ANIMACIONES COMBO ===
func label_in() -> void:
	_start_tween(Vector2(35, 200))

func label_out() -> void:
	_start_tween(Vector2(-165, 200))

func _start_tween(targetPos: Vector2) -> void:
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(comboLabel, "position", targetPos, moveDuration)\
		 .set_trans(Tween.TRANS_SINE)\
		 .set_ease(Tween.EASE_IN_OUT)
