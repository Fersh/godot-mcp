extends Node2D

# Skeleton minion for Summoner's Aid ability

var owner_player: Node2D = null
var health: float = 30.0
var damage: float = 10.0
var speed: float = 150.0
var attack_range: float = 40.0
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var lifetime: float = 5.0  # 5 second duration
var current_target: Node2D = null

var sprite: Sprite2D = null
var animation_timer: float = 0.0
var animation_frame: int = 0

func _ready() -> void:
	# Use the skeleton enemy sprite
	sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/SkeletalWarrior_Sprites.png"):
		sprite.texture = load("res://assets/sprites/SkeletalWarrior_Sprites.png")
		sprite.hframes = 10
		sprite.vframes = 10
		sprite.frame = 0
		sprite.scale = Vector2(2.0, 2.0)
		# Add a green tint to distinguish from enemy skeletons
		sprite.modulate = Color(0.7, 1.0, 0.7, 1.0)
	add_child(sprite)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0 or health <= 0:
		die()
		return

	attack_timer -= delta

	# Find target
	find_target()

	if current_target and is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)

		if dist <= attack_range:
			# Attack
			if attack_timer <= 0:
				attack()
		else:
			# Move toward target
			var direction = (current_target.global_position - global_position).normalized()
			global_position += direction * speed * delta
	elif owner_player and is_instance_valid(owner_player):
		# Follow player if no target
		var dist_to_player = global_position.distance_to(owner_player.global_position)
		if dist_to_player > 100.0:
			var direction = (owner_player.global_position - global_position).normalized()
			global_position += direction * speed * delta

func find_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = 300.0  # Detection range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	current_target = closest

func attack() -> void:
	attack_timer = attack_cooldown

	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(damage)

	# Attack visual
	var slash = Line2D.new()
	slash.add_point(global_position)
	slash.add_point(current_target.global_position)
	slash.width = 3.0
	slash.default_color = Color(0.9, 0.9, 0.8, 0.8)
	get_tree().current_scene.add_child(slash)

	var tween = create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(slash.queue_free)

func take_damage(amount: float) -> void:
	health -= amount
	modulate = Color(1, 0.5, 0.5, 1)

	var tween = create_tween()
	# Reset to green tint (friendly skeleton)
	tween.tween_property(self, "modulate", Color(0.7, 1.0, 0.7, 1.0), 0.1)

	if health <= 0:
		die()

func die() -> void:
	# Death effect
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.5
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2(0, 200)
	particles.color = Color(0.9, 0.9, 0.8, 1.0)
	get_tree().current_scene.add_child(particles)

	# Auto-cleanup particles
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)

	queue_free()
