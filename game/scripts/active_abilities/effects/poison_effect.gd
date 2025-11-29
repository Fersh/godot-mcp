extends Node2D

# Poison effect using PoisonCast and PoisonClaw sprites
# Used for toxic aura, poison abilities

enum PoisonType { CAST, CLAW }

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5
var poison_type: PoisonType = PoisonType.CAST
var duration: float = 0.5
var is_looping: bool = false
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
	# SpriteFrames.new() already creates "default" animation, just configure it
	frames.set_animation_speed("default", 18.0)
	frames.set_animation_loop("default", is_looping)

	var source_path: String
	var frame_size: int = 96

	match poison_type:
		PoisonType.CAST:
			source_path = "res://assets/sprites/effects/pack2/PoisonCast_96x96.png"
		PoisonType.CLAW:
			source_path = "res://assets/sprites/effects/pack2/PoisonClaw_96x96.png"

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

func set_poison_type(type: PoisonType) -> void:
	poison_type = type

func set_looping(loop: bool, loop_duration: float = 3.0) -> void:
	is_looping = loop
	duration = loop_duration

func setup(ability_duration: float = 0.5, ability_scale: float = 1.5) -> void:
	duration = ability_duration
	effect_scale = ability_scale
	is_looping = duration > 0.5
	# If setup is called before _ready completes, mark as done and setup now
	if not _setup_done:
		_setup_done = true
		_setup_sprite()
	elif sprite:
		sprite.scale = Vector2(effect_scale, effect_scale)
