extends Control

const OPTIONS := [
	"RESUME",
	"RESTART",
	"BACK TO TITLE",
	"SETTINGS",
    "EXIT"
]

@onready var labels: Array[Label] = []

# === Configuración de navegación ===
var selected: int = 0
var init_delay: float = 0.20
var repeat_delay: float = 0.10
var deadzone: float = 0.1

var repeat_timer: float = 0.0
var last_direction: int = 0

var first_frame: bool = true

func _ready() -> void:
	GLOBAL.pause_game()
	
	# Crear las opciones
	var vbox = $VBoxContainer
	for text in OPTIONS:
		var lbl = Label.new()
		lbl.text = text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.add_theme_font_size_override("font_size", 16)
		vbox.add_child(lbl)
		labels.append(lbl)
	
	update_selection()
	
	mouse_filter = MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	# Navegación vertical
	var y_axis = INPUT.yAxis
	var direction: int = 0
	
	if y_axis > deadzone:      direction = 1
	elif y_axis < -deadzone:   direction = -1
	
	if direction != last_direction:
		if direction != 0:
			_move_selection(direction == 1)
			repeat_timer = init_delay
		else:
			repeat_timer = 0.0
		last_direction = direction
	
	if direction != 0 and repeat_timer > 0:
		repeat_timer -= delta
		if repeat_timer <= 0:
			_move_selection(direction == 1)
			repeat_timer = repeat_delay
	
	# Confirmar selección
	if Input.is_action_just_pressed("A") or Input.is_action_just_pressed("C"):
		_confirm()
	
	# Cerrar pausa con Start o B (solo después del primer frame)
	if !first_frame:
		if Input.is_action_just_pressed("Start") or Input.is_action_just_pressed("B"):
			_resume()
	else: first_frame = false

func _move_selection(down: bool) -> void:
	if down: selected = (selected + 1) % OPTIONS.size()
	else: selected = (selected - 1 + OPTIONS.size()) % OPTIONS.size()
	update_selection()

func update_selection() -> void:
	for i in labels.size():
		var lbl = labels[i]
		if i == selected:
			lbl.modulate = Color.YELLOW
			lbl.add_theme_font_size_override("font_size", 18)
		else:
			lbl.modulate = Color.WHITE
			lbl.add_theme_font_size_override("font_size", 16)

func _confirm() -> void:
	match selected:
		0:  # RESUME
			_resume()
		1:  # RESTART
			GLOBAL.resume_game()
			RANK.reset_all()
			SCORE.reset()
			SCORE.reset_game_score()
			GAME.store(Vector2(10000, 10000), false)
			GLOBAL.change_scene("GAME")
		2:  # BACK TO TITLE
			GAME.playing = false
			GLOBAL.resume_game()
			RANK.reset_all()
			SCORE.reset()
			SCORE.reset_game_score()
			GLOBAL.change_scene("MENU")
		3:  # SETTINGS
			pass
		4:  # EXIT
			GLOBAL.resume_game()
			get_tree().quit()

func _resume() -> void:
	GLOBAL.resume_game()
	queue_free()
