extends Node2D

# Sentry Turret using Fire Totem spritesheet
# Animated totem that shoots at nearby enemies

var sprite: Sprite2D
var duration: float = 8.0
var damage: float = 10.0
var shoot_interval: float = 0.5
var shoot_timer: float = 0.0
var lifetime: float = 0.0
var fire_range: float = 300.0

# Animation (Fire Totem: 448x160, frames are 64x32)
var animation_timer: float = 0.0
var current_frame: int = 0
var hframes: int = 7  # 448/64 = 7 columns
var vframes: int = 5  # 160/32 = 5 rows
var idle_row: int = 0  # Idle animation row
var shoot_row: int = 2  # Attack/shoot animation row
var frames_per_row: int = 7
var animation_speed: float = 10.0
var is_shooting: bool = false
var shoot_anim_timer: float = 0.0

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.scale = Vector2(1.5, 1.5)
	add_child(sprite)

	var texture_path = "res://assets/sprites/Fire TotemSprite Sheet v1.1.png"
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		sprite.hframes = hframes
		sprite.vframes = vframes
		sprite.frame = 0
	else:
		# Fallback: draw a simple turret shape
		_draw_fallback()

func _draw_fallback() -> void:
	# Remove sprite and use _draw instead
	if sprite:
		sprite.queue_free()
		sprite = null
	queue_redraw()

func _draw() -> void:
	if sprite == null:
		# Simple turret visual fallback
		draw_rect(Rect2(-12, -20, 24, 30), Color(0.5, 0.3, 0.2))
		draw_rect(Rect2(-8, -25, 16, 8), Color(0.6, 0.4, 0.3))
		draw_circle(Vector2(0, -28), 6, Color(1.0, 0.5, 0.2))

func setup(p_duration: float, p_damage: float) -> void:
	duration = p_duration
	damage = p_damage

func _process(delta: float) -> void:
	lifetime += delta

	# Check if expired
	if lifetime >= duration:
		_despawn()
		return

	# Animate
	_animate(delta)

	# Shooting logic
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		_try_shoot()

func _animate(delta: float) -> void:
	if sprite == null:
		return

	animation_timer += delta * animation_speed

	var row = idle_row
	var max_frames = frames_per_row

	# Use shoot animation briefly when shooting
	if is_shooting:
		shoot_anim_timer -= delta
		if shoot_anim_timer <= 0:
			is_shooting = false
		else:
			row = shoot_row

	# Cycle through frames
	if animation_timer >= 1.0:
		animation_timer = 0.0
		current_frame = (current_frame + 1) % max_frames

	sprite.frame = row * hframes + current_frame

func _try_shoot() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = fire_range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	if closest:
		_fire_at(closest)

func _fire_at(target: Node2D) -> void:
	# Trigger shoot animation
	is_shooting = true
	shoot_anim_timer = 0.3

	# Create laser/beam visual
	var line = Line2D.new()
	line.add_point(Vector2(0, -20))  # From totem top
	line.add_point(target.global_position - global_position)
	line.width = 3.0
	line.default_color = Color(1.0, 0.6, 0.2, 0.9)
	add_child(line)

	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(damage / (duration / shoot_interval))

	# Fade out line
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)

func _despawn() -> void:
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
