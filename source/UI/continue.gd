extends Control

@export var countdown_start := 9
var countdown := countdown_start

@export var timerLabel: Label
var countdown_timer : Timer

func _ready():
	# Crear el timer si no está en la escena
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.one_shot = false
	countdown_timer.autostart = true
	add_child(countdown_timer)
	countdown_timer.timeout.connect(_on_timer_timeout)

	# Pausar todo menos esta escena
	get_tree().paused = true

	timerLabel.text = str(countdown)

func _process(_delta):
	if Input.is_action_just_pressed("A") or \
	   Input.is_action_just_pressed("B") or \
	   Input.is_action_just_pressed("C"):  # A, B, C por defecto
		countdown = max(countdown - 1, 0)
		timerLabel.text = str(countdown)

	if Input.is_action_just_pressed("Start"):  # Start
		get_tree().paused = false
		GAME.lives = 2
		SCORE.reset_game_score()
		GAME.store(GAME.CENTER, true)
		GAME.spawn()
		queue_free()

func _on_timer_timeout():
	countdown -= 1
	timerLabel.text = str(countdown)
	if countdown <= 0:
		# Aquí puedes decidir si terminar el juego o ir al menú principal
		get_tree().paused = false
		GAME.game_over()
		queue_free()
