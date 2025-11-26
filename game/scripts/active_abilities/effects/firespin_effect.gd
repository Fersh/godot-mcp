extends Node2D

# Fire spin effect using 7_firespin_spritesheet.png
# Used for spinning_attack, bladestorm

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5
var duration: float = 0.5
var is_looping: bool = false

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 20.0)
	frames.set_animation_loop("default", is_looping)

	# Load firespin sprite sheet - 7x8 grid (56 frames), ~100x100 each
	var source_path = "res://assets/sprites/effects/Free Pixel Effects Pack/7_firespin_spritesheet.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var total_height = img.get_height()
			var columns = 8
			var rows = 8
			var frame_width = total_width / columns
			var frame_height = total_height / rows

			for row in range(rows):
				for col in range(columns):
					var frame_img = Image.create(frame_width, frame_height, false, img.get_format())
					frame_img.blit_rect(img, Rect2i(col * frame_width, row * frame_height, frame_width, frame_height), Vector2i.ZERO)
					frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames

	if is_looping:
		sprite.play("default")
		get_tree().create_timer(duration).timeout.connect(_on_duration_finished)
	else:
		sprite.animation_finished.connect(_on_animation_finished)
		sprite.play("default")

func _on_animation_finished() -> void:
	queue_free()

func _on_duration_finished() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func setup(ability_duration: float, ability_radius: float, _damage: float, _multiplier: float = 1.0) -> void:
	duration = ability_duration
	is_looping = duration > 0.5
	effect_scale = ability_radius / 60.0
	if sprite:
		sprite.scale = Vector2(effect_scale, effect_scale)
