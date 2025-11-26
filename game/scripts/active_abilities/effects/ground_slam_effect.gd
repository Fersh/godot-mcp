extends Node2D

# Ground slam shockwave effect - uses BIG IMPACT SMOKE sprite

var radius: float = 100.0
var duration: float = 0.5

var sprite: AnimatedSprite2D

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(3.0, 3.0)  # Large impact
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 18.0)
	frames.set_animation_loop("default", false)

	# Load BIG IMPACT SMOKE sprite sheet
	var source_path = "res://assets/sprites/effects/slash/BIG IMPACT SMOKE.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var height = img.get_height()
			# Estimate frame count based on aspect ratio
			var frame_count = max(1, int(total_width / height))
			if frame_count < 2:
				frame_count = 6  # Default estimate
			var frame_width = total_width / frame_count

			for i in range(frame_count):
				var frame_img = Image.create(frame_width, height, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_width, 0, frame_width, height), Vector2i.ZERO)
				frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("default")

func _on_animation_finished() -> void:
	queue_free()
