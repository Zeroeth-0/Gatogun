extends Label

# This is a debug script
func _process(_delta):
	text = str(int(Engine.get_frames_per_second())) + " fps"
