extends "res://source/items/item.gd"

# === TIPOS DE ITEM ===
enum ItemType { MEDAL, POWERUP, MAXPOWERUP, BOMB, ONEUP }

# === EXPORTABLES CONFIGURABLES ===
@export var itemEnum: ItemType = ItemType.MEDAL                                 # Tipo de item

# === CONSTANTES ===
const COLLECT_HEIGHT_THRESHOLD: float = 250
const FREE_THRESHOLD: float = 800

func _process(delta: float) -> void:
	match itemEnum:
		ItemType.MEDAL: _move_medal(delta) # Movimiento medalla
		_: _move_powerup(delta) # Movimiento potenciador
	
	if GAME.get_player().y < COLLECT_HEIGHT_THRESHOLD: powerUpFollowPlayer = true
	if position.y > FREE_THRESHOLD: queue_free()

func _on_area_entered(area: Node) -> void:
	if isCollected: return
	if area.is_in_group("Collect"):
		isCollected = true  # Bloquea múltiples ejecuciones
		match itemEnum:
			ItemType.MEDAL:
				GAME.innerMedalChain += 1
				SCORE.increase_mult()
			ItemType.POWERUP: WEAPON.lvl_up("ALL")
			ItemType.MAXPOWERUP: WEAPON.lvl_up("MAX")
			ItemType.BOMB:
				var player = get_tree().get_first_node_in_group("Player")
				if player.bombCount < player.maxBombs: player.bombCount += 1
			ItemType.ONEUP: if GAME.lives < 6: GAME.lives += 1
		queue_free()
