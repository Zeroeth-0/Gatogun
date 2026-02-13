extends Control

# === CONFIGURACIÓN ===
const GATOS: Array[Dictionary] = [
	{"name": "ZEBE",  "style": "DAMAGE"},
	{"name": "FUKU",   "style": "RANGE"},
	{"name": "SERGIO", "style": "CLASSIC"},
]
const DOLLS: Array[Dictionary] = [
	{"name": "STRONG",  "style": "STRONG"},
	{"name": "SPEED",   "style": "SPEED"},
	{"name": "NEWBIE", "style": "NEWBIE"},
]

var STYLES: Array[Dictionary]
enum SelectEnum { GATO, DOLL }
@export var SelectStyle: SelectEnum = SelectEnum.GATO

# === NODOS ===
@onready var desc_label: Label = $Label
@onready var cards: Array[VBoxContainer] = []

# === ESTADO ===
var selected: int = 1
var initDelay: float = 0.15
var repDelay: float = 0.08
var deadzone: float = 0.1
var repTimer: float = 0.0
var lastDir: int = 0
var first_frame: bool = true
var is_animating: bool = false

# === CONFIGURACIÓN BARAJA - AJUSTA ESTAS VARIABLES ===
@export var card_spacing: float = 200.0           # Distancia horizontal entre cartas
@export var back_card_y_offset: float = 60.0      # Cuánto bajan las cartas laterales
@export var back_card_scale: float = 0.85         # Escala de las cartas laterales (0.85 = 85%)
@export var center_offset_x: float = -65.0        # Ajuste horizontal del centro (+derecha, -izquierda)
@export var center_offset_y: float = -50.0        # Ajuste vertical del centro (+abajo, -arriba)
@export var animation_speed: float = 0.15         # Velocidad de animación (menor = más rápido)

# === ANIMACIONES ===
var active_tweens: Array[Tween] = []
var can_interact: bool = false

func _ready() -> void:
	match SelectStyle:
		SelectEnum.GATO: STYLES = GATOS
		SelectEnum.DOLL: STYLES = DOLLS
	
	# Cargar la fuente
	var font := load("res://fonts/Super Malibu.ttf")
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	
	# Recopilar los 3 VBoxContainer
	for i in range(3):
		var vbox: VBoxContainer = get_child(i + 1)
		cards.append(vbox)
		
		# Obtener y configurar los hijos
		var name_label: Label = vbox.get_child(1)
		name_label.text = STYLES[i].name
		
		# Aplicar fuente y configuración
		name_label.add_theme_font_override("font", font)
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_constant_override("outline_size", 13)
		name_label.add_theme_color_override("outline_color", Color.BLACK)
		
		# Hacer invisibles al inicio
		vbox.modulate.a = 0
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Configurar pivot y escala
	for card in cards:
		card.pivot_offset = card.size / 2
		card.scale = Vector2(2.0, 2.0)
	
	await get_tree().process_frame
	
	# Setup inicial sin animación
	update_selection(false)
	
	# Guardar posiciones finales y colocar cartas fuera de pantalla (derecha)
	var final_positions: Array[Vector2] = []
	for card in cards:
		final_positions.append(card.position)
		card.position.x = GAME.CENTER.x + 600  # Fuera de pantalla a la derecha
	
	# Animar entrada desde la derecha con delay escalonado
	for i in cards.size():
		var card = cards[i]
		var delay = i * 0.1  # Delay entre cartas para efecto de reparto
		
		await get_tree().create_timer(delay).timeout
		
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_parallel(true)
		tween.tween_property(card, "position:x", final_positions[i].x, 0.4)
		tween.tween_property(card, "modulate:a", 1.0, 0.3)
	
	# Esperar a que termine la última animación
	await get_tree().create_timer(0.4).timeout
	
	if desc_label:
		desc_label.text = STYLES[selected].style + " STYLE"
	
	can_interact = true

func _process(delta: float) -> void:
	if not can_interact or is_animating:
		return
	
	var xAxis := INPUT.xAxis
	
	var direction: int = 0
	if xAxis > deadzone: direction = 1
	elif xAxis < -deadzone: direction = -1
	
	if direction != lastDir:
		if direction != 0:
			move_selection(direction == 1)
			repTimer = initDelay
		else:
			repTimer = 0.0
		lastDir = direction
	
	if direction != 0 and repTimer > 0:
		repTimer -= delta
		if repTimer <= 0:
			move_selection(direction == 1)
			repTimer = repDelay
	
	if !first_frame:
		if Input.is_action_just_pressed("C") or Input.is_action_just_pressed("A"):
			confirm_selection()
		if Input.is_action_just_pressed("B"):
			animate_exit()
	else:
		first_frame = false

