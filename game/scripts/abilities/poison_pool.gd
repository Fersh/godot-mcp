extends Node2D

# Poison Pool - A damaging area left behind by Toxic Traits passive

var lifetime: float = 3.0
var damage_per_tick: float = 3.0
var tick_interval: float = 0.5
var tick_timer: float = 0.0
var elapsed_time: float = 0.0

var pool_radius: float = 30.0
var enemies_in_pool: Array = []

# Visual
var alpha: float = 0.7
var bubble_time: float = 0.0

func _ready() -> void:
	# Create detection area
	var area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 4  # Enemy layer
	area.name = "DamageArea"

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = pool_radius
	collision.shape = shape
	area.add_child(collision)

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

func _process(delta: float) -> void:
	elapsed_time += delta
	bubble_time += delta * 4.0

	# Fade out over lifetime
	var life_ratio = 1.0 - (elapsed_time / lifetime)
	alpha = life_ratio * 0.7

	# Damage tick
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_deal_damage()

	# Clean up
	if elapsed_time >= lifetime:
		queue_free()

	queue_redraw()

func _deal_damage() -> void:
	for enemy in enemies_in_pool:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			var damage = damage_per_tick
			if AbilityManager:
				damage *= AbilityManager.get_summon_damage_multiplier()
			enemy.take_damage(damage)

			# Apply poison effect if possible
			if enemy.has_method("apply_poison"):
				enemy.apply_poison(damage_per_tick * 2, 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body not in enemies_in_pool:
		enemies_in_pool.append(body)

func _on_body_exited(body: Node2D) -> void:
	enemies_in_pool.erase(body)

func _draw() -> void:
	var bubble_offset = sin(bubble_time) * 0.15 + 1.0
	var current_radius = pool_radius * bubble_offset

	# Outer poison pool (sickly green)
	var poison_color = Color(0.2, 0.55, 0.15, alpha * 0.6)
	draw_circle(Vector2.ZERO, current_radius, poison_color)

	# Inner darker core
	var core_color = Color(0.1, 0.35, 0.05, alpha * 0.8)
	draw_circle(Vector2.ZERO, current_radius * 0.6, core_color)

	# Bubbling effect
	var bubble1 = (sin(bubble_time * 1.5) + 1.0) * 0.5
	var bubble2 = (sin(bubble_time * 2.0 + 1.0) + 1.0) * 0.5
	var bubble3 = (sin(bubble_time * 1.8 + 2.5) + 1.0) * 0.5

	var bubble_color = Color(0.4, 0.7, 0.2, alpha * 0.5 * bubble1)
	draw_circle(Vector2(8, -5), 4 + bubble1 * 3, bubble_color)

	bubble_color = Color(0.3, 0.6, 0.15, alpha * 0.5 * bubble2)
	draw_circle(Vector2(-10, 7), 3 + bubble2 * 2, bubble_color)

	bubble_color = Color(0.35, 0.65, 0.18, alpha * 0.5 * bubble3)
	draw_circle(Vector2(5, 10), 3 + bubble3 * 2, bubble_color)

	# Highlight
	var highlight_color = Color(0.5, 0.8, 0.3, alpha * 0.3)
	draw_circle(Vector2(-6, -6), current_radius * 0.15, highlight_color)
