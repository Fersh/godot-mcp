extends Node2D

# Frost Totem using Buff Totem spritesheet
# Slows and damages nearby enemies

var sprite: Sprite2D
var duration: float = 6.0
var radius: float = 100.0
var damage: float = 0.0  # DPS
var slow_percent: float = 0.5
var slow_duration: float = 1.0
var tick_interval: float = 0.5
var tick_timer: float = 0.0
var lifetime: float = 0.0

# Animation (Buff Totem: 256x128, frames are 32x32)
var animation_timer: float = 0.0
var current_frame: int = 0
var hframes: int = 8  # 256/32 = 8 columns
var vframes: int = 4  # 128/32 = 4 rows
var idle_row: int = 0  # Idle animation row
var frames_per_row: int = 8
var animation_speed: float = 10.0

# Frost aura visual
var aura_circle: Node2D = null

func _ready() -> void:
	_setup_sprite()
	_setup_aura()

func _setup_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.scale = Vector2(2.0, 2.0)
	# Tint blue for frost
	sprite.modulate = Color(0.7, 0.85, 1.0, 1.0)
	add_child(sprite)

	var texture_path = "res://assets/sprites/Buff Totem Sprite Sheet v1.1.png"
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		sprite.hframes = hframes
		sprite.vframes = vframes
		sprite.frame = 0

func _setup_aura() -> void:
	# Aura is drawn in _draw()

func setup(p_duration: float, p_radius: float = 100.0, p_damage: float = 0.0, p_slow_percent: float = 0.5, p_slow_duration: float = 1.0) -> void:
	duration = p_duration
	radius = p_radius
	damage = p_damage
	slow_percent = p_slow_percent
	slow_duration = p_slow_duration

func _process(delta: float) -> void:
	lifetime += delta

	# Check if expired
	if lifetime >= duration:
		_despawn()
		return

	# Animate sprite
	_animate(delta)

	# Apply effects to enemies
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_apply_frost_effect()

	# Draw aura
	queue_redraw()

func _animate(delta: float) -> void:
	if sprite == null:
		return

	animation_timer += delta * animation_speed

	if animation_timer >= 1.0:
		animation_timer = 0.0
		current_frame = (current_frame + 1) % frames_per_row

	sprite.frame = idle_row * hframes + current_frame

func _apply_frost_effect() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= radius:
			# Apply damage
			if damage > 0 and enemy.has_method("take_damage"):
				var tick_damage = max(1.0, damage * tick_interval)
				enemy.take_damage(tick_damage, false)
			# Apply slow
			if slow_percent > 0 and enemy.has_method("apply_slow"):
				enemy.apply_slow(slow_percent, slow_duration)

func _draw() -> void:
	# Draw frost aura circle
	var alpha = 0.15 + sin(lifetime * 3.0) * 0.05
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.7, 1.0, alpha))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.6, 0.8, 1.0, 0.4), 2.0)

func _despawn() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
