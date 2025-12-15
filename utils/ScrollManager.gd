extends Node

@export var scroll: int = 75                                                    # Velocidad scroll

enum Direction { NORTH, WEST, SOUTH, EAST }
@export var directionEnum: Direction = Direction.SOUTH                          # Dirección de scroll
var DIRECTION_MAP = {
	Direction.NORTH: Vector2(0, -1).normalized(),
	Direction.SOUTH: Vector2(0, 1).normalized(),
	Direction.WEST: Vector2(-1, 0).normalized(),
	Direction.EAST: Vector2(1, 0).normalized()
}
var direction: Vector2 = Vector2(0, 1)

func _process(_delta):
	# print(get_tree().get_nodes_in_group("Enemy Bullet").size())
	direction = DIRECTION_MAP.get(directionEnum)

func get_scroll():
	return direction * scroll

func set_scroll(newScroll, newDir):
	scroll = newScroll
	match newDir:
		"NORTH": directionEnum = Direction.NORTH
		"SOUTH": directionEnum = Direction.SOUTH
		"WEST": directionEnum = Direction.WEST
		"EAST": directionEnum = Direction.EAST
