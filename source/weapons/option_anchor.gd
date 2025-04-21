extends Marker2D

# === CONFIGURACIÓN EXPORTADA ===
@export var target: Node2D                                                      # Objetivo a seguir
@export_range(0.0, 1.0, 0.01) var followDelay: float = 0.1                      # Retardo del seguimiento
var targetPos: Vector2 = Vector2.ZERO     

# === LOOP PRINCIPAL ===
func _process(delta: float) -> void:
	position = position.lerp(targetPos, followDelay)
