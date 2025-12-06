extends StaticBody2D

## Destructible obstacle that blocks enemy attacks and can be destroyed.
## When player is behind it, becomes transparent. Trees, rocks, etc.

signal destroyed(obstacle: Node2D)

@export var max_health: float = 175.0
@export var obstacle_type: String = "tree"  # "tree", "rock", "branch"
@export var show_health_bar: bool = true

# Health system
var current_health: float
var health_bar: Node2D = null
var is_destroyed: bool = false

# Transparency when characters are behind
const NORMAL_ALPHA: float = 1.0
const PLAYER_BEHIND_ALPHA: float = 0.4   # 40% opacity when player is behind
const ENEMY_BEHIND_ALPHA: float = 0.6    # 60% opacity when enemy is behind
var current_alpha: float = 1.0
var target_alpha: float = 1.0
const ALPHA_LERP_SPEED: float = 8.0

# Visual components
@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea

# Character references
var player: Node2D = null
var enemies_behind: Array[Node2D] = []

func _ready() -> void:
	add_to_group("obstacles")
	current_health = max_health

	# Setup collision - obstacles on layer 8, mask player (1) and enemies (4)
	collision_layer = 8
	collision_mask = 0  # Static body, doesn't need to detect

	# Set z_index based on Y position for proper depth sorting
	# Trees lower on screen (higher Y) render on top of things higher on screen
	# Add +1 to ensure obstacles render slightly above enemies at same Y position
	z_index = int(global_position.y / 10) + 1

	# Ensure sprite renders on top of enemies behind the tree
	if sprite:
		sprite.z_index = 1  # Relative to parent, ensures it's above enemies

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

	# Check if player or enemies are behind us
	_check_characters_behind()

func _check_characters_behind() -> void:
	# Calculate the tree's collision/trunk width (much narrower than visual)
	var trunk_width = 24.0  # Narrow width for "directly behind" check
	if collision_shape and collision_shape.shape is RectangleShape2D:
		trunk_width = collision_shape.shape.size.x * scale.x

	var max_horizontal = trunk_width * 0.5  # Only directly behind the trunk

	# Check if player is DIRECTLY behind (within trunk width)
	var player_is_behind = false
	if player and is_instance_valid(player):
		var horizontal_dist = abs(player.global_position.x - global_position.x)
		# Player is "behind" visually if their Y is LESS than the tree's position
		# (lower Y = higher on screen = behind the tree in top-down view)
		# Also check they're close enough vertically (within 60 pixels)
		var vertical_dist = global_position.y - player.global_position.y
		if vertical_dist > 0 and vertical_dist < 60 and horizontal_dist < max_horizontal:
			player_is_behind = true

	# Check if any enemies are DIRECTLY behind
	var enemy_is_behind = false
	enemies_behind.clear()
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var horizontal_dist = abs(enemy.global_position.x - global_position.x)
		var vertical_dist = global_position.y - enemy.global_position.y
		if vertical_dist > 0 and vertical_dist < 60 and horizontal_dist < max_horizontal:
			enemy_is_behind = true
			enemies_behind.append(enemy)

	# Set target alpha - player takes priority over enemies
	if player_is_behind:
		target_alpha = PLAYER_BEHIND_ALPHA  # 20% opacity
	elif enemy_is_behind:
		target_alpha = ENEMY_BEHIND_ALPHA   # 50% opacity
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
	# Create particle effect based on type - similar to blood splatter effect
	var particle_colors: Array[Color] = []
	var particle_count: int = 12

	match obstacle_type:
		"tree":
			# Green leaves with some brown bark
			particle_colors = [
				Color(0.15, 0.5, 0.1),   # Dark green
				Color(0.25, 0.6, 0.15),  # Medium green
				Color(0.35, 0.7, 0.2),   # Light green
				Color(0.4, 0.3, 0.15),   # Brown bark
			]
			particle_count = 16
		"rock":
			# Gray stone shades
			particle_colors = [
				Color(0.4, 0.4, 0.4),   # Dark gray
				Color(0.5, 0.5, 0.5),   # Medium gray
				Color(0.6, 0.6, 0.6),   # Light gray
				Color(0.35, 0.35, 0.38), # Blue-gray
			]
			particle_count = 12
		"lamp":
			# Brown wood pieces
			particle_colors = [
				Color(0.45, 0.28, 0.12),  # Dark brown
				Color(0.55, 0.35, 0.15),  # Medium brown
				Color(0.65, 0.42, 0.2),   # Light brown
				Color(0.3, 0.2, 0.1),     # Very dark brown
			]
			particle_count = 10
		"branch":
			# Brown wood
			particle_colors = [
				Color(0.4, 0.25, 0.1),
				Color(0.5, 0.32, 0.14),
				Color(0.35, 0.2, 0.08),
			]
			particle_count = 8
		_:
			particle_colors = [Color(0.5, 0.5, 0.5)]
			particle_count = 8

	# Spawn particles with varied sizes and colors
	for i in range(particle_count):
		var particle = Sprite2D.new()
		particle.texture = _create_particle_texture()
		particle.modulate = particle_colors[randi() % particle_colors.size()]
		particle.global_position = global_position + Vector2(randf_range(-25, 25), randf_range(-30, 10))
		particle.scale = Vector2(1.0, 1.0) * randf_range(0.8, 2.0)
		particle.z_index = z_index + 1
		get_parent().add_child(particle)

		# Animate particle - burst outward and fall
		var tween = create_tween()
		var burst_dir = Vector2(randf_range(-1, 1), randf_range(-1, -0.3)).normalized()
		var burst_distance = randf_range(40, 80)
		var end_pos = particle.global_position + burst_dir * burst_distance + Vector2(0, randf_range(20, 50))

		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", end_pos, randf_range(0.4, 0.7)).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, randf_range(0.5, 0.8)).set_delay(0.1)
		tween.tween_property(particle, "rotation", randf_range(-4, 4), 0.6)
		tween.tween_property(particle, "scale", particle.scale * 0.3, 0.6)
		tween.chain().tween_callback(particle.queue_free)

