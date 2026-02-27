extends Node2D

# === EXPORTS GENERALES ===
@export var bullet_scene: PackedScene
@export var cooldownTime := 1.5
@export var sprite: Sprite2D

# === ESTADO INTERNO ===
var cooldown := 0.0
var _shader_mat: ShaderMaterial

# === FLUJO DE COMPORTAMIENTO ===
func _ready() -> void:
	cooldown = cooldownTime
	# Obtén el ShaderMaterial del sprite una sola vez
	_shader_mat = sprite.material as ShaderMaterial

func _process(delta: float) -> void:
	# Actualiza el uniform charge (0 = recargando, 1 = listo)
	var charge = 1.0 - clamp(cooldown / cooldownTime, 0.0, 1.0)
	if _shader_mat:
		_shader_mat.set_shader_parameter("charge", charge)

	if INPUT.firing or INPUT.fireHold:
		if cooldown <= 0.0:
			_spawn_bullet()
			cooldown = cooldownTime
		else:
			cooldown = cooldownTime
	else:
		cooldown = max(cooldown - delta, 0.0)

# === DISPARO ===
func _spawn_bullet() -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position - Vector2(0, 100)
	GLOBAL.add_to_game(bullet)
