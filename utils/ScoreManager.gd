extends Node

# Parámetros generales
var GeneralGameScore: int = 0
var weakPts: int = 15000
var elitePts: int = 25000

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_dead_enemy(size, extraPts):
	var pts: int = 0
	match size:
		"Weak": pts += weakPts
		"Elite": pts += elitePts
	
	if extraPts: pts += pts / 2
	add_score(pts)

func add_score(scoreVal):
	GeneralGameScore += scoreVal
	print(GeneralGameScore)
