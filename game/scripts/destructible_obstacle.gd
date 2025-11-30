extends StaticBody2D

## Destructible obstacle that blocks enemy attacks and can be destroyed.
## When player is behind it, becomes transparent. Trees, rocks, etc.

signal destroyed(obstacle: Node2D)

@export var max_health: float = 50.0
@export var obstacle_type: String = "tree"  # "tree", "rock", "branch"
@export var show_health_bar: bool = true

# Health system
var current_health: float
var health_bar: Node2D = null
var is_destroyed: bool = false

# Transparency when player behind
const NORMAL_ALPHA: float = 1.0
const BEHIND_ALPHA: float = 0.35
var current_alpha: float = 1.0
var target_alpha: float = 1.0
const ALPHA_LERP_SPEED: float = 8.0

# Visual components
@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea

# Player reference
var player: Node2D = null

func _ready() -> void:
	add_to_group("obstacles")
	current_health = max_health

	# Setup collision - obstacles on layer 8, mask player (1) and enemies (4)
	collision_layer = 8
	collision_mask = 0  # Static body, doesn't need to detect

	# Set z_index based on Y position for proper depth sorting
	# Trees lower on screen (higher Y) render on top of things higher on screen
	z_index = int(global_position.y / 10)

	# Find player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# Create health bar if enabled
	if show_health_bar:
		_create_health_bar()

	# Setup detection area for transparency
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered_detection)
		detection_area.body_exited.connect(_on_body_exited_detection)

func _process(delta: float) -> void:
	if is_destroyed:
		return

	# Smoothly lerp alpha
	if abs(current_alpha - target_alpha) > 0.01:
		current_alpha = lerp(current_alpha, target_alpha, ALPHA_LERP_SPEED * delta)
		if sprite:
			sprite.modulate.a = current_alpha

	# Check if player is behind us (player Y > our Y means behind in top-down view)
	_check_player_behind()

func _check_player_behind() -> void:
	if not player or not is_instance_valid(player):
		target_alpha = NORMAL_ALPHA
		return

	# Calculate the tree's visual bounds
	var tree_top = global_position.y
	var tree_width = 40.0  # Default width

	if sprite and sprite.texture:
		# Tree sprite is offset upward, so the visual top is above global_position
		var sprite_height = sprite.texture.get_height() * sprite.scale.y
		tree_top = global_position.y + sprite.position.y - sprite_height / 2
		tree_width = sprite.texture.get_width() * sprite.scale.x

	# Player is "behind" visually if their Y is LESS than the tree's position
	# (lower Y = higher on screen = behind the tree in top-down view)
	var horizontal_dist = abs(player.global_position.x - global_position.x)
	var max_horizontal = tree_width * 0.6  # Slightly wider than tree for smooth transition

	# Only make transparent if player is BEHIND (lower Y, meaning visually behind/above in top-down)
	# AND horizontally overlapping with the tree
	if player.global_position.y < global_position.y and horizontal_dist < max_horizontal:
		target_alpha = BEHIND_ALPHA
	else:
		target_alpha = NORMAL_ALPHA

func _on_body_entered_detection(body: Node2D) -> void:
	pass  # Handled by _check_player_behind now

func _on_body_exited_detection(body: Node2D) -> void:
	pass  # Handled by _check_player_behind now

func take_damage(amount: float, _is_critical: bool = false) -> void:
	if is_destroyed:
		return

	current_health -= amount

	# Update health bar
	if health_bar and health_bar.has_method("update_health"):
		health_bar.update_health(current_health, max_health)

	# Flash white on hit
	_flash_hit()

	if current_health <= 0:
		_destroy()

func _flash_hit() -> void:
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color(2.0, 2.0, 2.0, sprite.modulate.a)

		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, sprite.modulate.a), 0.1)

func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true

	# Emit signal
	emit_signal("destroyed", self)

	# Play destruction animation
	_play_destruction_animation()

func _play_destruction_animation() -> void:
	if not sprite:
		queue_free()
		return

	# Disable collision immediately
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	# Shake and fade out
	var original_pos = sprite.position
	var tween = create_tween()
	tween.set_parallel(true)

	# Shake effect
	for i in range(6):
		var shake_offset = Vector2(randf_range(-4, 4), randf_range(-2, 2))
		tween.tween_property(sprite, "position", original_pos + shake_offset, 0.05).set_delay(i * 0.05)

	# Scale down and fade
	tween.tween_property(sprite, "scale", sprite.scale * 0.3, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)

	# Spawn particles
	_spawn_destruction_particles()

	# Remove after animation
	tween.chain().tween_callback(queue_free)

