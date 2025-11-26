extends Node2D

# Animated pixel explosion effect using Explosion sprite sheets from pack2

var sprite: AnimatedSprite2D
var scale_multiplier: float = 1.5
var explosion_size: String = "medium"  # "small", "medium", "large"

func _ready() -> void:
	_create_animated_sprite()

func _create_animated_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	add_child(sprite)

	# Create SpriteFrames resource
	var frames = SpriteFrames.new()
	frames.add_animation("explode")
	frames.set_animation_speed("explode", 20.0)
	frames.set_animation_loop("explode", false)

	var source_path: String
	var frame_size: int

	match explosion_size:
		"small":
			source_path = "res://assets/sprites/effects/pack2/Explosion_2_64x64.png"
			frame_size = 64
			scale_multiplier = 1.2
		"large":
			source_path = "res://assets/sprites/effects/pack2/Explosion_3_133x133.png"
			frame_size = 133
			scale_multiplier = 1.8
		_:  # medium (default)
			source_path = "res://assets/sprites/effects/pack2/Explosion_96x96.png"
			frame_size = 96
			scale_multiplier = 1.5

	sprite.scale = Vector2(scale_multiplier, scale_multiplier)

	# Try to load pack2 explosion first
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var frame_count = total_width / frame_size

			for i in range(frame_count):
				var frame_img = Image.create(frame_size, frame_size, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_size, 0, frame_size, frame_size), Vector2i.ZERO)
				frames.add_frame("explode", ImageTexture.create_from_image(frame_img))
	else:
		# Fallback to FireBomb frames
		for i in range(1, 16):
			var path = "res://assets/sprites/effects/FireBomb/Fire-bomb%d.png" % i
			if ResourceLoader.exists(path):
				var texture = load(path)
				frames.add_frame("explode", texture)

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("explode")

func _on_animation_finished() -> void:
	queue_free()

func set_explosion_scale(new_scale: float) -> void:
	scale_multiplier = new_scale
	if sprite:
		sprite.scale = Vector2(scale_multiplier, scale_multiplier)

func set_size(size: String) -> void:
	explosion_size = size
