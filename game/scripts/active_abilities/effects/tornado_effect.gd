extends Node2D

# Tornado/Whirlwind effect using TornadoLoop_96x96.png
# Used for whirlwind, bladestorm

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5
var duration: float = 3.0
var radius: float = 100.0
var damage: float = 0.0
var damage_multiplier: float = 1.0
var follow_parent: bool = true
var _setup_done: bool = false

func _ready() -> void:
	# Defer setup to allow setup() to be called first
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
	frames.set_animation_speed("default", 15.0)
	frames.set_animation_loop("default", true)

	# Load TornadoLoop sprite sheet - 96x96 frames
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

	# Auto-remove after duration
	get_tree().create_timer(duration).timeout.connect(_on_duration_finished)

func _on_duration_finished() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func setup(ability_duration: float, ability_radius: float, ability_damage: float, ability_multiplier: float = 1.0) -> void:
	duration = ability_duration
	radius = ability_radius
	damage = ability_damage
	damage_multiplier = ability_multiplier
	# Adjust scale based on radius
	effect_scale = radius / 60.0

	# If setup is called before _ready completes, mark as done and setup now
	if not _setup_done:
		_setup_done = true
		_setup_sprite()
	elif sprite:
		sprite.scale = Vector2(effect_scale, effect_scale)