func _spawn_destruction_particles() -> void:
	# Different effects for different obstacle types
	match obstacle_type:
		"tree":
			_spawn_tree_shatter_effect()
		"rock":
			_spawn_rock_shatter_effect()
		_:
			_spawn_generic_particles()

func _spawn_tree_shatter_effect() -> void:
	# Dramatic shattering effect for trees - like blood splatter but green/brown
	var leaf_colors = [
		Color(0.2, 0.55, 0.15),   # Green
		Color(0.25, 0.6, 0.2),    # Light green
		Color(0.15, 0.45, 0.1),   # Dark green
		Color(0.3, 0.5, 0.15),    # Yellow-green
	]
	var wood_colors = [
		Color(0.4, 0.25, 0.1),    # Brown
		Color(0.35, 0.2, 0.08),   # Dark brown
		Color(0.5, 0.3, 0.12),    # Light brown
	]

	# Calculate spawn center based on sprite
	var spawn_center = global_position
	if sprite:
		spawn_center = global_position + sprite.position

	# Spawn many leaf particles (burst outward)
	var leaf_count = 25
	for i in range(leaf_count):
		var particle = Sprite2D.new()
		particle.texture = _create_leaf_texture()
		particle.modulate = leaf_colors[randi() % leaf_colors.size()]

		# Start from tree center with random offset
		var start_offset = Vector2(randf_range(-15, 15), randf_range(-40, 10))
		particle.global_position = spawn_center + start_offset
		particle.scale = Vector2(1.0, 1.0) * randf_range(0.4, 1.2)
		particle.rotation = randf_range(0, TAU)
		particle.z_index = z_index + 1
		get_parent().add_child(particle)

		# Burst outward in all directions
		var angle = randf_range(0, TAU)
		var distance = randf_range(40, 120)
		var end_pos = particle.global_position + Vector2(cos(angle), sin(angle)) * distance
		# Add gravity - leaves fall down
		end_pos.y += randf_range(20, 60)

		var duration = randf_range(0.4, 0.8)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", end_pos, duration).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, duration).set_delay(duration * 0.3)
		tween.tween_property(particle, "rotation", particle.rotation + randf_range(-4, 4), duration)
		tween.tween_property(particle, "scale", particle.scale * 0.3, duration)
		tween.chain().tween_callback(particle.queue_free)

	# Spawn wood splinter particles
	var wood_count = 12
	for i in range(wood_count):
		var particle = Sprite2D.new()
		particle.texture = _create_splinter_texture()
		particle.modulate = wood_colors[randi() % wood_colors.size()]

		var start_offset = Vector2(randf_range(-10, 10), randf_range(-20, 20))
		particle.global_position = spawn_center + start_offset
		particle.scale = Vector2(1.0, 1.0) * randf_range(0.5, 1.0)
		particle.rotation = randf_range(0, TAU)
		particle.z_index = z_index + 1
		get_parent().add_child(particle)

		# Wood flies out faster and more horizontally
		var angle = randf_range(-PI * 0.8, PI * 0.8) - PI / 2  # Mostly upward
		var distance = randf_range(30, 80)
		var end_pos = particle.global_position + Vector2(cos(angle), sin(angle)) * distance
		end_pos.y += randf_range(40, 80)  # Gravity

		var duration = randf_range(0.3, 0.6)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", end_pos, duration).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, duration).set_delay(duration * 0.4)
		tween.tween_property(particle, "rotation", particle.rotation + randf_range(-6, 6), duration)
		tween.chain().tween_callback(particle.queue_free)

