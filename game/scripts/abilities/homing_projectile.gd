extends Node2D

# Homing projectile for Ceremonial Dagger and Missile Barrage abilities

var target: Node2D = null
var damage: float = 20.0
var source: Node2D = null
var speed: float = 400.0
var turn_speed: float = 8.0
var lifetime: float = 3.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Create visual
	var sprite = Sprite2D.new()
	sprite.modulate = Color(1.0, 0.8, 0.3, 1.0)
	add_child(sprite)

	# Create a simple triangle shape using a polygon
	var polygon = Polygon2D.new()
	polygon.polygon = PackedVector2Array([
		Vector2(-8, -4),
		Vector2(8, 0),
		Vector2(-8, 4)
	])
	polygon.color = Color(1.0, 0.8, 0.3, 1.0)
	add_child(polygon)

	# Add trail effect
	var trail = Line2D.new()
	trail.name = "Trail"
	trail.width = 3.0
	trail.default_color = Color(1.0, 0.8, 0.3, 0.5)
	trail.width_curve = Curve.new()
	trail.width_curve.add_point(Vector2(0, 1))
	trail.width_curve.add_point(Vector2(1, 0))
	add_child(trail)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return

	# Update trail
	var trail = get_node_or_null("Trail")
	if trail:
		trail.add_point(global_position)
		if trail.get_point_count() > 10:
			trail.remove_point(0)

	# Home toward target
	if is_instance_valid(target):
		var desired_direction = (target.global_position - global_position).normalized()
		direction = direction.lerp(desired_direction, turn_speed * delta).normalized()

	# Move
	global_position += direction * speed * delta
	rotation = direction.angle()

	# Check for collision with enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < 20.0:
				hit_enemy(enemy)
				return

func hit_enemy(enemy: Node2D) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	# Visual effect
	spawn_hit_effect()
	queue_free()

func spawn_hit_effect() -> void:
	var effect = Node2D.new()
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)

	var circle = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in 16:
		var angle = i * TAU / 16
		points.append(Vector2(cos(angle), sin(angle)) * 15.0)
	circle.polygon = points
	circle.color = Color(1.0, 0.8, 0.3, 0.8)
	effect.add_child(circle)

	var tween = effect.create_tween()
	tween.tween_property(circle, "scale", Vector2(2, 2), 0.2)
	tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.2)
	tween.tween_callback(effect.queue_free)
