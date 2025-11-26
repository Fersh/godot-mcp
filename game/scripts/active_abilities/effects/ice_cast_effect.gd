extends Node2D

# Ice cast effect using IceCast_96x96.png
# Used for totem_of_frost, ice abilities

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5
var duration: float = 5.0
var is_looping: bool = true

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 15.0)
	frames.set_animation_loop("default", is_looping)

	var source_path = "res://assets/sprites/effects/pack2/IceCast_96x96.png"
	var frame_size = 96

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
	sprite.play("default")

	if is_looping:
		get_tree().create_timer(duration).timeout.connect(_on_duration_finished)
	else:
		sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	queue_free()

func _on_duration_finished() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func setup(ability_duration: float, _radius: float, _damage: float, _slow_percent: float = 0.0, _slow_duration: float = 0.0) -> void:
	duration = ability_duration
