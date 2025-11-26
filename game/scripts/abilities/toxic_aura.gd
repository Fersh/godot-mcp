extends Node2D

var radius: float = 100.0
var pulse_timer: float = 0.0

var sprite: AnimatedSprite2D

func _ready() -> void:
	z_index = -1  # Draw behind player
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(radius / 48.0, radius / 48.0)  # Scale based on radius
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 12.0)
	frames.set_animation_loop("default", true)

	# Load PoisonCast sprite sheet - 96x96 frames
	var source_path = "res://assets/sprites/effects/pack2/PoisonCast_96x96.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var frame_size = 96
			var frame_count = total_width / frame_size

			for i in range(frame_count):
				var frame_img = Image.create(frame_size, frame_size, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_size, 0, frame_size, frame_size), Vector2i.ZERO)
				frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.play("default")

	# Green tint for toxic
	sprite.modulate = Color(0.6, 1.0, 0.6, 0.8)
