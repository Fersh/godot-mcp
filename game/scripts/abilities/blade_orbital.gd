extends Area2D

# Blade Orbital - A sword that orbits the player dealing melee damage

var orbit_index: int = 0
var orbit_radius: float = 70.0
var orbit_speed: float = 4.0  # Faster than normal orbital
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
	sprite.scale = Vector2(1.5, 1.5)
	add_child(sprite)

	# Try to load a sword sprite, or create a simple one
	var sword_path = "res://assets/sprites/effects/blade_orbital.png"
	if ResourceLoader.exists(sword_path):
		sprite.texture = load(sword_path)
	else:
		# Create a simple sword shape using ColorRect as placeholder
		_create_placeholder_sword()

	# Silver/steel color
	sprite.modulate = Color(0.9, 0.95, 1.0, 1.0)

func _create_placeholder_sword() -> void:
	# Create a simple visual representation
	var blade = ColorRect.new()
	blade.size = Vector2(8, 32)
	blade.position = Vector2(-4, -16)
	blade.color = Color(0.8, 0.85, 0.9)
	add_child(blade)

	var hilt = ColorRect.new()
	hilt.size = Vector2(16, 6)
	hilt.position = Vector2(-8, 12)
	hilt.color = Color(0.5, 0.35, 0.2)
	add_child(hilt)

	# Add glow effect
	var glow = ColorRect.new()
	glow.size = Vector2(12, 36)
	glow.position = Vector2(-6, -18)
	glow.color = Color(0.7, 0.8, 1.0, 0.3)
	glow.z_index = -1
	add_child(glow)

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
