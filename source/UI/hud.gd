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
# === VARIABLES ANIMACIONES ===
@export var moveDuration: float = 1.0
var tween: Tween

func _ready():
	set_bar_vals(hotBar, maxHot)
	set_bar_vals(medalCountdown, maxMedalCountdown)
	# Guardar referencia al ShaderMaterial del hotBar
	hot_shader_material = hotBar.material as ShaderMaterial

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

# === SHADER HOT BAR ===
func _update_hot_shader() -> void:
	if hot_shader_material == null:
		return
	# Mapea SCORE.hot de [0, maxHot] → [-1, 1]
	# 0       → -1.0 (esfera vacía)
	# maxHot  →  1.0 (esfera llena)
	var normalized: float = (SCORE.hot / maxHot) * 2.0 - 1.0
	hot_shader_material.set_shader_parameter("fill_value", normalized)

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

# === ANIMACIONES ===
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
