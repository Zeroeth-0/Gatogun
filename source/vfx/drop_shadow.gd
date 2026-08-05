extends TextureRect

func _process(delta):
	var parent = get_parent()
	
	if parent is Sprite2D: texture = parent.texture
	
	if parent is AnimatedSprite2D:
		var animation = parent.animation
		var frame = parent.frame
		texture = parent.sprite_frames.get_frame_texture(animation, frame)
	
	if parent is TextureRect: texture = parent.texture
