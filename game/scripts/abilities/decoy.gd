extends Node2D

# Decoy for Mirror Image ability
# Taunts enemies and dies in one hit, exploding for minor damage

var owner_player: Node2D = null
var lifetime: float = 3.0
var health: float = 1.0
var explosion_damage: float = 10.0
var taunt_radius: float = 150.0

func _ready() -> void:
	# Visual - ghostly copy of player
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-12, -16),
		Vector2(12, -16),
		Vector2(12, 16),
		Vector2(-12, 16)
	])
	body.color = Color(0.5, 0.5, 1.0, 0.5)  # Translucent blue
	add_child(body)

	# Head
	var head = Polygon2D.new()
	var head_points: PackedVector2Array = []
	for i in 8:
		var angle = i * TAU / 8
		head_points.append(Vector2(cos(angle), sin(angle)) * 10.0 + Vector2(0, -22))
	head.polygon = head_points
	head.color = Color(0.5, 0.5, 1.0, 0.5)
	add_child(head)

	# Pulsing effect
	var tween = create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.3, 0.5)
	tween.tween_property(self, "modulate:a", 0.7, 0.5)

	# Apply taunt to nearby enemies
	apply_taunt()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0 or health <= 0:
		die()
		return

	# Keep taunting nearby enemies
	apply_taunt()

func apply_taunt() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < taunt_radius and enemy.has_method("set_target"):
				enemy.set_target(self)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	# Explosion on death
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= 60.0 and enemy.has_method("take_damage"):
				enemy.take_damage(explosion_damage)

	# Visual explosion
	spawn_explosion_effect()
	queue_free()

func spawn_explosion_effect() -> void:
	var effect = Node2D.new()
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)

	var circle = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in 16:
		var angle = i * TAU / 16
		points.append(Vector2(cos(angle), sin(angle)) * 30.0)
	circle.polygon = points
	circle.color = Color(0.5, 0.5, 1.0, 0.6)
	effect.add_child(circle)

	var tween = effect.create_tween()
	tween.tween_property(circle, "scale", Vector2(2, 2), 0.25)
	tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.25)
	tween.tween_callback(effect.queue_free)
