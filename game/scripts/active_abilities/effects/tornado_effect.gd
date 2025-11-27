extends Node2D

# Tornado/Whirlwind effect using TornadoLoop_96x96.png
# Used for whirlwind, bladestorm

var sprite: AnimatedSprite2D
var effect_scale: float = 2.0
var duration: float = 3.0
var radius: float = 100.0
var damage: float = 0.0
var damage_multiplier: float = 1.0
var follow_parent: bool = true
var _initialized: bool = false

func _ready() -> void:
	# Defer initialization to allow setup() to be called first
	call_deferred("_deferred_init")

func _deferred_init() -> void:
	if _initialized:
		return
	_initialized = true
	_setup_sprite()
	_start_duration_timer()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	sprite.centered = true
	sprite.z_index = 10  # Draw above other effects
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 20.0)  # Faster animation
	frames.set_animation_loop("default", true)

	# Load TornadoLoop sprite sheet - 96x96 frames, 60 frames total
	var source_path = "res://assets/sprites/effects/pack2/TornadoLoop_96x96.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var frame_size = 96
			var frame_count = total_width / frame_size

			for i in range(frame_count):
				var frame_img = Image.create(frame_size, frame_size, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_size, 0, frame_size, frame_size), Vector2i.ZERO)
				frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.play("default")

func _start_duration_timer() -> void:
	get_tree().create_timer(duration).timeout.connect(_on_duration_finished)

func _on_duration_finished() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func setup(ability_duration: float, ability_radius: float, ability_damage: float, ability_multiplier: float = 1.0) -> void:
	duration = ability_duration
	radius = ability_radius
	damage = ability_damage
	damage_multiplier = ability_multiplier
	# Adjust scale based on radius - make it visually larger
	effect_scale = max(radius / 50.0, 1.5)

	# If setup called after deferred init, update sprite scale
	if sprite:
		sprite.scale = Vector2(effect_scale, effect_scale)

	# If setup called before deferred init, trigger init now
	if not _initialized:
		_initialized = true
		_setup_sprite()
		_start_duration_timer()
