extends Node2D

# Fireball explosion effect using FireBall_64x64.png or Explosion_96x96.png
# Used for fireball impact, explosive_arrow, throwing_bomb

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5
var use_explosion: bool = false  # Use explosion sprite instead of fireball

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	add_child(sprite)

	var frames = SpriteFrames.new()
	# SpriteFrames.new() already creates "default" animation, just configure it
	frames.set_animation_speed("default", 20.0)
	frames.set_animation_loop("default", false)

	var source_path: String
	var frame_size: int

	if use_explosion:
		source_path = "res://assets/sprites/effects/pack2/Explosion_96x96.png"
		frame_size = 96
	else:
		source_path = "res://assets/sprites/effects/pack2/FireBall_64x64.png"
		frame_size = 64

	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
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

func set_explosion_mode(enabled: bool) -> void:
	use_explosion = enabled
