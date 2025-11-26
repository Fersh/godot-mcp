extends Node2D

# Black hole effect using Black-hole.png sprite sheet
# Used for black_hole ability

var sprite: AnimatedSprite2D
var effect_scale: float = 2.5
var duration: float = 3.0
var _setup_done: bool = false

func _ready() -> void:
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	if _setup_done:
		return
	_setup_done = true
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 12.0)
	frames.set_animation_loop("default", true)  # Loop for duration

	# Load Black-hole sprite sheet - 8 frames in horizontal strip, ~32x32 each
	var source_path = "res://assets/sprites/effects/pack/9 Black hole/Black-hole.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var height = img.get_height()
			var frame_count = 8
			var frame_width = total_width / frame_count

			for i in range(frame_count):
				var frame_img = Image.create(frame_width, height, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_width, 0, frame_width, height), Vector2i.ZERO)
				frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.play("default")

	# Auto-remove after duration
	get_tree().create_timer(duration).timeout.connect(_on_duration_finished)

	# Pulsing scale effect
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "scale", Vector2(effect_scale * 1.1, effect_scale * 1.1), 0.5)
	tween.tween_property(sprite, "scale", Vector2(effect_scale, effect_scale), 0.5)

func _on_duration_finished() -> void:
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func setup(ability_duration: float, ability_radius: float, _damage: float, _multiplier: float = 1.0) -> void:
	duration = ability_duration
	effect_scale = ability_radius / 40.0  # Scale based on radius
	# If setup is called before _ready completes, mark as done and setup now
	if not _setup_done:
		_setup_done = true
		_setup_sprite()
	elif sprite:
		sprite.scale = Vector2(effect_scale, effect_scale)
