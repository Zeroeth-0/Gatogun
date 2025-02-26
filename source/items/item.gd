extends Area2D

enum ItemType {
	MEDAL,
	OPTION
}

@export var itemEnum: ItemType = ItemType.MEDAL
@export var speed = 200
var extraVel: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match itemEnum:
		ItemType.MEDAL: move_towards_player(delta)

func move_towards_player(delta):
	var playerPos = GETPLAYER.get_player()
	var direction = (playerPos - position).normalized()
	position += direction * speed * delta

func _on_area_entered(area):
	if area.is_in_group("Player"): queue_free()
