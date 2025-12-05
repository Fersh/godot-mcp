extends Node2D

# Earthquake effect - sustained screen-wide damage and stun
# Used for slam_earthquake (T3 Seismic Ground Slam of Cataclysm)

var duration: float = 3.0
var earthquake_radius: float = 400.0
var earthquake_damage: float = 80.0
var stun_duration: float = 1.5

var damage_tick_interval: float = 0.5
var damage_tick_timer: float = 0.0
var total_ticks: int = 0
var is_active: bool = false

# Visual elements
var impact_sprites: Array[AnimatedSprite2D] = []
var shake_intensity: float = 5.0

func _ready() -> void:
	call_deferred("_start_earthquake")

func _start_earthquake() -> void:
	is_active = true
	_spawn_impact_effects()
	_apply_initial_stun()

	# Start shake and duration timer
	get_tree().create_timer(duration).timeout.connect(_on_duration_finished)

func _process(delta: float) -> void:
	if not is_active:
		return

	# Apply camera shake continuously
	_apply_screen_shake()

	# Apply damage over time
	damage_tick_timer += delta
	if damage_tick_timer >= damage_tick_interval:
		damage_tick_timer = 0.0
		total_ticks += 1
		_apply_damage_tick()
		_spawn_additional_impact()

func _apply_initial_stun() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= earthquake_radius:
			if enemy.has_method("apply_stun"):
				enemy.apply_stun(stun_duration)
			elif enemy.has_method("stun"):
				enemy.stun(stun_duration)

func _apply_damage_tick() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var tick_damage = max(1.0, earthquake_damage * damage_tick_interval / duration * 2.0)

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= earthquake_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(tick_damage, false)
			# Re-apply shorter stuns periodically
			if total_ticks % 2 == 0:
				if enemy.has_method("apply_stun"):
					enemy.apply_stun(0.3)
				elif enemy.has_method("stun"):
					enemy.stun(0.3)

func _spawn_impact_effects() -> void:
	# Spawn multiple ground slam impacts across the area
	var num_impacts = 5
	for i in range(num_impacts):
		var offset = Vector2.ZERO
		if i > 0:
			var angle = randf() * TAU
			var dist = randf_range(50.0, earthquake_radius * 0.6)
			offset = Vector2(cos(angle), sin(angle)) * dist

		_spawn_single_impact(global_position + offset, 0.1 * i)

func _spawn_additional_impact() -> void:
	# Spawn random impacts during the earthquake
	var angle = randf() * TAU
	var dist = randf_range(30.0, earthquake_radius * 0.7)
	var offset = Vector2(cos(angle), sin(angle)) * dist
	_spawn_single_impact(global_position + offset, 0.0)

func _spawn_single_impact(pos: Vector2, delay: float) -> void:
	if delay > 0:
		get_tree().create_timer(delay).timeout.connect(func(): _create_impact_sprite(pos))
	else:
		_create_impact_sprite(pos)

func _create_impact_sprite(pos: Vector2) -> void:
	var sprite = AnimatedSprite2D.new()
	sprite.global_position = pos
	sprite.scale = Vector2(2.5, 2.5)
	sprite.modulate = Color(0.8, 0.6, 0.4)  # Brown/earthy tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_parent().add_child(sprite)

	var frames = SpriteFrames.new()
	frames.set_animation_speed("default", 15.0)
	frames.set_animation_loop("default", false)

	# Use weapon hit spritesheet for impact effect
	var source_path = "res://assets/sprites/effects/Free Pixel Effects Pack/10_weaponhit_spritesheet.png"
	var frame_size = 100
	var grid_size = 8

	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			for row in range(grid_size):
				for col in range(grid_size):
					var frame_img = Image.create(frame_size, frame_size, false, img.get_format())
					frame_img.blit_rect(img, Rect2i(col * frame_size, row * frame_size, frame_size, frame_size), Vector2i.ZERO)
					frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(sprite.queue_free)
	sprite.play("default")

func _apply_screen_shake() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("add_shake"):
		camera.add_shake(shake_intensity * 0.1)
	elif camera:
		# Fallback: manual offset
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)

func _on_duration_finished() -> void:
	is_active = false

	# Reset camera
	var camera = get_viewport().get_camera_2d()
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.2)

	# Fade out and cleanup
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func setup(damage: float, radius: float, effect_duration: float, stun_time: float) -> void:
	earthquake_damage = damage
	earthquake_radius = radius
	duration = effect_duration
	stun_duration = stun_time
