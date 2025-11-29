extends Node2D

# Punch/hit impact effect using PunchImp sprite
# Used for shield_bash, melee hits, small impacts

var sprite: AnimatedSprite2D
var effect_scale: float = 2.5

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

	# Load PunchImp sprite - small impact, estimate 3-4 frames
	var source_path = "res://assets/sprites/effects/slash/PunchImp1.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var height = img.get_height()
			# Estimate based on aspect ratio
			var frame_count = max(1, total_width / height)
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
