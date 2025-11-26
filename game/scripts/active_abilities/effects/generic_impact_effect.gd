extends Node2D
class_name GenericImpactEffect

# A generic impact effect using weapon hit sprite
# Used as fallback for abilities without specific effects

@export var color: Color = Color(1.0, 0.8, 0.3, 0.8)
@export var radius: float = 50.0
@export var duration: float = 0.3
@export var expand: bool = true

var sprite: AnimatedSprite2D

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 20.0)
	frames.set_animation_loop("default", false)

	# Try to load weapon hit sprite sheet
	var source_path = "res://assets/sprites/effects/Free Pixel Effects Pack/10_weaponhit_spritesheet.png"
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

	# Tint with color
	sprite.modulate = color

func _on_animation_finished() -> void:
	queue_free()

func setup(p_radius: float, p_color: Color, p_duration: float = 0.3) -> void:
	radius = p_radius
	color = p_color
	duration = p_duration
	if sprite:
		sprite.modulate = color
		sprite.scale = Vector2(p_radius / 25.0, p_radius / 25.0)
