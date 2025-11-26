extends Node2D

# Slash effect using SlashFX Combo sprite sheets
# Used for cleave, omnislash individual hits

var sprite: AnimatedSprite2D
var effect_scale: float = 2.0
var slash_type: int = 1  # 1, 2, or 3 for different combo styles
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 24.0)  # Fast slash
	frames.set_animation_loop("default", false)

	# Choose which slash combo to use
	var source_path = "res://assets/sprites/effects/slash/SlashFX Combo%d sheet.png" % slash_type
	if not ResourceLoader.exists(source_path):
		source_path = "res://assets/sprites/effects/slash/SlashFX Combo1 sheet.png"

	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var height = img.get_height()
			# These sheets have 7 frames of 128x128 each (896 / 128 = 7)
			var frame_count = 7
			var frame_width = total_width / frame_count

			for i in range(frame_count):
				var frame_img = Image.create(frame_width, height, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_width, 0, frame_width, height), Vector2i.ZERO)
				frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("default")

	# Rotate to face direction and offset sprite forward
	rotation = direction.angle()
	sprite.position = Vector2(30, 0)  # Offset forward in local space

func _on_animation_finished() -> void:
	queue_free()

func set_direction(dir: Vector2) -> void:
	direction = dir
	rotation = dir.angle()

func set_slash_type(type: int) -> void:
	slash_type = clamp(type, 1, 3)
