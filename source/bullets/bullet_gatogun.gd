extends "res://source/bullets/bullet.gd"

# === EXPORTS GENERALES ===
@export var revenge: bool = false                                               # ¿Devuelta al morir?
@export var medal: PackedScene = preload("res://scenes/items/medal.tscn")       # Item que recompensa

# === ESTADO INTERNO ===
var revHealth := 7

# === FLUJO DE COMPORTAMIENTO ===
func _ready() -> void:
	# Si está en modo "venganza", apunta al jugador directamente
	if revenge:
		direction = (GAME.get_player() - position).normalized()

# === INTERACCIÓN Y FINALIZACIÓN ===
# Muestra la medalla y elimina la bala
func cancel() -> void:
	var item = medal.instantiate()
	get_tree().current_scene.call_deferred("add_child", item)
	item.position = global_position
	queue_free()

func remove() -> void: queue_free()

# Al salir de un área, si es del grupo "Free", elimina la bala
func _on_area_exited(area) -> void:
	if area.is_in_group("Free"): queue_free()

# Al entrar en contacto con fuego, reduce vida o destruye con condiciones
func _on_area_entered(area) -> void:
	if area.is_in_group("Fire") and revenge:
		revHealth -= 1
		if revHealth <= 0 and not isCancelled:
			isCancelled = true  # Bloquea ejecuciones futuras
			var playerPos = GAME.get_player()
			if position.distance_to(playerPos) < 150 or SCORE.medalCountdown >0: cancel()
			else: queue_free()
