extends Node2D

# Dash smoke effect using DASH SMOKE.png sprite sheet
# Used for dodge, quick_roll, dash_strike, blade_rush

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
	frames.set_animation_speed("default", 20.0)
	frames.set_animation_loop("default", false)

	# Load DASH SMOKE sprite sheet - horizontal strip, estimate 6 frames at ~48x32 each
	var source_path = "res://assets/sprites/effects/slash/DASH SMOKE.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var height = img.get_height()
			# Estimate frame count - image appears to be ~288x32, so 6 frames of 48x32
			var frame_width = 48
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

func set_direction(dir: Vector2) -> void:
	rotation = dir.angle()
	# Flip if going left
	if dir.x < 0:
		sprite.flip_h = true
