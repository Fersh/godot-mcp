extends Node2D

# Frost Nova - uses IceShatter_96x96 sprite sheet

var radius: float = 100.0
var color: Color = Color(0.5, 0.8, 1.0, 0.8)
var duration: float = 0.5

var sprite: AnimatedSprite2D

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(2.0, 2.0)  # Scale based on radius
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 22.0)
	frames.set_animation_loop("default", false)

	# Load IceShatter sprite sheet
	var source_path = "res://assets/sprites/effects/pack2/IceShatter_96x96.png"
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
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("default")

func _on_animation_finished() -> void:
	queue_free()
