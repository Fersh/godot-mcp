extends Node2D

# Chicken Companion - An angry chicken that pecks enemies

var target: Node2D = null
var player: Node2D = null

var move_speed: float = 150.0
var attack_range: float = 30.0
var attack_cooldown: float = 0.6
var attack_timer: float = 0.0
var base_damage: float = 8.0

var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var is_attacking: bool = false
var attack_anim_timer: float = 0.0

# Visual state
var facing_right: bool = true
var bob_offset: float = 0.0
var peck_offset: float = 0.0

# Colors
var body_color: Color = Color(1.0, 0.9, 0.7)  # Cream/white chicken
var beak_color: Color = Color(1.0, 0.6, 0.2)  # Orange beak
var comb_color: Color = Color(0.9, 0.2, 0.2)  # Red comb
var eye_color: Color = Color(0.1, 0.1, 0.1)   # Black eye

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player:
		global_position = player.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))

	# Randomize color slightly
	var hue_shift = randf_range(-0.05, 0.05)
	body_color = body_color.lightened(randf_range(-0.1, 0.1))

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	# Animation
	bob_offset = sin(Time.get_ticks_msec() / 100.0) * 2.0

	if is_attacking:
		attack_anim_timer += delta
		peck_offset = sin(attack_anim_timer * 30.0) * 5.0
		if attack_anim_timer > 0.2:
			is_attacking = false
			attack_anim_timer = 0.0
			peck_offset = 0.0

	# Find target
	target = find_closest_enemy()

	# Attack or chase
	attack_timer += delta

	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)

		# Face target
		facing_right = target.global_position.x > global_position.x

		if dist <= attack_range:
			# Attack!
			if attack_timer >= attack_cooldown:
				attack_timer = 0.0
				peck_target()
		else:
			# Chase target
			var dir = (target.global_position - global_position).normalized()
			global_position += dir * move_speed * delta
	else:
		# No target, stay near player or wander
		var dist_to_player = global_position.distance_to(player.global_position)

		if dist_to_player > 150:
			# Return to player
			var dir = (player.global_position - global_position).normalized()
			global_position += dir * move_speed * 0.8 * delta
			facing_right = dir.x > 0
		else:
			# Wander randomly
			wander_timer -= delta
			if wander_timer <= 0:
				wander_timer = randf_range(0.5, 2.0)
				wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				if wander_direction.length() > 0:
					facing_right = wander_direction.x > 0

			global_position += wander_direction * move_speed * 0.3 * delta

	queue_redraw()

func find_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = 200.0  # Detection range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	return closest

func peck_target() -> void:
	if target == null or not is_instance_valid(target):
		return

	is_attacking = true
	attack_anim_timer = 0.0

	# Deal damage
	if target.has_method("take_damage"):
		var damage = base_damage
		if AbilityManager:
			damage *= AbilityManager.get_summon_damage_multiplier()
		target.take_damage(damage)

	# Small knockback
	if target.has_method("apply_knockback"):
		var dir = (target.global_position - global_position).normalized()
		target.apply_knockback(dir * 50)

func _draw() -> void:
	var p = 2.0  # Pixel size
	var flip = -1.0 if facing_right else 1.0
	var y_bob = bob_offset
	var x_peck = peck_offset * flip

	# Body (oval shape)
	draw_circle(Vector2(x_peck, y_bob), 12, body_color)
	draw_circle(Vector2(x_peck - 2 * flip, y_bob + 2), 10, body_color.darkened(0.1))

	# Wing
	var wing_color = body_color.darkened(0.15)
	draw_circle(Vector2(x_peck + 4 * flip, y_bob + 2), 6, wing_color)

	# Head
	draw_circle(Vector2(x_peck - 8 * flip, y_bob - 4), 8, body_color)

	# Comb (on top of head)
	draw_rect(Rect2(x_peck - 10 * flip - 2, y_bob - 14, 4, 6), comb_color)
	draw_rect(Rect2(x_peck - 6 * flip - 2, y_bob - 12, 4, 4), comb_color)

	# Beak
	var beak_x = x_peck - 14 * flip
	if is_attacking:
		# Open beak during attack
		draw_rect(Rect2(beak_x, y_bob - 6, 6 * abs(flip), 3), beak_color)
		draw_rect(Rect2(beak_x, y_bob - 2, 6 * abs(flip), 3), beak_color.darkened(0.2))
	else:
		draw_rect(Rect2(beak_x, y_bob - 5, 6 * abs(flip), 4), beak_color)

	# Eye
	var eye_x = x_peck - 10 * flip
	draw_circle(Vector2(eye_x, y_bob - 5), 2, Color.WHITE)
	draw_circle(Vector2(eye_x - 0.5 * flip, y_bob - 5), 1, eye_color)

	# Angry eyebrow when attacking
	if is_attacking or target != null:
		draw_line(
			Vector2(eye_x - 3 * flip, y_bob - 9),
			Vector2(eye_x + 2 * flip, y_bob - 7),
			Color(0.3, 0.2, 0.1), 2
		)

	# Wattle (under beak)
	draw_circle(Vector2(x_peck - 12 * flip, y_bob + 2), 3, comb_color)

	# Legs
	var leg_color = beak_color.darkened(0.2)
	draw_line(Vector2(2, y_bob + 10), Vector2(2, y_bob + 16), leg_color, 2)
	draw_line(Vector2(-2, y_bob + 10), Vector2(-2, y_bob + 16), leg_color, 2)

	# Feet
	draw_line(Vector2(2, y_bob + 16), Vector2(5, y_bob + 18), leg_color, 2)
	draw_line(Vector2(2, y_bob + 16), Vector2(-1, y_bob + 18), leg_color, 2)
	draw_line(Vector2(-2, y_bob + 16), Vector2(1, y_bob + 18), leg_color, 2)
	draw_line(Vector2(-2, y_bob + 16), Vector2(-5, y_bob + 18), leg_color, 2)

	# Tail feathers
	var tail_x = x_peck + 10 * flip
	draw_line(Vector2(tail_x, y_bob - 2), Vector2(tail_x + 6 * flip, y_bob - 8), body_color.darkened(0.1), 3)
	draw_line(Vector2(tail_x, y_bob), Vector2(tail_x + 8 * flip, y_bob - 4), body_color, 3)
	draw_line(Vector2(tail_x, y_bob + 2), Vector2(tail_x + 6 * flip, y_bob), body_color.darkened(0.05), 3)
