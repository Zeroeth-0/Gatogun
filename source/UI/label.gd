extends RichTextLabel

# Direction
enum LabelType { GSCORE, COMBO, RANK }
@export var labelEnum: LabelType

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var outTxt: String
	match labelEnum:
		LabelType.GSCORE: outTxt = "Score: " + str(SCORE.GeneralGameScore)
		LabelType.COMBO: outTxt = "+" + str(SCORE.combo)
		LabelType.RANK: outTxt = "Rank: " + str(SCORE.rank)
	
	self.text = outTxt
