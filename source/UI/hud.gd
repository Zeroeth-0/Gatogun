extends Control

# === CONTADORES ===
@export var gameScore: RichTextLabel
@export var highScore: RichTextLabel
@export var comboLabel: RichTextLabel
@export var multLabel: RichTextLabel
@export var gameName: RichTextLabel
@export var highName: RichTextLabel
# === COLORES EXPORTABLES ===
@export var playerScoreColor: Color
@export var highScoreColor: Color
# === BARRAS ===
@export var hotBar: TextureProgressBar
@export var medalCountdown: TextureProgressBar
# === CONTENEDORES ===
@export var heartContainer: HBoxContainer
@export var currBombContainer: HBoxContainer
@export var maxBombContainer: HBoxContainer
@export var resource_texture: Texture2D
# === VALORES INTERNOS ===
var maxHot: float = SCORE.hotSize
var maxMedalCountdown: float = SCORE.MAX_MEDAL_COUNTDOWN
var currentLives
var currentBombs
var currMaxBombs
var _prevCombo: int = 0
# === VARIABLES SHADER ===
var hot_shader_material: ShaderMaterial
# === VARIABLES ANIMACIONES COMBO ===
@export var moveDuration: float = 1.0
@export var comboPosIn: Vector2  = Vector2(35, 250)
@export var comboPosOut: Vector2 = Vector2(-165, 250)
var tween: Tween
# === CONSTANTES ESCALA HOT BAR ===
const HOT_BASE_SCALE         := Vector2(0.6, 0.6)
const HOT_PULSE_SCALE        := Vector2(0.7, 0.7)
const HOT_PULSE_IN_DURATION  : float = 0.12
const HOT_PULSE_OUT_DURATION : float = 0.30
const HOT_ACTIVE_HOLD        : float = 0.15
# === EXPORT HOT BAR PULSE RATE ===
@export_range(0.0, 0.5, 0.05) var hotPulseRate: float = 0.35
# === VARIABLES HOT BAR ANIMATION ===
var hot_pulse_tween: Tween
var hot_active_timer: float = 0.0
var hot_at_base: bool = true
var hot_pulsing: bool = false
var hot_pulse_cooldown: float = 0.0
# === FUENTE Y SOMBRA ===
@export var shadowColor: Color = Color(0, 0, 0, 0.6)
@export var shadowOffset: Vector2 = Vector2(2, 2)
@export var shadowSize: int = 1
var _font: Font

func _ready():
	set_bar_vals(hotBar, maxHot)
	set_bar_vals(medalCountdown, maxMedalCountdown)
	hot_shader_material = hotBar.material as ShaderMaterial
	hotBar.scale = HOT_BASE_SCALE
	_load_font()
	_apply_font_to_all_labels()
	comboLabel.position = comboPosOut

	# ── Títulos con wave y color del inspector ──
	gameName.bbcode_enabled = true
	highName.bbcode_enabled = true
	gameName.add_theme_color_override("default_color", playerScoreColor)
	highName.add_theme_color_override("default_color", highScoreColor)
	gameName.text = "[wave amp=48 freq=5.0]PLAYER SCORE[/wave]"
	highName.text = "[wave amp=48 freq=5.0]HIGH SCORE[/wave]"

func _load_font() -> void:
	_font = load("res://fonts/AprilGothicOne-R.ttf") as Font

func _apply_font_to_all_labels() -> void:
	for label in [gameScore, highScore, comboLabel, multLabel, gameName, highName]:
		_setup_rich_label(label)

func _setup_rich_label(label: RichTextLabel) -> void:
	var font := FontVariation.new()
	font.base_font = _font
	font.opentype_features = {"kern": 0, "liga": 0, "calt": 0, "clig": 0}
	label.add_theme_font_override("normal_font", font)
	label.add_theme_color_override("font_shadow_color", shadowColor)
	label.add_theme_constant_override("shadow_offset_x", int(shadowOffset.x))
	label.add_theme_constant_override("shadow_offset_y", int(shadowOffset.y))
	label.add_theme_constant_override("shadow_outline_size", shadowSize)

func _process(_delta):
	gameScore.text = str(SCORE.GeneralGameScore)
	highScore.text = str(SCORE.GeneralGameScore)
	comboLabel.text = "+" + str(SCORE.combo)
	multLabel.text = "x" + str(SCORE.mult)

	if SCORE.combo == 0 and _prevCombo > 0:
		if tween: tween.kill()
		comboLabel.position = comboPosOut
	_prevCombo = SCORE.combo

	_update_label_scale(comboLabel, SCORE.combo, 0.001)
	_update_label_scale(multLabel, SCORE.mult, 0.05, 2.5)

	hotBar.value = SCORE.hot
	medalCountdown.value = SCORE.medalCountdown
	_update_hot_shader()

	currentLives = GAME.lives
	currentBombs = GAME.bombCount
	currMaxBombs = GAME.maxBombs

	for child in heartContainer.get_children(): child.queue_free()
	for child in currBombContainer.get_children(): child.queue_free()
	for child in maxBombContainer.get_children(): child.queue_free()
	print_container(heartContainer, currentLives)
	print_container(currBombContainer, currentBombs)
	print_container(maxBombContainer, currMaxBombs)

	if hot_active_timer > 0.0:
		hot_active_timer -= _delta
		if hot_active_timer <= 0.0:
			_hot_return_to_base()

	if hot_pulse_cooldown > 0.0:
		hot_pulse_cooldown -= _delta

# === SHADER HOT BAR ===
func _update_hot_shader() -> void:
	if hot_shader_material == null:
		return
	var normalized: float = (SCORE.hot / maxHot) * 2.0 - 1.0
	hot_shader_material.set_shader_parameter("fill_value", normalized)

# === ANIMACIONES HOT BAR ===
func pulse_hot_bar() -> void:
	if hot_pulse_cooldown > 0.0:
		return
	hot_pulse_cooldown = hotPulseRate
	hot_at_base = false
	hot_pulsing = true
	if hot_pulse_tween: hot_pulse_tween.kill()
	hotBar.scale = HOT_BASE_SCALE
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
func _update_label_scale(label, value: int, factor, maxScale: float = 2.5) -> void:
	var scaleValue = clamp(1.0 + value * factor, 1.0, maxScale)
	label.scale = Vector2(scaleValue, scaleValue)

# === ANIMACIONES COMBO ===
func label_in() -> void:
	comboLabel.position = comboPosOut
	_start_tween(comboPosIn)

func label_out() -> void:
	_start_tween(comboPosOut)

func _start_tween(targetPos: Vector2) -> void:
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(comboLabel, "position", targetPos, moveDuration)\
		 .set_trans(Tween.TRANS_SINE)\
		 .set_ease(Tween.EASE_IN_OUT)
