extends Node2D

# Fire Pool - A damaging area left behind by Blazing Trail passive

var lifetime: float = 2.5
var damage_per_tick: float = 5.0
var tick_interval: float = 0.3
var tick_timer: float = 0.0
var elapsed_time: float = 0.0

var pool_radius: float = 25.0
var enemies_in_pool: Array = []

# Visual
var alpha: float = 0.8
var flicker_time: float = 0.0

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
	flicker_time += delta * 8.0

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

			# Apply burn effect if possible
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(damage_per_tick, 1.5)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body not in enemies_in_pool:
		enemies_in_pool.append(body)

func _on_body_exited(body: Node2D) -> void:
	enemies_in_pool.erase(body)

func _draw() -> void:
	var flicker = sin(flicker_time) * 0.1 + 1.0
	var current_radius = pool_radius * flicker

	# Outer fire glow (orange/yellow)
	var outer_color = Color(1.0, 0.5, 0.1, alpha * 0.4)
	draw_circle(Vector2.ZERO, current_radius * 1.3, outer_color)

	# Main fire (bright orange)
	var fire_color = Color(1.0, 0.4, 0.0, alpha * 0.7)
	draw_circle(Vector2.ZERO, current_radius, fire_color)

	# Inner hot core (yellow)
	var core_color = Color(1.0, 0.7, 0.2, alpha * 0.9)
	draw_circle(Vector2.ZERO, current_radius * 0.5, core_color)

	# Flickering flames
	var flame1 = (sin(flicker_time * 2.0) + 1.0) * 0.5
	var flame2 = (sin(flicker_time * 2.5 + 1.0) + 1.0) * 0.5
	var flame3 = (sin(flicker_time * 1.8 + 2.0) + 1.0) * 0.5

	var flame_color = Color(1.0, 0.6, 0.1, alpha * 0.6 * flame1)
	draw_circle(Vector2(6, -8), 5 + flame1 * 4, flame_color)

	flame_color = Color(1.0, 0.5, 0.0, alpha * 0.6 * flame2)
	draw_circle(Vector2(-8, -5), 4 + flame2 * 3, flame_color)

	flame_color = Color(1.0, 0.7, 0.2, alpha * 0.5 * flame3)
	draw_circle(Vector2(3, -10), 3 + flame3 * 3, flame_color)

	# Bright center highlight
	var highlight_color = Color(1.0, 0.9, 0.5, alpha * 0.4)
	draw_circle(Vector2(0, -2), current_radius * 0.2, highlight_color)
