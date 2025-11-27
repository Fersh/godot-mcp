extends Node2D

# Ice cast effect using IceCast_96x96.png
# Used for totem_of_frost, ice abilities

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5
var duration: float = 5.0
var is_looping: bool = true
var _setup_done: bool = false
var _totem_started: bool = false

# Totem functionality
var totem_radius: float = 100.0
var totem_damage: float = 0.0
var totem_slow_percent: float = 0.0
var totem_slow_duration: float = 0.0
var tick_interval: float = 0.5
var tick_timer: float = 0.0
var is_totem: bool = false

func _ready() -> void:
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	if _setup_done:
		return
	_setup_done = true
	_setup_sprite()

func _process(delta: float) -> void:
	if not is_totem or not _totem_started:
		return

	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_apply_totem_effect()

func _apply_totem_effect() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= totem_radius:
			# Apply damage first
			if totem_damage > 0 and enemy.has_method("take_damage"):
				var tick_damage = totem_damage * tick_interval
				enemy.take_damage(tick_damage, false)
			# Apply slow
			if totem_slow_percent > 0 and enemy.has_method("apply_slow"):
				enemy.apply_slow(totem_slow_percent, totem_slow_duration)

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 15.0)
	frames.set_animation_loop("default", is_looping)

	var source_path = "res://assets/sprites/effects/pack2/IceCast_96x96.png"
	var frame_size = 96

	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var frame_count = total_width / frame_size

			for i in range(frame_count):
				var frame_img = Image.create(frame_size, frame_size, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_size, 0, frame_size, frame_size), Vector2i.ZERO)
				frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.play("default")

	if is_looping:
		get_tree().create_timer(duration).timeout.connect(_on_duration_finished)
	else:
		sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	queue_free()

func _on_duration_finished() -> void:
	is_totem = false  # Stop applying effects
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func setup(ability_duration: float, ability_radius: float = 100.0, damage: float = 0.0, slow_percent: float = 0.0, slow_duration: float = 0.0) -> void:
	duration = ability_duration
	totem_radius = ability_radius
	totem_damage = damage
	totem_slow_percent = slow_percent
	totem_slow_duration = slow_duration
	effect_scale = ability_radius / 60.0
	is_totem = true  # Enable totem functionality when setup is called with params

	# If setup is called before _ready completes, mark as done and setup now
	if not _setup_done:
		_setup_done = true
		_setup_sprite()
	elif sprite:
		sprite.scale = Vector2(effect_scale, effect_scale)

	# Start totem processing after setup is complete
	_totem_started = true
