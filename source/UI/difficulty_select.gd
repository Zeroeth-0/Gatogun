extends Control

const OPTIONS: Array[String] = [
	"NOVICE",
	"RANKED",
	"MANIAC"
]

@onready var labels: Array[RichTextLabel] = []
var vbox: VBoxContainer

# === ESTADO INTERNO ===
var selected: int = 0
var initDelay: float = 0.20
var repDelay: float = 0.08
var deadzone: float = 0.12
var repTimer: float = 0.0
var lastDir: int = 0
var first_frame: bool = true

# === ANIMACIONES ===
var can_interact: bool = false
var active_tweens: Array[Tween] = []
var original_positions: Array[float] = []

# === CONFIGURACIÓN DIAGONAL ===
@export var diagonal_offset: float = 0.0
@export var vertical_spacing: int = 80  # Separación vertical entre opciones

func _ready() -> void:
	vbox = $VBoxContainer
	vbox.clip_contents = false
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER  # Alineamiento central
	vbox.add_theme_constant_override("separation", vertical_spacing)  # Mayor separación
	
	RANK.reset_all()
	
	# Cargar la fuente
	var font := load("res://fonts/Super Malibu.ttf")
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	
	for option_text in OPTIONS:
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size = Vector2(400, 50)
		label.clip_contents = false
		
		label.add_theme_font_override("normal_font", font)
		label.add_theme_font_size_override("normal_font_size", 40)
		
		# Outline negro
		label.add_theme_constant_override("outline_size", 27)
		label.add_theme_color_override("outline_color", Color.BLACK)
		
		label.text = "[center]" + option_text + "[/center]"  # Centrar texto
		
		vbox.modulate.a = 0
		vbox.add_child(label)
		labels.append(label)
	
	update_selection()
	
	await get_tree().process_frame
	await get_tree().process_frame
	animate_entry()

func animate_entry() -> void:
	can_interact = true
	var screen_width := get_viewport_rect().size.x
	
	vbox.modulate.a = 1
	await get_tree().process_frame
	
	# Guardar posiciones originales con offset diagonal
	original_positions.clear()
	for i in labels.size():
		var base_x := labels[i].position.x
		var diagonal_x := base_x + (i * diagonal_offset)
		original_positions.append(diagonal_x)
	
	# Animar entrada
	for i in labels.size():
		var label := labels[i]
		label.position.x = screen_width + 100
		
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(label, "position:x", original_positions[i], 0.35).set_delay(i * 0.05)
		active_tweens.append(tween)

func animate_exit(callback: Callable) -> void:
	can_interact = false
	
	# Matar todos los tweens activos
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	active_tweens.clear()
	
	var screen_width := get_viewport_rect().size.x
	
	# Animar salida
	for i in labels.size():
		var tween := create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(labels[i], "position:x", screen_width + 100, 0.25).set_delay((labels.size() - 1 - i) * 0.04)
	
	await get_tree().create_timer((labels.size() - 1) * 0.04 + 0.25).timeout
	callback.call()

func _process(delta: float) -> void:
	if not can_interact:
		return
	
	var yAxis = Input.get_axis("ui_up", "ui_down") if Input.get_axis("ui_up", "ui_down") != 0 else INPUT.yAxis
	
	# Dirección actual
	var direction: int = 0
	if yAxis > deadzone: direction = 1
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
		if Input.is_action_just_pressed("B"):
			animate_exit(func(): GLOBAL.raw_change_scene("MENU"))
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
			labels[i].modulate = Color.WHITE  # Seleccionada = blanca brillante
			shake_label(labels[i])
		else:
			labels[i].modulate = Color(0.2, 0.2, 0.2, 1.0)  # No seleccionadas = oscurecidas

func shake_label(label: RichTextLabel) -> void:
	# Solo hacer shake si hay posiciones guardadas
	if original_positions.is_empty():
		return
	
	var label_index := labels.find(label)
	if label_index == -1:
		return
	
	var shake_tween := create_tween()
	shake_tween.set_ease(Tween.EASE_IN_OUT)
	shake_tween.set_trans(Tween.TRANS_SINE)
	
	var original_x := original_positions[label_index]  # Usar posición guardada
	var shake_amount := 4.0
	
	shake_tween.tween_property(label, "position:x", original_x + shake_amount, 0.04)
	shake_tween.tween_property(label, "position:x", original_x - shake_amount, 0.04)
	shake_tween.tween_property(label, "position:x", original_x + shake_amount, 0.04)
	shake_tween.tween_property(label, "position:x", original_x, 0.04)

func confirm_selection() -> void:
	# Configuramos la dificultad ANTES de cambiar de escena
	match selected:
		0:  # NOVICE
			RANK.DifficultyStyle = RANK.DifficultyEnum.NOVICE
		1:  # RANKED
			RANK.DifficultyStyle = RANK.DifficultyEnum.RANKED
		2:  # MANIAC
			RANK.DifficultyStyle = RANK.DifficultyEnum.MANIAC
	
	animate_exit(func(): GLOBAL.raw_change_scene("GATO"))
