extends Control

@export var countdown_start := 9
var countdown := countdown_start

@export var timerLabel: Label

# Variables para countdown en tiempo real (reemplaza al Timer)
var last_tick: int = 0  # Marca de tiempo del último decremento

func _ready():
	# Inicia el countdown y actualiza label
	countdown = countdown_start
	timerLabel.text = str(countdown)
	last_tick = Time.get_ticks_msec()  # Inicia el reloj real

	# Pausar el juego (mantiene time_scale=0)
	GLOBAL.pause_game()

	# Asegura que este nodo procese siempre (por si no lo seteaste en editor)
	process_mode = PROCESS_MODE_ALWAYS

func _process(_delta):
	# Countdown en tiempo real (cada 1000 ms reales)
	var current_tick = Time.get_ticks_msec()
	if current_tick - last_tick >= 1000:  # 1 segundo real
		countdown -= 1
		timerLabel.text = str(countdown)
		last_tick = current_tick  # Resetea para el próximo segundo
		if countdown <= 0:
			# Lógica de timeout (igual que antes)
			GLOBAL.resume_game()
			GAME.game_over()
			queue_free()

	# Input para acelerar countdown (igual que antes)
	if Input.is_action_just_pressed("A") or \
	   Input.is_action_just_pressed("B") or \
	   Input.is_action_just_pressed("C"):
		countdown = max(countdown - 1, 0)
		timerLabel.text = str(countdown)

	# Input para continuar con Start (igual que antes)
	if Input.is_action_just_pressed("Start"):
		GLOBAL.resume_game()
		GAME.lives = 2
		SCORE.reset_game_score()
		GAME.store(GAME.CENTER, true)
		GAME.spawn()
		queue_free()
