extends Node2D

# Blood Pool - A damaging area left behind when enemies die

var lifetime: float = 2.0
var damage_per_tick: float = 5.0
var tick_interval: float = 0.3
var tick_timer: float = 0.0
var elapsed_time: float = 0.0

var pool_radius: float = 25.0
var enemies_in_pool: Array = []

# Visual
var alpha: float = 0.8
var pulse_time: float = 0.0

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
	pulse_time += delta * 3.0

	# Fade out over lifetime
	var life_ratio = 1.0 - (elapsed_time / lifetime)
	alpha = life_ratio * 0.8

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

			# Apply slow if possible
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(0.2, 0.5)  # 20% slow for 0.5s

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body not in enemies_in_pool:
		enemies_in_pool.append(body)

func _on_body_exited(body: Node2D) -> void:
	enemies_in_pool.erase(body)

func _draw() -> void:
	var pulse = sin(pulse_time) * 0.1 + 1.0
	var current_radius = pool_radius * pulse

	# Outer blood pool
	var blood_color = Color(0.5, 0.05, 0.05, alpha * 0.6)
	draw_circle(Vector2.ZERO, current_radius, blood_color)

	# Inner darker core
	var core_color = Color(0.3, 0.0, 0.0, alpha * 0.8)
	draw_circle(Vector2.ZERO, current_radius * 0.6, core_color)

	# Highlight/shine
	var highlight_color = Color(0.7, 0.1, 0.1, alpha * 0.4)
	draw_circle(Vector2(-5, -5), current_radius * 0.2, highlight_color)

	# Some splatter spots
	var splat_color = Color(0.4, 0.0, 0.0, alpha * 0.5)
	draw_circle(Vector2(10, 8), 6 * pulse, splat_color)
	draw_circle(Vector2(-12, 5), 5 * pulse, splat_color)
	draw_circle(Vector2(5, -10), 4 * pulse, splat_color)
