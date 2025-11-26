extends Node2D

# Cleave visual effect - uses SlashFX Combo sprite sheet

var arc_radius: float = 80.0
var arc_angle: float = PI * 0.75  # 135 degrees
var direction: Vector2 = Vector2.RIGHT:
	set(value):
		direction = value
		_update_rotation()
var color: Color = Color(1.0, 0.9, 0.7, 0.9)
var duration: float = 0.25

var sprite: AnimatedSprite2D

func _ready() -> void:
	_setup_sprite()
	_update_rotation()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(2.5, 2.5)  # Scale up the sprite
	sprite.centered = true  # Ensure sprite is centered
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 28.0)  # Fast slash
	frames.set_animation_loop("default", false)

	# Load SlashFX Combo1 sprite sheet
	var source_path = "res://assets/sprites/effects/slash/SlashFX Combo1 sheet.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var height = img.get_height()
			var frame_count = 6
			var frame_width = total_width / frame_count

			for i in range(frame_count):
				var frame_img = Image.create(frame_width, height, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_width, 0, frame_width, height), Vector2i.ZERO)
				frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("default")

func _update_rotation() -> void:
	rotation = direction.angle()

func _on_animation_finished() -> void:
	queue_free()
