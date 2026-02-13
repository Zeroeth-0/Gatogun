extends Control

const OPTIONS: Array[String] = [
	"NOVICE",
	"RANKED",
	"MANIAC"
]

@onready var labels: Array[Label] = []

# === ESTADO INTERNO ===
var selected: int = 0
var initDelay: float = 0.20     # tiempo antes de empezar la repetición
var repDelay: float  = 0.08     # intervalo entre repeticiones (un poco más rápido que el menú principal)
var deadzone: float  = 0.12     # umbral para stick analógico
var repTimer: float  = 0.0
var lastDir: int     = 0        # -1 = arriba, 0 = nada, 1 = abajo

var first_frame: bool = true

func _ready() -> void:
	var vbox = $VBoxContainer
	
	RANK.reset_all()
	
	for text in OPTIONS:
		var label = Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", 40)
		vbox.add_child(label)
		labels.append(label)
	
	update_selection()

func _process(delta: float) -> void:
	var yAxis = Input.get_axis("ui_up", "ui_down") if Input.get_axis("ui_up", "ui_down") != 0 else INPUT.yAxis
	
	# Dirección actual
	var direction: int = 0
	if yAxis > deadzone:   direction = 1
	elif yAxis < -deadzone: direction = -1
	
	# Detectar cambio de dirección
	if direction != lastDir:
		if direction != 0:
			move_selection(direction == 1)
			repTimer = initDelay
		else:
			repTimer = 0.0
		lastDir = direction
	
	# Repetición mientras se mantiene
	if direction != 0 and repTimer > 0:
		repTimer -= delta
		if repTimer <= 0:
			move_selection(direction == 1)
			repTimer = repDelay
	
	# Confirmar
	if not first_frame:
		if Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A"):
			confirm_selection()
		if Input.is_action_just_pressed("B"): GLOBAL.raw_change_scene("MENU")
	else:
		first_frame = false

func move_selection(is_down: bool) -> void:
	if is_down:
		selected = (selected + 1) % OPTIONS.size()
	else:
		selected = (selected - 1 + OPTIONS.size()) % OPTIONS.size()
	update_selection()

func update_selection() -> void:
	for i in labels.size():
		if i == selected:
			labels[i].modulate = Color.YELLOW
			labels[i].add_theme_font_size_override("font_size", 44)
		else:
			labels[i].modulate = Color.WHITE
			labels[i].add_theme_font_size_override("font_size", 40)

func confirm_selection() -> void:
	# Configuramos la dificultad ANTES de cambiar de escena
	match selected:
		0:  # NOVICE
			RANK.DifficultyStyle = RANK.DifficultyEnum.NOVICE
		1:  # RANKED
			RANK.DifficultyStyle = RANK.DifficultyEnum.RANKED
		2:  # MANIAC
			RANK.DifficultyStyle = RANK.DifficultyEnum.MANIAC
	
	GLOBAL.raw_change_scene("GATO")
