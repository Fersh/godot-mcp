extends Node2D

# Magic cast/summon effect using magic spritesheets
# Used for summon_burst, army_of_the_dead, magic abilities

enum MagicType { SPELL, DARK, SUMMON, VORTEX }

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5
var magic_type: MagicType = MagicType.SPELL

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	add_child(sprite)

	var frames = SpriteFrames.new()
	# SpriteFrames.new() already creates "default" animation, just configure it
	frames.set_animation_speed("default", 18.0)
	frames.set_animation_loop("default", false)

	var source_path: String
	var grid_cols: int = 8
	var grid_rows: int = 8

	match magic_type:
		MagicType.SPELL:
			source_path = "res://assets/sprites/effects/Free Pixel Effects Pack/1_magicspell_spritesheet.png"
		MagicType.DARK:
			source_path = "res://assets/sprites/effects/Free Pixel Effects Pack/17_felspell_spritesheet.png"
		MagicType.SUMMON:
			source_path = "res://assets/sprites/effects/Free Pixel Effects Pack/4_casting_spritesheet.png"
		MagicType.VORTEX:
			source_path = "res://assets/sprites/effects/Free Pixel Effects Pack/13_vortex_spritesheet.png"

	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var total_height = img.get_height()
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

func _on_animation_finished() -> void:
	queue_free()

func set_magic_type(type: MagicType) -> void:
	magic_type = type
