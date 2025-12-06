extends StaticBody2D

## Destructible obstacle that blocks enemy attacks and can be destroyed.
## When player is behind it, becomes transparent. Trees, rocks, etc.

signal destroyed(obstacle: Node2D)

@export var max_health: float = 175.0
@export var obstacle_type: String = "tree"  # "tree", "rock", "branch"
@export var show_health_bar: bool = false

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

	# CRITICAL: Use absolute z_index so we're not affected by parent's z_index
	# TileBackground has z_index = -10, which would offset our z_index otherwise
	z_as_relative = false

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

	# Update z_index based on Y position every frame for proper depth sorting
	# Use the collision shape's bottom edge (where character feet would be)
	# Add +1 to ensure obstacles render on top of characters at same Y position
	var base_y = global_position.y
	if collision_shape:
		base_y = global_position.y + collision_shape.position.y + 10  # Bottom of collision
	z_index = int(base_y / 10) + 1

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
	# Blood-splatter style particles - small squares like enemy death
	var particle_colors: Array[Color] = []
	var particle_count: int = 20  # Similar to blood particle count
	var chunk_count: int = 8  # Medium debris pieces

	match obstacle_type:
		"tree":
			# Green leaves with brown bark
			particle_colors = [
				Color(0.15, 0.5, 0.1),   # Dark green
				Color(0.2, 0.6, 0.15),   # Forest green
				Color(0.3, 0.7, 0.2),    # Medium green
				Color(0.45, 0.3, 0.12),  # Brown bark
				Color(0.35, 0.22, 0.1),  # Dark bark
			]
			particle_count = 25
			chunk_count = 10
		"rock":
			# Gray stone shades
			particle_colors = [
				Color(0.35, 0.35, 0.38),  # Dark gray
				Color(0.45, 0.45, 0.48),  # Medium gray
				Color(0.55, 0.55, 0.58),  # Light gray
				Color(0.4, 0.38, 0.42),   # Blue-gray
			]
			particle_count = 20
			chunk_count = 8
		"lamp":
			# Wood pieces with glass
			particle_colors = [
				Color(0.45, 0.28, 0.12),  # Dark brown
				Color(0.55, 0.35, 0.15),  # Medium brown
				Color(0.65, 0.42, 0.2),   # Light brown
				Color(0.9, 0.85, 0.7),    # Glass shard
			]
			particle_count = 18
			chunk_count = 6
		"branch":
			# Brown wood splinters
			particle_colors = [
				Color(0.4, 0.25, 0.1),
				Color(0.5, 0.32, 0.14),
				Color(0.35, 0.2, 0.08),
			]
			particle_count = 15
			chunk_count = 5
		_:
			particle_colors = [Color(0.5, 0.5, 0.5), Color(0.6, 0.6, 0.6)]
			particle_count = 15
			chunk_count = 5

	# Spawn medium debris chunks (like blood chunks, size 3-6)
	for i in range(chunk_count):
		var chunk = Sprite2D.new()
		chunk.texture = _create_particle_texture()  # Use small 4x4 texture
		chunk.modulate = particle_colors[randi() % particle_colors.size()]
		chunk.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-30, 0))
		chunk.z_index = z_index + 2
		get_parent().add_child(chunk)

		# Burst outward with gravity like blood
		var tween = create_tween()
		var burst_dir = Vector2(randf_range(-1, 1), randf_range(-0.8, -0.2)).normalized()
		var burst_distance = randf_range(40, 80)
		var mid_pos = chunk.global_position + burst_dir * burst_distance
		var end_pos = mid_pos + Vector2(0, randf_range(30, 60))

		tween.set_parallel(true)
		tween.tween_property(chunk, "global_position", mid_pos, 0.2).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(chunk, "global_position", end_pos, 0.35).set_ease(Tween.EASE_IN)
		tween.set_parallel(true)
		tween.tween_property(chunk, "rotation", randf_range(-4, 4), 0.55)
		tween.tween_property(chunk, "modulate:a", 0.0, 0.25).set_delay(0.35)
		tween.chain().tween_callback(chunk.queue_free)

	# Spawn small particles (like blood particles, size 2-5)
	for i in range(particle_count):
		var particle = Sprite2D.new()
		particle.texture = _create_particle_texture()  # 4x4 texture
		particle.modulate = particle_colors[randi() % particle_colors.size()]
		particle.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-35, 5))
		particle.z_index = z_index + 1
		get_parent().add_child(particle)

		# Explosive burst like blood splatter
		var tween = create_tween()
		var burst_dir = Vector2(randf_range(-1, 1), randf_range(-1, 0.3)).normalized()
		var burst_distance = randf_range(30, 70)
		var end_pos = particle.global_position + burst_dir * burst_distance + Vector2(0, randf_range(15, 35))

		var duration = randf_range(0.35, 0.6)
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", end_pos, duration).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, duration * 0.8).set_delay(duration * 0.3)
		tween.tween_property(particle, "rotation", randf_range(-3, 3), duration)
		tween.chain().tween_callback(particle.queue_free)

	# Add a smaller dust cloud
	_spawn_dust_cloud()

