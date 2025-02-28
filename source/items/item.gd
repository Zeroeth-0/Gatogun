extends Area2D

enum ItemType {
	MEDAL,
	OPTION
}

@export var itemEnum: ItemType = ItemType.MEDAL
@export var speed = 200
@export var label: Label
var extraVel: Vector2 = Vector2.ZERO
var medalVal: int = 5

func get_distance(pos):
	var distance = pos.distance_to(GETPLAYER.get_player())
	if distance < 200: medalVal = 5
	elif distance < 275: medalVal = 4
	elif distance < 350: medalVal = 3
	elif distance < 425: medalVal = 2
	else: medalVal = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match itemEnum:
		ItemType.MEDAL: medal_behavior(delta)

func medal_behavior(delta):
	move_towards_player(delta)
	label.text = str(medalVal)
	match medalVal:
		5: global_scale = Vector2(1, 1)
		4: global_scale = Vector2(0.9, 0.9)
		3: global_scale = Vector2(0.8, 0.8)
		2: global_scale = Vector2(0.7, 0.7)
		1: global_scale = Vector2(0.6, 0.6)

func move_towards_player(delta):
	var playerPos = GETPLAYER.get_player()
	var direction = (playerPos - position).normalized()
	position += direction * speed * delta

func _on_area_entered(area):
	if area.is_in_group("Player"):
		SCORE.add_score(SCORE.combo * medalVal)
		SCORE.increase_fever(medalVal)
		queue_free()
