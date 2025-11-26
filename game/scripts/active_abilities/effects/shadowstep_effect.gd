extends Node2D

# Shadowstep teleport effect using phantom spritesheet

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 24.0)
	frames.set_animation_loop("default", false)

	# Load phantom spritesheet - 8x8 grid
	var source_path = "res://assets/sprites/effects/Free Pixel Effects Pack/14_phantom_spritesheet.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var total_height = img.get_height()
			var grid_cols = 8
			var grid_rows = 8
			var frame_width = total_width / grid_cols
			var frame_height = total_height / grid_rows

			for row in range(grid_rows):
				for col in range(grid_cols):
					var frame_img = Image.create(frame_width, frame_height, false, img.get_format())
					frame_img.blit_rect(img, Rect2i(col * frame_width, row * frame_height, frame_width, frame_height), Vector2i.ZERO)
					frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("default")

	# Purple/dark tint for shadow effect
	sprite.modulate = Color(0.7, 0.5, 1.0, 0.9)

func _on_animation_finished() -> void:
	queue_free()
