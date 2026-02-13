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

@onready var labels: Array[RichTextLabel] = []
var vbox: VBoxContainer

# === ESTADO INTERNO ===
var selected: int = 0
var initDelay: float = 0.20
var repDelay: float = 0.1
var deadzone: float = 0.1
var repTimer: float = 0.0
var lastDir: int = 0
var first_frame: bool = true

# === ANIMACIONES ===
var can_interact: bool = false
var active_tweens: Array[Tween] = []  # Para matar tweens cuando salgamos

func _ready() -> void:
	vbox = $VBoxContainer
	
	# Cargar la fuente
	var font := load("res://fonts/Super Malibu.ttf")
	# Configurar antialiasing para evitar pixelación
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	
	for option_text in OPTIONS:
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size = Vector2(400, 50)  # Dar tamaño mínimo para que no se aplaste
		
		# Añadir padding izquierdo para que quepa el outline completo
		label.add_theme_constant_override("text_margin_left", 25)
		
		# Aplicar fuente con tamaño
		label.add_theme_font_override("normal_font", font)
		label.add_theme_font_size_override("normal_font_size", 32)
		
		# Outline negro
		label.add_theme_constant_override("outline_size", 6)
		label.add_theme_color_override("outline_color", Color.BLACK)
		
		# Drop shadow
		label.add_theme_constant_override("shadow_offset_x", 4)
		label.add_theme_constant_override("shadow_offset_y", 4)
		label.add_theme_color_override("shadow_color", Color(0, 0, 0, 0.75))
		
		label.text = option_text
		
		vbox.modulate.a = 0  # Invisible al inicio para evitar flash
		vbox.add_child(label)
		labels.append(label)
	
	update_selection()
	
	# Esperar frames para que el layout se calcule
	await get_tree().process_frame
	await get_tree().process_frame
	animate_entry()

func animate_entry() -> void:
	can_interact = true
	var screen_width := get_viewport_rect().size.x
	
	# Hacer visible primero para que el layout se calcule
	vbox.modulate.a = 1
	
	# Esperar un frame más para que el layout esté 100% calculado
	await get_tree().process_frame
	
	# AHORA guardar posiciones originales (ya calculadas por el VBoxContainer)
	var original_positions: Array[float] = []
	for label in labels:
		original_positions.append(label.position.x)
	
	# Animar entrada con delay escalonado
	for i in labels.size():
		var label := labels[i]
		var original_x := original_positions[i]
		
		# Mover fuera de pantalla
		label.position.x = screen_width + 100
		
		# Crear tween
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(label, "position:x", original_x, 0.35).set_delay(i * 0.05)
		active_tweens.append(tween)

func animate_exit(callback: Callable) -> void:
	can_interact = false
	
	# MATAR TODOS LOS TWEENS ACTIVOS para evitar snapping
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	active_tweens.clear()
	
	var screen_width := get_viewport_rect().size.x
	
	# Animar salida en orden inverso
	for i in labels.size():
		var tween := create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(labels[i], "position:x", screen_width + 100, 0.25).set_delay((labels.size() - 1 - i) * 0.04)
	
	# Ejecutar callback cuando termine
	await get_tree().create_timer((labels.size() - 1) * 0.04 + 0.25).timeout
	callback.call()

func _process(delta: float) -> void:
	if not can_interact:
		return
		
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
	if !first_frame:
		if Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A"):
			confirm_selection()
		if Input.is_action_just_pressed("B"): 
			animate_exit(func(): GLOBAL.change_scene("TITLE"))
	else: first_frame = false

func move_selection(is_down: bool) -> void:
	if is_down: selected = (selected + 1) % OPTIONS.size()
	else: selected = (selected - 1 + OPTIONS.size()) % OPTIONS.size()
	update_selection()

func update_selection() -> void:
	for i in labels.size():
		if i == selected:
			labels[i].modulate = Color.YELLOW
			# Agitación rápida SOLO una vez al seleccionar
			shake_label(labels[i])
		else:
			labels[i].modulate = Color.WHITE

func shake_label(label: RichTextLabel) -> void:
	# Agitación rápida de ida y vuelta
	var shake_tween := create_tween()
	shake_tween.set_ease(Tween.EASE_IN_OUT)
	shake_tween.set_trans(Tween.TRANS_SINE)
	
	var original_x := label.position.x
	var shake_amount := 4.0
	
	# Sacudir izquierda-derecha-centro muy rápido
	shake_tween.tween_property(label, "position:x", original_x + shake_amount, 0.04)
	shake_tween.tween_property(label, "position:x", original_x - shake_amount, 0.04)
	shake_tween.tween_property(label, "position:x", original_x + shake_amount, 0.04)
	shake_tween.tween_property(label, "position:x", original_x, 0.04)

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
	animate_exit(func(): GLOBAL.raw_change_scene("MODE"))

func caravan() -> void:
	pass # animate_exit(func(): GLOBAL.raw_change_scene("CARAVAN"))

func practice() -> void:
	pass # animate_exit(func(): GLOBAL.raw_change_scene("PRACTICE"))

func leaderboards() -> void:
	pass # animate_exit(func(): GLOBAL.raw_change_scene("LEADERBOARDS"))

func gallery() -> void:
	pass # animate_exit(func(): GLOBAL.raw_change_scene("GALLERY"))

func settings() -> void:
	pass # animate_exit(func(): GLOBAL.raw_change_scene("SETTINGS"))

func exit_game() -> void:
	animate_exit(func(): get_tree().quit())
