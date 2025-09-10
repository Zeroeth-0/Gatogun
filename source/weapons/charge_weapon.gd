extends Node2D

# === EXPORTS GENERALES ===
@export var bullet_scene: PackedScene
@export var cooldownTime := 2.0  # segundos
@export var sprite: Sprite2D

# === ESTADO INTERNO
var cooldown := 0.0

# === FLUJO DE COMPORTAMIENTO ===
func _ready() -> void:
	cooldown = cooldownTime

func _process(delta: float) -> void:
	# Debug
	if cooldown <= 0.0: sprite.modulate = Color.YELLOW
	else: sprite.modulate = Color.WHITE
	
	if INPUT.firing or INPUT.fireHold:
		if cooldown <= 0.0:
			_spawn_bullet()
			cooldown = cooldownTime
		else: cooldown = cooldownTime
	else: cooldown = max(cooldown - delta, 0.0)

# === DISPARO ===
func _spawn_bullet() -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position - Vector2(0, 100)
	get_tree().current_scene.add_child(bullet)
	print("Bala instanciada")
