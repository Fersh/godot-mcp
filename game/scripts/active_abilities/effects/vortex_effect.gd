extends Node2D

# Vortex effect that pulls enemies toward the center
# Used for spin_vortex, spin_bladestorm abilities

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5
var duration: float = 3.0
var is_looping: bool = true
var _setup_done: bool = false
var _vortex_started: bool = false

# Vortex functionality
var vortex_radius: float = 150.0
var vortex_damage: float = 0.0
var pull_strength: float = 100.0  # How strongly enemies are pulled per second
var tick_interval: float = 0.1   # Apply pull every 0.1 seconds for smooth effect
var tick_timer: float = 0.0
var damage_tick_interval: float = 0.5  # Apply damage less frequently
var damage_tick_timer: float = 0.0

# Reference to player for following
var follow_target: Node2D = null

func _ready() -> void:
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	if _setup_done:
		return
	_setup_done = true
	_setup_sprite()

func _process(delta: float) -> void:
	# Follow the player if set
	if follow_target and is_instance_valid(follow_target):
		global_position = follow_target.global_position

	if not _vortex_started:
		return

	# Apply pull effect frequently for smooth pulling
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_apply_pull_effect()

	# Apply damage less frequently
	damage_tick_timer += delta
	if damage_tick_timer >= damage_tick_interval:
		damage_tick_timer = 0.0
		_apply_damage_effect()

func _apply_pull_effect() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= vortex_radius and dist > 20.0:  # Don't pull if already very close
			# Calculate pull direction (toward center)
			var pull_dir = (global_position - enemy.global_position).normalized()
			# Pull strength decreases with distance for more natural feel
			var distance_factor = 1.0 - (dist / vortex_radius) * 0.5
			var pull_amount = pull_strength * tick_interval * distance_factor

			# Move the enemy toward the vortex center
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(pull_dir * pull_amount)
			elif "global_position" in enemy:
				enemy.global_position += pull_dir * pull_amount

func _apply_damage_effect() -> void:
	if vortex_damage <= 0:
		return

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= vortex_radius:
			if enemy.has_method("take_damage"):
				var tick_damage = max(1.0, vortex_damage * damage_tick_interval)
				enemy.take_damage(tick_damage, false)

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.set_animation_speed("default", 15.0)
	frames.set_animation_loop("default", is_looping)

	# Use vortex spritesheet (800x800, likely 8x8 grid of 100x100 frames)
	var source_path = "res://assets/sprites/effects/Free Pixel Effects Pack/13_vortex_spritesheet.png"
	var frame_size = 100
	var grid_size = 8  # 8x8 grid

	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			# Extract frames from grid
			for row in range(grid_size):
				for col in range(grid_size):
					var frame_img = Image.create(frame_size, frame_size, false, img.get_format())
					frame_img.blit_rect(img, Rect2i(col * frame_size, row * frame_size, frame_size, frame_size), Vector2i.ZERO)
					frames.add_frame("default", ImageTexture.create_from_image(frame_img))
	else:
		# Fallback to pack2 effect if vortex not found
		var fallback_path = "res://assets/sprites/effects/pack2/IceCast_96x96.png"
		var fallback_size = 96
		if ResourceLoader.exists(fallback_path):
			var source_texture = load(fallback_path) as Texture2D
			if source_texture:
				var img = source_texture.get_image()
				var total_width = img.get_width()
				var frame_count = total_width / fallback_size

				for i in range(frame_count):
					var frame_img = Image.create(fallback_size, fallback_size, false, img.get_format())
					frame_img.blit_rect(img, Rect2i(i * fallback_size, 0, fallback_size, fallback_size), Vector2i.ZERO)
					frames.add_frame("default", ImageTexture.create_from_image(frame_img))
		# Tint it purple/blue for vortex look
		modulate = Color(0.7, 0.5, 1.0)

	sprite.sprite_frames = frames
	sprite.play("default")

	if is_looping:
		get_tree().create_timer(duration).timeout.connect(_on_duration_finished)
	else:
		sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	queue_free()

func _on_duration_finished() -> void:
	_vortex_started = false  # Stop applying effects
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func setup(ability_duration: float, ability_radius: float = 150.0, damage: float = 0.0, p_pull_strength: float = 100.0, p_follow_target: Node2D = null) -> void:
	duration = ability_duration
	vortex_radius = ability_radius
	vortex_damage = damage
	pull_strength = p_pull_strength
	follow_target = p_follow_target
	effect_scale = ability_radius / 60.0

	# If setup is called before _ready completes, mark as done and setup now
	if not _setup_done:
		_setup_done = true
		_setup_sprite()
	elif sprite:
		sprite.scale = Vector2(effect_scale, effect_scale)

	# Start vortex processing after setup is complete
	_vortex_started = true
