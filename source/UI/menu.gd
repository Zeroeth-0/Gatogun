extends Control

const OPTIONS: Array[String] = [
	"GAME START",
	"CARAVAN",
	"PRACTICE",
	"LEADERBOARDS",
	"GALLERY",
	"SETTINGS",
    "EXIT"
]

@onready var labels: Array[Label] = []
@export var gameScene: PackedScene                                              # Escena Game Start
@export var caravanScene: PackedScene                                           # Escena Caravan
@export var practScene: PackedScene                                             # Escena Practice
@export var leaderScene: PackedScene                                            # Escena Leaderboards
@export var galleryScene: PackedScene                                           # Escena Gallery
@export var settScene: PackedScene                                              # Escena Settings

# === ESTADO INTERNO ===
var selected: int = 0
var initDelay: float = 0.20                                                     # Tiempo antes del primer auto-movimiento
var repDelay: float = 0.1                                                       # Intervalo entre auto-movimientos
var deadzone: float = 0.1                                                       # Umbral mínimo para detectar input (para sticks analógicos)
var repTimer: float = 0.0
var lastDir: int = 0                                                            # -1=up, 0=none, 1=down

func _ready() -> void:
	var vbox: VBoxContainer = $VBoxContainer
	for option_text in OPTIONS:
		var label := Label.new()
		label.text = option_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", 32)
		vbox.add_child(label)
		labels.append(label)
	update_selection()

func _process(delta: float) -> void:
	var yAxis := INPUT.yAxis
	
	# Calcular dirección actual
	var direction: int = 0
	if yAxis > deadzone: direction = 1
	elif yAxis < -deadzone: direction = -1
	
	# Cambio dirección
	if direction != lastDir:
		if direction != 0:
			move_selection(direction == 1)
			repTimer = initDelay
		else: repTimer = 0.0
		lastDir = direction
	
	# Input mantenido
	if direction != 0 and repTimer > 0:
		repTimer -= delta
		if repTimer <= 0:
			move_selection(direction == 1)
			repTimer = repDelay
	
	# Confirmar selección
	if Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A"):
		confirm_selection()

func move_selection(is_down: bool) -> void:
	if is_down: selected = (selected + 1) % OPTIONS.size()  # ¡WRAP AROUND! Abajo del todo → arriba
	else: selected = (selected - 1 + OPTIONS.size()) % OPTIONS.size()  # ¡WRAP AROUND! Arriba del todo → abajo
	update_selection()

func update_selection() -> void:
	for i in labels.size():
		if i == selected:
			labels[i].modulate = Color.YELLOW
			labels[i].add_theme_font_size_override("font_size", 36)
		else:
			labels[i].modulate = Color.WHITE
			labels[i].add_theme_font_size_override("font_size", 32)

func confirm_selection() -> void:
	match selected:
		0: game_start()
		1: caravan()
		2: practice()
		3: leaderboards()
		4: gallery()
		5: settings()
		6: exit_game()

# ESQUELETO DE FUNCIONES
func game_start() -> void:
	if gameScene: GLOBAL.change_scene(gameScene)

func caravan() -> void:
	if caravanScene: GLOBAL.change_scene(caravanScene)

func practice() -> void:
	if practScene: GLOBAL.change_scene(practScene)

func leaderboards() -> void:
	if leaderScene: GLOBAL.change_scene(leaderScene)

func gallery() -> void:
	if galleryScene: GLOBAL.change_scene(galleryScene)

func settings() -> void:
	if settScene: GLOBAL.change_scene(settScene)

func exit_game() -> void:
	get_tree().quit()
