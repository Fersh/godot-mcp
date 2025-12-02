extends EnemyBase

# Eye Monster - Floating eye that spits acid projectiles
# Passive ranged attacker, keeps distance and pelts player with acid

@export var acid_projectile_scene: PackedScene
@export var preferred_range: float = 170.0
@export var acid_speed: float = 120.0

func _on_ready() -> void:
	enemy_type = "eye_monster"

	# Eye Monster stats - ranged glass cannon
	speed = 42.0            # Slow movement (floating)
	max_health = 18.0       # Fragile
	attack_damage = 9.0     # Decent acid damage
	attack_cooldown = 1.8   # Moderate fire rate
	attack_range = 220.0    # Long range
	windup_duration = 0.35  # Visible buildup
	animation_speed = 8.0

	# Eye Monster sprite sheet: 8 columns x 5 rows (32x32 frames)
	# Row 0: Idle/Move (8 frames)
	# Row 1: Detect (4 frames)
	# Row 2: Look around (8 frames)
	# Row 3: Prep (4 frames)
	# Row 4: Drip Acid/Attack (6 frames)
	ROW_IDLE = 0
	ROW_MOVE = 0
	ROW_ATTACK = 4  # Acid drip
	ROW_DAMAGE = 1  # Use detect as hurt
	ROW_DEATH = 4   # Use attack for death (no dedicated)
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 8,   # IDLE/MOVE
		1: 4,   # DETECT
		2: 8,   # LOOK
		3: 4,   # PREP
		4: 6,   # ACID DRIP
	}

	# Scale sprite for visibility
	if sprite:
		sprite.scale = Vector2(2.2, 2.2)

func _process_behavior(delta: float) -> void:
	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# Maintain safe distance
		if distance < preferred_range * 0.6:
			# Too close - float away
			velocity = -dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, -dir_normalized)
		elif distance > attack_range:
			# Too far - drift closer
			velocity = dir_normalized * speed * 0.8
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			# In range - hover and attack
			velocity = Vector2.ZERO
			update_animation(delta, ROW_ATTACK, dir_normalized)
			if can_attack:
				start_attack()
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func _on_attack_complete() -> void:
	fire_acid()
	can_attack = false

func fire_acid() -> void:
	if not player or not is_instance_valid(player):
		return

	var direction = (player.global_position - global_position).normalized()

	if acid_projectile_scene:
		var acid = acid_projectile_scene.instantiate()
		acid.global_position = global_position + direction * 12
		acid.direction = direction
		acid.speed = acid_speed
		acid.damage = attack_damage
		# Give it a green tint if possible
		if acid.has_node("Sprite2D"):
			acid.get_node("Sprite2D").modulate = Color(0.5, 1.0, 0.3, 1.0)
		elif acid.has_node("Sprite"):
			acid.get_node("Sprite").modulate = Color(0.5, 1.0, 0.3, 1.0)
		get_parent().add_child(acid)
	else:
		# Fallback direct damage
		if player.has_method("take_damage"):
			var dist = global_position.distance_to(player.global_position)
			if dist <= attack_range:
				player.take_damage(attack_damage)
