extends Node

enum DifficultyEnum { NOVICE, RANKED, MANIAC }
var DifficultyStyle: DifficultyEnum = DifficultyEnum.RANKED

@export_range(1, 6, 1) var rank: int
@export_range(1, 6, 1) var baseRank: int
var medalCombo: int = 0
const THRESHOLD: int = 100
var canDecrease = false

func _process(_delta):
	match DifficultyStyle:
		DifficultyEnum.NOVICE:
			baseRank = 1
			rank = baseRank
		DifficultyEnum.MANIAC:
			baseRank = 6
			rank = baseRank
		DifficultyEnum.RANKED:
			baseRank = 1
			if SCORE.mult < medalCombo: reset_combo()
			if SCORE.hot <= 0 and canDecrease: decrease_rank()
			if medalCombo >= THRESHOLD * rank: increase_rank()
			if SCORE.hot > 0: canDecrease = true

func reset_combo():
	medalCombo = 0

func increase_combo():
	medalCombo += 1

func increase_rank():
	if rank < 6: rank += 1
	else: rank = 6
	reset_combo()

func decrease_rank():
	if rank > 1: rank -= 1
	else: rank = 1
	canDecrease = false
	reset_combo()

func reset_all():
	reset_combo()
	DifficultyStyle = DifficultyEnum.RANKED
	rank = 1