func _create_particle_texture() -> Texture2D:
	# Create a small square texture like blood particles (4x4)
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

func _spawn_dust_cloud() -> void:
	# Spawn small fading dust puffs
	var dust_count = 8
	var dust_color = Color(0.6, 0.55, 0.45, 0.4)  # Brownish dust

	match obstacle_type:
		"tree":
			dust_color = Color(0.4, 0.5, 0.35, 0.4)  # Greenish dust
		"rock":
			dust_color = Color(0.5, 0.5, 0.5, 0.4)   # Gray dust
		"lamp":
			dust_color = Color(0.55, 0.45, 0.35, 0.4)  # Brown dust

	for i in range(dust_count):
		var dust = Sprite2D.new()
		dust.texture = _create_dust_texture()
		dust.modulate = dust_color
		dust.modulate.a = randf_range(0.2, 0.4)
		dust.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-25, 0))
		dust.scale = Vector2(1.0, 1.0) * randf_range(0.8, 1.5)
		dust.z_index = z_index + 3
		get_parent().add_child(dust)

		# Dust expands and fades quickly
		var tween = create_tween()
		var expand_dir = Vector2(randf_range(-1, 1), randf_range(-0.5, 0.3)).normalized()
		var end_pos = dust.global_position + expand_dir * randf_range(20, 40)

		tween.set_parallel(true)
		tween.tween_property(dust, "global_position", end_pos, randf_range(0.3, 0.5)).set_ease(Tween.EASE_OUT)
		tween.tween_property(dust, "scale", dust.scale * randf_range(1.3, 1.8), randf_range(0.3, 0.5))
		tween.tween_property(dust, "modulate:a", 0.0, randf_range(0.35, 0.5))
		tween.chain().tween_callback(dust.queue_free)

func _create_dust_texture() -> Texture2D:
	# Create a small soft circular dust texture
	var size = 8
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0

	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var alpha = clamp(1.0 - (dist / radius), 0.0, 1.0)
			alpha = alpha * alpha  # Soft falloff
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	return ImageTexture.create_from_image(image)

func _create_health_bar() -> void:
	# Health bar above the obstacle - matches enemy health bar exactly (40x6 with rounded corners)
	var bar_container = Node2D.new()
	bar_container.name = "HealthBar"
	bar_container.position = Vector2(0, -40)
	bar_container.visible = false  # Only show when damaged
	bar_container.z_index = 100  # Always render above obstacles
	bar_container.z_as_relative = false  # Use absolute z-index
	add_child(bar_container)

	var bar_width := 40.0
	var bar_height := 6.0

	# Background - Panel with StyleBoxFlat for rounded corners
	var bg = Panel.new()
	bg.name = "Background"
	bg.size = Vector2(bar_width, bar_height)
	bg.position = Vector2(-bar_width / 2, -bar_height / 2)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	bg_style.border_color = Color(0, 0, 0, 1.0)
	bg_style.set_border_width_all(1)
	bg_style.set_corner_radius_all(2)
	bg_style.shadow_color = Color(0, 0, 0, 0.5)
	bg_style.shadow_size = 2
	bg_style.shadow_offset = Vector2(1, 1)
	bg.add_theme_stylebox_override("panel", bg_style)
	bar_container.add_child(bg)

	# Health fill - Panel with StyleBoxFlat for rounded corners
	var fill = Panel.new()
	fill.name = "Fill"
	fill.size = Vector2(bar_width - 2, bar_height - 2)  # Account for border
	fill.position = Vector2(-bar_width / 2 + 1, -bar_height / 2 + 1)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.2, 1.0)
	fill_style.set_corner_radius_all(1)
	fill.add_theme_stylebox_override("panel", fill_style)
	bar_container.add_child(fill)

	health_bar = bar_container
	health_bar.set_script(_create_health_bar_script())

func _create_health_bar_script() -> GDScript:
	var script = GDScript.new()
	script.source_code = """extends Node2D

var show_timer: float = 0.0
const SHOW_DURATION: float = 3.0
const BAR_WIDTH: float = 40.0
const BORDER_WIDTH: float = 1.0

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
		var fill_width = (BAR_WIDTH - BORDER_WIDTH * 2) * ratio
		fill.size.x = fill_width
		# Update color from green to red via StyleBoxFlat
		var style = fill.get_theme_stylebox("panel").duplicate()
		if ratio > 0.5:
			style.bg_color = Color(0.2, 0.8, 0.2, 1.0)  # Green
		elif ratio > 0.25:
			style.bg_color = Color(0.9, 0.7, 0.1, 1.0)  # Yellow
		else:
			style.bg_color = Color(0.9, 0.2, 0.2, 1.0)  # Red
		fill.add_theme_stylebox_override("panel", style)
"""
	script.reload()
	return script

# Called by enemy projectiles when they hit this obstacle
func on_projectile_hit(projectile: Node2D) -> void:
	var damage = 10.0
	if projectile.has_method("get") and "damage" in projectile:
		damage = projectile.damage
	take_damage(damage)
