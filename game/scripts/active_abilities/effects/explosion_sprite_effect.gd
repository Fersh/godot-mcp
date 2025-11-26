extends Node2D

# General explosion effect using various explosion sprites
# Used for explosive_arrow, cluster_bomb, meteor_strike, explosive_decoy

enum ExplosionSize { SMALL, MEDIUM, LARGE }

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5
var explosion_size: ExplosionSize = ExplosionSize.MEDIUM

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 20.0)
	frames.set_animation_loop("default", false)

	var source_path: String
	var frame_size: int

	match explosion_size:
		ExplosionSize.SMALL:
			source_path = "res://assets/sprites/effects/pack2/Explosion_2_64x64.png"
			frame_size = 64
			effect_scale = 1.2
		ExplosionSize.MEDIUM:
			source_path = "res://assets/sprites/effects/pack2/Explosion_96x96.png"
			frame_size = 96
			effect_scale = 1.5
		ExplosionSize.LARGE:
			source_path = "res://assets/sprites/effects/pack2/Explosion_3_133x133.png"
			frame_size = 133
			effect_scale = 1.8

	sprite.scale = Vector2(effect_scale, effect_scale)

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

func set_size(size: ExplosionSize) -> void:
	explosion_size = size

func set_size_from_string(size_str: String) -> void:
	match size_str.to_lower():
		"small":
			explosion_size = ExplosionSize.SMALL
		"large":
			explosion_size = ExplosionSize.LARGE
		_:
			explosion_size = ExplosionSize.MEDIUM
