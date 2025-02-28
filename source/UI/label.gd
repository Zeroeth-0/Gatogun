extends RichTextLabel

# Direction
enum LabelType { GSCORE, COMBO }
@export var labelEnum: LabelType

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var outTxt: String
	match labelEnum:
		LabelType.GSCORE: outTxt = "Score: " + str(SCORE.GeneralGameScore)
		LabelType.COMBO: outTxt = "+" + str(SCORE.combo)
	
	self.text = outTxt
