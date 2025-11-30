extends Area2D

# Blade Orbital - A sword that orbits the player dealing melee damage

var orbit_index: int = 0
var orbit_radius: float = 70.0
var orbit_speed: float = 2.5  # Moderate orbital speed
var angle: float = 0.0
var base_damage: float = 20.0

var sprite: Sprite2D

func _ready() -> void:
	# Offset starting angle based on index
	angle = orbit_index * (TAU / 4.0)

	# Set up collision
	collision_layer = 2  # Arrow layer
	collision_mask = 4   # Enemy layer

	# Create collision shape (elongated for sword)
	var collision = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 24.0
	collision.shape = shape
	add_child(collision)

	# Connect signal
	body_entered.connect(_on_body_entered)

	# Setup sprite
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.scale = Vector2(1.0, 1.0)  # Slightly smaller
	add_child(sprite)

	# Try to load a sword sprite, or create a pixel art one
	var sword_path = "res://assets/sprites/effects/blade_orbital.png"
	if ResourceLoader.exists(sword_path):
		sprite.texture = load(sword_path)
		sprite.modulate = Color(0.9, 0.95, 1.0, 1.0)
	else:
		# Create pixel art sword
		_create_pixel_art_sword()

func _create_pixel_art_sword() -> void:
	# Remove sprite, we'll draw directly
	sprite.queue_free()
	sprite = null

	# Create a custom drawing node
	var sword_drawer = Node2D.new()
	sword_drawer.name = "SwordDrawer"
	sword_drawer.set_script(preload("res://scripts/abilities/blade_orbital_drawer.gd") if ResourceLoader.exists("res://scripts/abilities/blade_orbital_drawer.gd") else null)
	add_child(sword_drawer)

	# Fallback: draw using ColorRects in pixel art style
	var pixel = 2  # Pixel size

	# Blade - pointed tip (from top to bottom)
	# Tip (1 pixel wide)
	_add_pixel(0, -12, pixel, Color(0.95, 0.97, 1.0))  # Bright tip

	# Upper blade (2 pixels wide)
	_add_pixel(-1, -10, pixel, Color(0.85, 0.9, 0.95))
	_add_pixel(0, -10, pixel, Color(0.9, 0.93, 0.97))
	_add_pixel(-1, -8, pixel, Color(0.8, 0.85, 0.9))
	_add_pixel(0, -8, pixel, Color(0.88, 0.92, 0.96))

	# Middle blade (3 pixels wide)
	_add_pixel(-1, -6, pixel, Color(0.75, 0.8, 0.88))
	_add_pixel(0, -6, pixel, Color(0.85, 0.9, 0.95))
	_add_pixel(1, -6, pixel, Color(0.7, 0.75, 0.82))

	_add_pixel(-1, -4, pixel, Color(0.72, 0.78, 0.85))
	_add_pixel(0, -4, pixel, Color(0.82, 0.88, 0.93))
	_add_pixel(1, -4, pixel, Color(0.68, 0.73, 0.8))

	_add_pixel(-1, -2, pixel, Color(0.7, 0.76, 0.83))
	_add_pixel(0, -2, pixel, Color(0.8, 0.86, 0.92))
	_add_pixel(1, -2, pixel, Color(0.65, 0.7, 0.78))

	# Lower blade near guard
	_add_pixel(-1, 0, pixel, Color(0.68, 0.74, 0.82))
	_add_pixel(0, 0, pixel, Color(0.78, 0.84, 0.9))
	_add_pixel(1, 0, pixel, Color(0.62, 0.68, 0.76))

	# Crossguard (gold/bronze)
	_add_pixel(-4, 2, pixel, Color(0.6, 0.5, 0.2))
	_add_pixel(-3, 2, pixel, Color(0.75, 0.6, 0.25))
	_add_pixel(-2, 2, pixel, Color(0.85, 0.7, 0.3))
	_add_pixel(-1, 2, pixel, Color(0.9, 0.75, 0.35))
	_add_pixel(0, 2, pixel, Color(0.9, 0.75, 0.35))
	_add_pixel(1, 2, pixel, Color(0.85, 0.7, 0.3))
	_add_pixel(2, 2, pixel, Color(0.75, 0.6, 0.25))
	_add_pixel(3, 2, pixel, Color(0.6, 0.5, 0.2))

	# Handle/grip (brown leather wrapped)
	_add_pixel(-1, 4, pixel, Color(0.4, 0.28, 0.15))
	_add_pixel(0, 4, pixel, Color(0.5, 0.35, 0.2))
	_add_pixel(-1, 6, pixel, Color(0.5, 0.35, 0.2))
	_add_pixel(0, 6, pixel, Color(0.4, 0.28, 0.15))
	_add_pixel(-1, 8, pixel, Color(0.4, 0.28, 0.15))
	_add_pixel(0, 8, pixel, Color(0.5, 0.35, 0.2))

	# Pommel (gold)
	_add_pixel(-1, 10, pixel, Color(0.8, 0.65, 0.25))
	_add_pixel(0, 10, pixel, Color(0.85, 0.7, 0.3))
	_add_pixel(1, 10, pixel, Color(0.75, 0.6, 0.2))

	# Spectral glow effect
	var glow = ColorRect.new()
	glow.size = Vector2(10, 28)
	glow.position = Vector2(-5, -14)
	glow.color = Color(0.6, 0.75, 1.0, 0.2)
	glow.z_index = -1
	add_child(glow)

func _add_pixel(x: int, y: int, size: int, color: Color) -> void:
	var px = ColorRect.new()
	px.size = Vector2(size, size)
	px.position = Vector2(x * size - size/2, y * size - size/2)
	px.color = color
	px.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(px)

func _process(delta: float) -> void:
	angle += orbit_speed * delta
	if angle > TAU:
		angle -= TAU

	# Update position relative to parent (player)
	position = Vector2(cos(angle), sin(angle)) * orbit_radius

	# Rotate sprite to point along orbit direction (tangent)
	rotation = angle + PI / 2

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var damage = base_damage
		# Apply summon damage bonus
		if AbilityManager:
			damage *= AbilityManager.get_summon_damage_multiplier()
		body.take_damage(damage)

		# Apply knockback
		if body.has_method("apply_knockback"):
			var knockback_dir = (body.global_position - global_position).normalized()
			body.apply_knockback(knockback_dir * 100)
