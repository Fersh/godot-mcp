extends Area2D

# Frost Orbital - An ice shard that orbits the player and applies slow

var orbit_index: int = 0
var orbit_radius: float = 75.0
var orbit_speed: float = 1.4  # Reduced 50%
var angle: float = 0.0
var base_damage: float = 10.0
var slow_amount: float = 0.4  # 40% slow
var slow_duration: float = 2.0

var sprite: AnimatedSprite2D
var shimmer_time: float = 0.0

func _ready() -> void:
	# Offset starting angle based on index
	angle = orbit_index * (TAU / 3.0) + PI / 6  # Offset from flame orbital

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

	# Add frost particle effect
	_setup_particles()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(0.55, 0.55)
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.set_animation_speed("default", 12.0)
	frames.set_animation_loop("default", true)

	# Load star sprite and tint it ice blue
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

	# Ice blue/cyan tint
	sprite.modulate = Color(0.6, 0.9, 1.0, 1.0)

func _setup_particles() -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 6
	particles.lifetime = 0.5
	particles.explosiveness = 0.0
	particles.local_coords = false

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3(0, 10, 0)  # Slight downward drift
	material.scale_min = 0.2
	material.scale_max = 0.4
	material.color = Color(0.7, 0.9, 1.0, 0.6)

	particles.process_material = material
	particles.z_index = -1
	add_child(particles)

func _process(delta: float) -> void:
	angle += orbit_speed * delta
	if angle > TAU:
		angle -= TAU

	# Update position relative to parent (player)
	position = Vector2(cos(angle), sin(angle)) * orbit_radius

	# Shimmer effect
	shimmer_time += delta * 4.0
	var shimmer = 0.85 + sin(shimmer_time) * 0.15
	sprite.modulate = Color(0.5 + shimmer * 0.2, 0.85 + shimmer * 0.1, 1.0, shimmer)

	# Slow rotation for ice crystal effect
	sprite.rotation += delta * 0.5

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var damage = base_damage
		# Apply summon damage bonus
		if AbilityManager:
			damage *= AbilityManager.get_summon_damage_multiplier()
		body.take_damage(damage)

		# Apply slow effect
		if body.has_method("apply_slow"):
			body.apply_slow(slow_amount, slow_duration)
		elif body.has_method("apply_chill"):
			body.apply_chill(slow_amount, slow_duration)
