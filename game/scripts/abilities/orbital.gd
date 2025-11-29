extends Area2D

var orbit_index: int = 0
var orbit_radius: float = 80.0
var orbit_speed: float = 3.0  # radians per second
var angle: float = 0.0
var damage: float = 15.0

var sprite: AnimatedSprite2D

func _ready() -> void:
	# Offset starting angle based on index
	angle = orbit_index * (TAU / 3.0)

	# Set up collision
	collision_layer = 2  # Arrow layer
	collision_mask = 4   # Enemy layer

	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	add_child(collision)

	# Connect signal
	body_entered.connect(_on_body_entered)

	# Setup sprite
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(0.5, 0.5)  # Scale down the 64x64 sprite
	add_child(sprite)

	var frames = SpriteFrames.new()
	# SpriteFrames.new() already creates "default" animation, just configure it
	frames.set_animation_speed("default", 15.0)
	frames.set_animation_loop("default", true)

	# Load SmallStar sprite sheet - 64x64 frames
	var source_path = "res://assets/sprites/effects/pack2/SmallStar_64x64.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var frame_size = 64
			var frame_count = total_width / frame_size

			for i in range(frame_count):
				var frame_img = Image.create(frame_size, frame_size, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_size, 0, frame_size, frame_size), Vector2i.ZERO)
				frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.play("default")

	# Blue tint for orbital
	sprite.modulate = Color(0.5, 0.8, 1.0, 1.0)

func _process(delta: float) -> void:
	angle += orbit_speed * delta
	if angle > TAU:
		angle -= TAU

	# Update position relative to parent (player)
	position = Vector2(cos(angle), sin(angle)) * orbit_radius

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
