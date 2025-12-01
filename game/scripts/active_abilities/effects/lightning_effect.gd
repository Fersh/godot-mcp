extends Node2D

# Lightning effect using Lightning individual frames or sprite sheet
# Used for chain_lightning, thunderstorm, lightning_strike

var sprite: AnimatedSprite2D
var effect_scale: float = 2.0
var use_individual_frames: bool = true  # Use Lightning1-11.png sequence

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	# Offset sprite upward so the lightning strike point (bottom of sprite) lands on the target
	# Sprite is 64x128, scaled by effect_scale, so offset by ~half the scaled height
	sprite.offset = Vector2(0, -44)  # Move sprite up so bottom aligns with position (20px higher)
	add_child(sprite)

	var frames = SpriteFrames.new()
	# SpriteFrames.new() already creates "default" animation, just configure it
	frames.set_animation_speed("default", 24.0)  # Fast lightning
	frames.set_animation_loop("default", false)

	if use_individual_frames:
		# Load individual Lightning frames 1-11
		for i in range(1, 12):
			var path = "res://assets/sprites/effects/Lightning/Lightning%d.png" % i
			if ResourceLoader.exists(path):
				frames.add_frame("default", load(path))
	else:
		# Use sprite sheet version
		var source_path = "res://assets/sprites/effects/lightning1Sprite-sheet.png"
		if ResourceLoader.exists(source_path):
			var source_texture = load(source_path) as Texture2D
			if source_texture:
				var img = source_texture.get_image()
				var total_width = img.get_width()
				var height = img.get_height()
				# Estimate frame count
				var frame_width = height  # Assume square frames
				var frame_count = total_width / frame_width

				for i in range(frame_count):
					var frame_img = Image.create(frame_width, height, false, img.get_format())
					frame_img.blit_rect(img, Rect2i(i * frame_width, 0, frame_width, height), Vector2i.ZERO)
					frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("default")

func _on_animation_finished() -> void:
	queue_free()
