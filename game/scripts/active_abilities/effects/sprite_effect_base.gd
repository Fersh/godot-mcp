extends Node2D
class_name SpriteEffectBase

# Base class for sprite-based ability effects
# Handles loading sprite sheets and individual frame sequences

var sprite: AnimatedSprite2D
var effect_scale: float = 1.0
var animation_speed: float = 15.0
var loop_animation: bool = false
var auto_free: bool = true
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_setup_sprite()
	# Apply direction after sprite is created
	if direction != Vector2.RIGHT:
		rotation = direction.angle()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	add_child(sprite)

	var frames = _create_sprite_frames()
	if frames:
		sprite.sprite_frames = frames
		if auto_free:
			sprite.animation_finished.connect(_on_animation_finished)
		sprite.play("default")

func _create_sprite_frames() -> SpriteFrames:
	# Override in subclass
	return null

func _on_animation_finished() -> void:
	queue_free()

# Helper to load a horizontal sprite sheet
static func load_sprite_sheet(path: String, frame_width: int, frame_height: int, frame_count: int) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var source_texture = load(path) as Texture2D
	if not source_texture:
		return textures

	var source_image = source_texture.get_image()

	for i in range(frame_count):
		var frame_image = Image.create(frame_width, frame_height, false, source_image.get_format())
		var src_rect = Rect2i(i * frame_width, 0, frame_width, frame_height)
		frame_image.blit_rect(source_image, src_rect, Vector2i.ZERO)
		textures.append(ImageTexture.create_from_image(frame_image))

	return textures

# Helper to load a grid sprite sheet
static func load_sprite_sheet_grid(path: String, frame_width: int, frame_height: int, columns: int, rows: int) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var source_texture = load(path) as Texture2D
	if not source_texture:
		return textures

	var source_image = source_texture.get_image()

	for row in range(rows):
		for col in range(columns):
			var frame_image = Image.create(frame_width, frame_height, false, source_image.get_format())
			var src_rect = Rect2i(col * frame_width, row * frame_height, frame_width, frame_height)
			frame_image.blit_rect(source_image, src_rect, Vector2i.ZERO)
			textures.append(ImageTexture.create_from_image(frame_image))

	return textures

# Helper to load individual frame files (numbered sequence)
static func load_frame_sequence(base_path: String, prefix: String, start: int, end: int, suffix: String = ".png") -> Array[Texture2D]:
	var textures: Array[Texture2D] = []

	for i in range(start, end + 1):
		var path = base_path + prefix + str(i) + suffix
		if ResourceLoader.exists(path):
			textures.append(load(path))

	return textures

func set_effect_scale(new_scale: float) -> void:
	effect_scale = new_scale
	if sprite:
		sprite.scale = Vector2(effect_scale, effect_scale)

func set_direction(dir: Vector2) -> void:
	direction = dir
	# Can set rotation on Node2D even before sprite exists
	rotation = dir.angle()
