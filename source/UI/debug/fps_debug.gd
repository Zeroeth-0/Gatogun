extends Label

# This is a debug script
func _process(_delta: float) -> void:
	text = "TICK: %.4f\nFPS: %d\nDELTA: %.4f" % [
		GLOBAL.TICK, 
		Engine.get_frames_per_second(), 
		get_process_delta_time()
	]
