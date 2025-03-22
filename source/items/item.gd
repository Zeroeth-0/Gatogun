extends Area2D

enum ItemType {
	MEDAL,
	OTHER
}

@export var itemEnum: ItemType = ItemType.MEDAL
@export var speed: float = 200.0
@export var grav: float = 800.0  # Fuerza de gravedad
@export var launch_force: float = 200.0  # Fuerza del disparo inicial
@export var delay_before_follow: float = 0.5  # Tiempo antes de que empiecen a seguir al jugador

var velocity: Vector2 = Vector2.ZERO
var following_player: bool = false

func _ready():
	var angle = randf_range(-PI / 20, PI / 20)
	velocity = Vector2(randf_range(-launch_force, launch_force), -launch_force).rotated(angle)

	# Esperar antes de empezar a seguir al jugador
	await get_tree().create_timer(delay_before_follow).timeout
	following_player = true

func _process(delta):
	if following_player:
		move_towards_player(delta)
	else:
		# Aplicar gravedad y movimiento inicial
		velocity.y += grav * delta  # Simula la gravedad
		position += velocity * delta

func move_towards_player(delta):
	var playerPos = GETPLAYER.get_player()
	var direction = (playerPos - position).normalized()
	position += direction * speed * delta

func _on_area_entered(area):
	if area.is_in_group("Collect"):
		SCORE.add_score(SCORE.combo / 2)
		queue_free()