func move_selection(is_right: bool) -> void:
	if is_animating:
		return
	
	if is_right: 
		selected = (selected + 1) % STYLES.size()
	else: 
		selected = (selected - 1 + STYLES.size()) % STYLES.size()
	
	update_selection()

func get_card_offset(card_index: int) -> int:
	var direct_offset := card_index - selected
	
	# Normalizar a rango [-1, 0, 1]
	if direct_offset == 2:
		return -1
	elif direct_offset == -2:
		return 1
	else:
		return direct_offset

func update_selection(animate: bool = true) -> void:
	if animate:
		is_animating = true
	
	# Limpiar tweens previos
	if animate:
		for tween in active_tweens:
			if tween and tween.is_valid():
				tween.kill()
		active_tweens.clear()
	
	var screen_center := GAME.CENTER
	
	for i in cards.size():
		var card := cards[i]
		
		# Calcular offset con wrapping inteligente
		var offset := get_card_offset(i)
		var is_center := (offset == 0)
		
		# Escala según si es central o no
		var target_scale_value := 2.0 if is_center else (2.0 * back_card_scale)
		var target_scale := Vector2(target_scale_value, target_scale_value)
		
		# Posición con offsets ajustables
		var target_x := screen_center.x + (offset * card_spacing) + center_offset_x
		var target_y := screen_center.y + center_offset_y
		
		# Las cartas laterales bajan un poco
		if not is_center:
			target_y += back_card_y_offset
		
		# Z-index: carta central siempre arriba
		if is_center:
			card.z_index = 100
		else:
			card.z_index = 10 + offset
		
		# Colores
		var icon: TextureRect = card.get_child(0)
		var name_label: Label = card.get_child(1)
		
		var content_color := Color.WHITE if is_center else Color(0.2, 0.2, 0.2, 1.0)
		
		if animate:
			var tween := create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_parallel(true)
			
			tween.tween_property(card, "position:x", target_x, animation_speed)
			tween.tween_property(card, "position:y", target_y, animation_speed)
			tween.tween_property(card, "scale", target_scale, animation_speed)
			tween.tween_property(icon, "modulate", content_color, animation_speed * 0.66)
			tween.tween_property(name_label, "modulate", content_color, animation_speed * 0.66)
			
			active_tweens.append(tween)
			
			if i == cards.size() - 1:
				tween.finished.connect(func(): is_animating = false)
		else:
			card.position = Vector2(target_x, target_y)
			card.scale = target_scale
			icon.modulate = content_color
			name_label.modulate = content_color
		
		name_label.add_theme_font_size_override("font_size", 20)
	
	if desc_label:
		desc_label.text = STYLES[selected].style + " STYLE"

func animate_exit() -> void:
	can_interact = false
	is_animating = true
	
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	active_tweens.clear()
	
	# Animar salida hacia la derecha con delay escalonado
	for i in cards.size():
		var card = cards[i]
		var delay = i * 0.08  # Delay entre cartas
		
		# Crear timer para el delay sin await
		get_tree().create_timer(delay).timeout.connect(func():
			var tween := create_tween()
			tween.set_ease(Tween.EASE_IN)
			tween.set_trans(Tween.TRANS_CUBIC)  # Cambiado de BACK a CUBIC para quitar rebote
			tween.set_parallel(true)
			
			tween.tween_property(card, "position:x", GAME.CENTER.x + 600, 0.3)
			tween.tween_property(card, "modulate:a", 0.0, 0.25)
		)
	
	await get_tree().create_timer(0.5).timeout
	
	match SelectStyle:
		SelectEnum.GATO: GLOBAL.raw_change_scene("MODE")
		SelectEnum.DOLL: GLOBAL.raw_change_scene("GATO")

func confirm_selection() -> void:
	can_interact = false
	is_animating = true
	var chosenStyle = STYLES[selected].style
	
	# Animar salida hacia la derecha con delay escalonado
	for i in cards.size():
		var card = cards[i]
		var delay = i * 0.08  # Delay entre cartas
		
		# Crear timer para el delay sin await
		get_tree().create_timer(delay).timeout.connect(func():
			var tween := create_tween()
			tween.set_ease(Tween.EASE_IN)
			tween.set_trans(Tween.TRANS_CUBIC)  # Cambiado de BACK a CUBIC para quitar rebote
			tween.set_parallel(true)
			
			tween.tween_property(card, "position:x", GAME.CENTER.x + 600, 0.3)
			tween.tween_property(card, "modulate:a", 0.0, 0.25)
		)
	
	await get_tree().create_timer(0.5).timeout
	
	match SelectStyle:
		SelectEnum.GATO:
			GAME.set_gato(chosenStyle)
			GLOBAL.raw_change_scene("DOLL")
		SelectEnum.DOLL:
			GAME.set_doll(chosenStyle)
			GLOBAL.change_scene("GAME")
