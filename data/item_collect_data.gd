# data/item_collect_data.gd

# Built and issued on catching an item
class_name ItemCollectData
extends RefCounted

## Item type
var item_type: int
var position: Vector2

## Type specific
var new_mult: int
var weapon_id: StringName
var new_weapon_lvl: int

func _init (p_type: int, p_position: Vector2) -> void:
	item_type = p_type
	position = p_position
