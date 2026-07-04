extends "res://source/items/item.gd"

# === TIPOS DE ITEM ===
enum ItemType { MEDAL, SIDESITEM, ORBITITEM, FOLLOWITEM, BOMB, ONEUP }
enum GrantedStyleEnum { SIDES, ORBIT, FOLLOW }

# === EXPORTABLES CONFIGURABLES ===
@export var itemEnum: ItemType = ItemType.MEDAL                                 # Tipo de item
@export var grantedOptionStyle: GrantedStyleEnum = GrantedStyleEnum.SIDES       # Estilo que otorga

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
				SCORE.increase_mult()
				FLOW.increase_medal_count()
				if SCORE.mult % 2 == 0: SFX.play("medal", -12)
			ItemType.SIDESITEM, ItemType.ORBITITEM, ItemType.FOLLOWITEM: 
				GAME.OptionStyle = grantedOptionStyle as int
				EVENTS.powerup_collected.emit(grantedOptionStyle as int)
			ItemType.BOMB:
				var player = get_tree().get_first_node_in_group("Player")
				if player.bombCount < player.maxBombs: player.bombCount += 1
			ItemType.ONEUP: if GAME.lives < 6: GAME.lives += 1
		queue_free()