func _spawn_rock_shatter_effect() -> void:
	# Rock debris effect
	var rock_colors = [
		Color(0.5, 0.5, 0.5),     # Gray
		Color(0.4, 0.4, 0.42),    # Dark gray
		Color(0.6, 0.58, 0.55),   # Light gray
	]

	var spawn_center = global_position
	if sprite:
		spawn_center = global_position + sprite.position

	var debris_count = 15
	for i in range(debris_count):
		var particle = Sprite2D.new()
		particle.texture = _create_rock_debris_texture()
		particle.modulate = rock_colors[randi() % rock_colors.size()]

		var start_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		particle.global_position = spawn_center + start_offset
		particle.scale = Vector2(1.0, 1.0) * randf_range(0.3, 0.8)
		particle.rotation = randf_range(0, TAU)
		particle.z_index = z_index + 1
		get_parent().add_child(particle)

		var angle = randf_range(0, TAU)
		var distance = randf_range(20, 60)
		var end_pos = particle.global_position + Vector2(cos(angle), sin(angle)) * distance
		end_pos.y += randf_range(10, 30)

		var duration = randf_range(0.3, 0.5)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", end_pos, duration).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, duration).set_delay(duration * 0.5)
		tween.tween_property(particle, "rotation", particle.rotation + randf_range(-3, 3), duration)
		tween.chain().tween_callback(particle.queue_free)

func _spawn_generic_particles() -> void:
	# Fallback for other obstacle types
	var particle_color = Color(0.5, 0.5, 0.5)

	for i in range(8):
		var particle = Sprite2D.new()
		particle.texture = _create_particle_texture()
		particle.modulate = particle_color
		particle.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		particle.scale = Vector2(0.5, 0.5) * randf_range(0.5, 1.5)
		particle.z_index = z_index + 1
		get_parent().add_child(particle)

		var tween = create_tween()
		var end_pos = particle.global_position + Vector2(randf_range(-40, 40), randf_range(-60, -20))
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", end_pos, 0.5)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_property(particle, "rotation", randf_range(-3, 3), 0.5)
		tween.chain().tween_callback(particle.queue_free)

func _create_particle_texture() -> Texture2D:
	# Create a simple square texture for particles
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

func _create_leaf_texture() -> Texture2D:
	# Create a leaf-shaped texture (diamond/oval shape)
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	# Draw a simple leaf shape
	for y in range(8):
		for x in range(8):
			var cx = x - 4
			var cy = y - 4
			# Diamond shape
			if abs(cx) + abs(cy) <= 3:
				image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)

func _create_splinter_texture() -> Texture2D:
	# Create an elongated splinter shape
	var image = Image.create(10, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	# Draw a horizontal bar with pointed ends
	for x in range(10):
		var width = 2 if x > 1 and x < 8 else 1
		for y in range(2 - width / 2, 2 + width):
			if y >= 0 and y < 4:
				image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)

func _create_rock_debris_texture() -> Texture2D:
	# Create an irregular rock chunk shape
	var image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	# Draw irregular polygon
	var pixels = [
		Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
		Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3),
		Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4),
		Vector2i(3, 5),
	]
	for p in pixels:
		image.set_pixel(p.x, p.y, Color.WHITE)
	return ImageTexture.create_from_image(image)

func _create_health_bar() -> void:
	# Simple health bar above the obstacle
	var bar_container = Node2D.new()
	bar_container.name = "HealthBar"
	bar_container.position = Vector2(0, -40)
	bar_container.visible = false  # Only show when damaged
	add_child(bar_container)

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	bg.size = Vector2(32, 4)
	bg.position = Vector2(-16, 0)
	bar_container.add_child(bg)

	# Health fill
	var fill = ColorRect.new()
	fill.name = "Fill"
	fill.color = Color(0.2, 0.8, 0.2)
	fill.size = Vector2(32, 4)
	fill.position = Vector2(-16, 0)
	bar_container.add_child(fill)

	health_bar = bar_container
	health_bar.set_script(_create_health_bar_script())

func _create_health_bar_script() -> GDScript:
	var script = GDScript.new()
	script.source_code = """extends Node2D

var show_timer: float = 0.0
const SHOW_DURATION: float = 3.0

func _process(delta: float) -> void:
	if visible:
		show_timer -= delta
		if show_timer <= 0:
			visible = false

func update_health(current: float, max_val: float) -> void:
	visible = true
	show_timer = SHOW_DURATION
	var fill = get_node_or_null("Fill")
	if fill:
		var ratio = clamp(current / max_val, 0.0, 1.0)
		fill.size.x = 32 * ratio
		# Color from green to red
		fill.color = Color(1.0 - ratio, ratio, 0.2)
"""
	script.reload()
	return script

# Called by enemy projectiles when they hit this obstacle
func on_projectile_hit(projectile: Node2D) -> void:
	var damage = 10.0
	if projectile.has_method("get") and "damage" in projectile:
		damage = projectile.damage
	take_damage(damage)
