extends Area2D

# Flame Orbital - A fireball that orbits the player and applies burn

var orbit_index: int = 0
var orbit_radius: float = 85.0
var orbit_speed: float = 1.25  # Reduced 50%
var angle: float = 0.0
var base_damage: float = 12.0
var burn_damage: float = 8.0  # Burn damage over 3 seconds
var burn_duration: float = 3.0

var sprite: AnimatedSprite2D
var glow_time: float = 0.0

func _ready() -> void:
	# Offset starting angle based on index
	angle = orbit_index * (TAU / 3.0)

	# Set up collision
	collision_layer = 2  # Arrow layer
	collision_mask = 4   # Enemy layer

	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 14.0
	collision.shape = shape
	add_child(collision)

	# Connect signal
	body_entered.connect(_on_body_entered)

	# Setup sprite
	_setup_sprite()

	# Add particle trail
	_setup_particles()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(0.6, 0.6)
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.set_animation_speed("default", 15.0)
	frames.set_animation_loop("default", true)

	# Try to load fire sprite sheet
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

	# Orange/red fire tint
	sprite.modulate = Color(1.0, 0.6, 0.2, 1.0)

func _setup_particles() -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 8
	particles.lifetime = 0.4
	particles.explosiveness = 0.0
	particles.local_coords = false

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 20.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 0.3
	material.scale_max = 0.6
	material.color = Color(1.0, 0.5, 0.1, 0.8)

	particles.process_material = material
	particles.z_index = -1
	add_child(particles)

func _process(delta: float) -> void:
	angle += orbit_speed * delta
	if angle > TAU:
		angle -= TAU

	# Update position relative to parent (player)
	position = Vector2(cos(angle), sin(angle)) * orbit_radius

	# Pulsing glow effect
	glow_time += delta * 5.0
	var pulse = 0.8 + sin(glow_time) * 0.2
	sprite.modulate = Color(1.0, 0.5 + pulse * 0.2, 0.1, pulse)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var damage = base_damage
		# Apply summon damage bonus
		if AbilityManager:
			damage *= AbilityManager.get_summon_damage_multiplier()
		body.take_damage(damage)

		# Apply burn effect (check if body still valid after taking damage)
		if is_instance_valid(body):
			if body.has_method("apply_burn"):
				var burn = burn_damage
				if AbilityManager:
					burn *= AbilityManager.get_summon_damage_multiplier()
				body.apply_burn(burn_duration, burn)  # (duration, damage_per_tick)
			elif body.has_method("apply_dot"):
				var burn = burn_damage
				if AbilityManager:
					burn *= AbilityManager.get_summon_damage_multiplier()
				body.apply_dot(burn, burn_duration, "burn")
