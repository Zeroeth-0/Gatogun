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
@onready var icons: Array[TextureRect] = []
@onready var names: Array[Label] = []
@onready var slots: Array[VBoxContainer] = []
@onready var desc_label: Label = $VBoxContainer/Label

# === ESTADO ===
var selected: int = 1
var initDelay: float = 0.20
var repDelay: float = 0.10
var deadzone: float = 0.1
var repTimer: float = 0.0
var lastDir: int = 0

var first_frame: bool = true

func _ready() -> void:
	match SelectStyle:
		SelectEnum.GATO: STYLES = GATOS
		SelectEnum.DOLL: STYLES = DOLLS
	# Espera un frame para que TODOS los sizes se calculen antes de recopilar y actualizar
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	var hbox: HBoxContainer = $VBoxContainer/HBoxContainer
	
	# Recopilar slots, iconos y nombres
	for i in STYLES.size():
		var slot: VBoxContainer = hbox.get_child(i)
		slots.append(slot)
		icons.append(slot.get_child(0))
		names.append(slot.get_child(1))
		names[i].text = STYLES[i].name
		
		# Config iconos para visibilidad y scaling
		icons[i].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icons[i].expand_mode = TextureRect.EXPAND_KEEP_SIZE
		icons[i].custom_minimum_size = Vector2(180, 180)
	
	# Setea pivots al centro
	for slot in slots:
		slot.pivot_offset = slot.size / 2
	
	# Actualiza selección inicial
	update_selection()
	
	# Descripción inicial
	if desc_label:
		desc_label.text = STYLES[selected].style + " STYLE"

func _process(delta: float) -> void:
	var xAxis := INPUT.xAxis
	
	var direction: int = 0
	if xAxis > deadzone:   direction = 1
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
			match SelectStyle:
				SelectEnum.GATO: GLOBAL.raw_change_scene("MODE")
				SelectEnum.DOLL: GLOBAL.raw_change_scene("GATO")
	else: first_frame = false

func move_selection(is_right: bool) -> void:
	if is_right: selected = (selected + 1) % STYLES.size()
	else: selected = (selected - 1 + STYLES.size()) % STYLES.size()
	update_selection()

func update_selection() -> void:
	for i in slots.size():
		var is_selected = (i == selected)
		
		# Escala el SLOT ENTERO uniformemente desde el centro
		slots[i].scale = Vector2(1.15, 1.15) if is_selected else Vector2(1.0, 1.0)
		
		# Colores y tamaños de fuente
		if is_selected:
			icons[i].modulate = Color(1.3, 1.3, 1.6)
			names[i].modulate = Color.YELLOW
			names[i].add_theme_font_size_override("font_size", 36)
		else:
			icons[i].modulate = Color.WHITE
			names[i].modulate = Color(0.7, 0.7, 0.7)
			names[i].add_theme_font_size_override("font_size", 28)
	
	if desc_label:
		desc_label.text = STYLES[selected].style + " STYLE"

func confirm_selection() -> void:
	var chosenStyle = STYLES[selected].style
	match SelectStyle:
		SelectEnum.GATO:
			GAME.set_gato(chosenStyle)
			GLOBAL.raw_change_scene("DOLL")
		SelectEnum.DOLL:
			GAME.set_doll(chosenStyle)
			GLOBAL.change_scene("GAME")