func _create_particle_texture() -> Texture2D:
	# Create a simple square texture for particles (like blood effect)
	var image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

func _create_health_bar() -> void:
	# Health bar above the obstacle with border styling
	var bar_container = Node2D.new()
	bar_container.name = "HealthBar"
	bar_container.position = Vector2(0, -40)
	bar_container.visible = false  # Only show when damaged
	bar_container.z_index = 100  # Always render above obstacles
	bar_container.z_as_relative = false  # Use absolute z-index
	add_child(bar_container)

	# Border (slightly larger, dark outline)
	var border = ColorRect.new()
	border.name = "Border"
	border.color = Color(0.1, 0.1, 0.1, 1.0)  # Dark border, 100% opacity
	border.size = Vector2(36, 8)
	border.position = Vector2(-18, -2)
	bar_container.add_child(border)

	# Background (inside border)
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.15, 0.15, 0.15, 1.0)  # Dark gray, 100% opacity
	bg.size = Vector2(32, 4)
	bg.position = Vector2(-16, 0)
	bar_container.add_child(bg)

	# Health fill
	var fill = ColorRect.new()
	fill.name = "Fill"
	fill.color = Color(0.2, 0.8, 0.2, 1.0)  # Green, 100% opacity
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
	# Keep health bar at 100% opacity regardless of parent's alpha
	modulate.a = 1.0

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
		# Color from green to red with 100% opacity
		fill.color = Color(1.0 - ratio, ratio, 0.2, 1.0)
"""
	script.reload()
	return script

# Called by enemy projectiles when they hit this obstacle
func on_projectile_hit(projectile: Node2D) -> void:
	var damage = 10.0
	if projectile.has_method("get") and "damage" in projectile:
		damage = projectile.damage
	take_damage(damage)
