extends RichTextLabel

# Direction
enum LabelType { GSCORE, COMBO, FEVER }
@export var labelEnum: LabelType

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var outTxt: String
	match labelEnum:
		LabelType.GSCORE: outTxt = "Score: " + str(SCORE.GeneralGameScore)
		LabelType.COMBO: outTxt = "+" + str(SCORE.combo)
		LabelType.FEVER: outTxt = "Fever! " + str(SCORE.fever)
	
	self.text = outTxt
