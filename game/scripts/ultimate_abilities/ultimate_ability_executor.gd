extends Node
class_name UltimateAbilityExecutor

# Executes ultimate abilities with epic visual effects
# Each ultimate has powerful, screen-affecting effects

var _effect_scenes: Dictionary = {}

func execute(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Main entry point - execute an ultimate ability."""
	if not ultimate or not player:
		return

	# Route to specific ultimate handler based on ID
	match ultimate.id:
		# Archer Ultimates
		"arrow_of_judgment":
			_execute_arrow_of_judgment(ultimate, player)
		"phantom_volley":
			_execute_phantom_volley(ultimate, player)
		"hunt_the_prey":
			_execute_hunt_the_prey(ultimate, player)
		"time_dilation_field":
			_execute_time_dilation_field(ultimate, player)
		"rain_of_thousand_arrows":
			_execute_rain_of_thousand_arrows(ultimate, player)

		# Knight Ultimates
		"aegis_immortal":
			_execute_aegis_immortal(ultimate, player)
		"judgment_day":
			_execute_judgment_day(ultimate, player)
		"unbreakable_will":
			_execute_unbreakable_will(ultimate, player)
		"warlords_challenge":
			_execute_warlords_challenge(ultimate, player)
		"chains_retribution":
			_execute_chains_retribution(ultimate, player)

		# Beast Ultimates
		"primal_rage":
			_execute_primal_rage(ultimate, player)
		"blood_tempest":
			_execute_blood_tempest(ultimate, player)
		"feast_carnage":
			_execute_feast_carnage(ultimate, player)
		"savage_instinct":
			_execute_savage_instinct(ultimate, player)
		"apex_predator":
			_execute_apex_predator(ultimate, player)

		# Mage Ultimates
		"meteor_swarm":
			_execute_meteor_swarm(ultimate, player)
		"arcane_singularity":
			_execute_arcane_singularity(ultimate, player)
		"time_rewind":
			_execute_time_rewind(ultimate, player)
		"elemental_mastery":
			_execute_elemental_mastery(ultimate, player)
		"mirror_dimension":
			_execute_mirror_dimension(ultimate, player)

		# Monk Ultimates
		"thousand_fist_barrage":
			_execute_thousand_fist_barrage(ultimate, player)
		"inner_peace":
			_execute_inner_peace(ultimate, player)
		"dragons_awakening":
			_execute_dragons_awakening(ultimate, player)
		"perfect_harmony":
			_execute_perfect_harmony(ultimate, player)
		"astral_projection":
			_execute_astral_projection(ultimate, player)

		_:
			push_warning("Unknown ultimate ability: " + ultimate.id)

# ============================================
# HELPER FUNCTIONS
# ============================================

func _get_damage(ultimate: UltimateAbilityData) -> float:
	"""Calculate ultimate damage with player stats."""
	var base = ultimate.base_damage
	var damage_mult = 1.0
	if AbilityManager:
		damage_mult = AbilityManager.get_damage_multiplier()
	return base * ultimate.damage_multiplier * damage_mult

func _get_enemies_in_radius(center: Vector2, radius: float) -> Array:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var result = []
	for enemy in enemies:
		if is_instance_valid(enemy):
			if center.distance_to(enemy.global_position) <= radius:
				result.append(enemy)
	return result

func _get_nearest_enemy(origin: Vector2, max_range: float = INF) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist = max_range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = origin.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy

	return nearest

func _get_strongest_enemy(origin: Vector2, max_range: float = INF) -> Node2D:
	"""Get the enemy with most HP in range."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var strongest: Node2D = null
	var highest_hp = 0.0

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = origin.distance_to(enemy.global_position)
			if dist <= max_range:
				var hp = enemy.health if "health" in enemy else 1.0
				if hp > highest_hp:
					highest_hp = hp
					strongest = enemy

	return strongest

func _get_attack_direction(player: Node2D) -> Vector2:
	if player.has_method("get_attack_direction"):
		return player.get_attack_direction()
	if "attack_direction" in player:
		return player.attack_direction
	if "facing_right" in player:
		return Vector2.RIGHT if player.facing_right else Vector2.LEFT
	return Vector2.RIGHT

func _deal_damage_to_enemy(enemy: Node2D, damage: float, is_crit: bool = false) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, is_crit)

func _apply_stun_to_enemy(enemy: Node2D, duration: float) -> void:
	if enemy.has_method("apply_stun"):
		enemy.apply_stun(duration)
	elif enemy.has_method("apply_stagger"):
		enemy.apply_stagger()

func _apply_slow_to_enemy(enemy: Node2D, percent: float, duration: float) -> void:
	if enemy.has_method("apply_slow"):
		enemy.apply_slow(percent, duration)

func _apply_knockback_to_enemy(enemy: Node2D, direction: Vector2, force: float) -> void:
	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(direction * force)

func _spawn_effect(effect_id: String, position: Vector2, parent: Node = null) -> Node:
	"""Spawn a visual effect at a position."""
	var scene_path = "res://scenes/effects/ability_effects/" + effect_id + ".tscn"

	if not _effect_scenes.has(effect_id):
		if ResourceLoader.exists(scene_path):
			_effect_scenes[effect_id] = load(scene_path)

	var scene = _effect_scenes.get(effect_id)
	if scene:
		var effect = scene.instantiate()
		effect.global_position = position
		if parent:
			parent.add_child(effect)
		else:
			get_tree().current_scene.add_child(effect)
		return effect

	# Fallback: create simple visual
	return _spawn_generic_effect(position, parent)

func _spawn_generic_effect(position: Vector2, parent: Node = null) -> Node:
	var effect = Node2D.new()
	effect.global_position = position

	if parent:
		parent.add_child(effect)
	else:
		get_tree().current_scene.add_child(effect)

	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

	return effect

func _play_sound(sound_name: String) -> void:
	if SoundManager:
		if SoundManager.has_method("play_" + sound_name):
			SoundManager.call("play_" + sound_name)

func _screen_shake(intensity: String = "medium") -> void:
	if JuiceManager:
		match intensity:
			"small":
				JuiceManager.shake_small()
			"medium":
				JuiceManager.shake_medium()
			"large":
				JuiceManager.shake_large()
			"ultimate":
				JuiceManager.shake_ultimate()

func _impact_pause() -> void:
	if JuiceManager:
		JuiceManager.hitstop_medium()

# ============================================
# ARCHER ULTIMATES
# ============================================

func _execute_arrow_of_judgment(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""5000% damage single target nuke, executes below 25% HP."""
	var damage = _get_damage(ultimate)
	var target = _get_strongest_enemy(player.global_position, ultimate.range_distance)

	if not target:
		target = _get_nearest_enemy(player.global_position)

	if not target:
		return

	# Spawn massive arrow projectile
	var direction = (target.global_position - player.global_position).normalized()
	_spawn_judgment_arrow(player.global_position, direction, target, damage)

	_play_sound("arrow")
	_screen_shake("ultimate")

func _spawn_judgment_arrow(start: Vector2, direction: Vector2, target: Node2D, damage: float) -> void:
	"""Spawn the divine arrow that seeks its target."""
	var arrow = Node2D.new()
	arrow.global_position = start
	get_tree().current_scene.add_child(arrow)

	# Tween to target
	var tween = arrow.create_tween()
	tween.tween_property(arrow, "global_position", target.global_position, 0.3)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		if is_instance_valid(target):
			# Check for execute
			var hp_percent = target.health / target.max_health if "max_health" in target else 1.0
			if hp_percent < 0.25:
				# Execute - instant kill
				_deal_damage_to_enemy(target, target.health + 1000)
			else:
				_deal_damage_to_enemy(target, damage, true)  # Always crit

			_spawn_effect("explosion_sprite", target.global_position)
			_impact_pause()

		arrow.queue_free()
	)

func _execute_phantom_volley(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Summon 5 spectral archers for 8 seconds."""
	var duration = ultimate.duration
	var damage_mult = ultimate.damage_multiplier

	# Create 5 phantom archers around the player
	for i in range(5):
		var angle = TAU * i / 5
		var offset = Vector2(cos(angle), sin(angle)) * 60
		_spawn_phantom_archer(player, offset, duration, damage_mult)

	_play_sound("buff")
	_screen_shake("medium")

func _spawn_phantom_archer(player: Node2D, offset: Vector2, duration: float, damage_mult: float) -> void:
	"""Create a phantom that fires arrows alongside the player."""
	# This would ideally be a proper scene, but for now we simulate it
	var attack_interval = 0.5
	var attacks = int(duration / attack_interval)

	for i in range(attacks):
		get_tree().create_timer(attack_interval * i).timeout.connect(func():
			if not is_instance_valid(player):
				return

			var phantom_pos = player.global_position + offset
			var target = _get_nearest_enemy(phantom_pos, 400.0)

			if target and is_instance_valid(target):
				var base_damage = AbilityManager.get_damage_multiplier() if AbilityManager else 1.0
				_deal_damage_to_enemy(target, base_damage * damage_mult)
		)

func _execute_hunt_the_prey(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Mark strongest enemy, +50% speed and +200% damage to them for 10s."""
	var duration = ultimate.duration
	var target = _get_strongest_enemy(player.global_position, 600.0)

	if not target:
		return

	# Mark the target visually
	var mark_effect = _spawn_effect("target_mark", target.global_position, target)

	# Apply speed boost to player
	if player.has_method("apply_speed_boost"):
		player.apply_speed_boost(1.5, duration)

	# Create tracking damage buff
	var tick_interval = 0.2
	var ticks = int(duration / tick_interval)

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(player) or not is_instance_valid(target):
				return
			# The damage boost is applied through the ability system
		)

	# Reset cooldown by 50% on kill (would need event connection)
	_play_sound("buff")
	_screen_shake("small")

func _execute_time_dilation_field(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Create zone that slows enemies 80%, projectiles deal 150% damage. 6s."""
	var duration = ultimate.duration
	var radius = ultimate.radius
	var center = player.global_position

	# Create visual field
	var field = _spawn_effect("time_field", center)

	# Apply slow periodically
	var tick_interval = 0.1
	var ticks = int(duration / tick_interval)

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			var enemies = _get_enemies_in_radius(center, radius)
			for enemy in enemies:
				_apply_slow_to_enemy(enemy, ultimate.slow_percent, 0.2)
		)

	# Clean up after duration
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(field):
			field.queue_free()
	)

	_play_sound("time_stop")
	_screen_shake("medium")

func _execute_rain_of_thousand_arrows(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Arrows rain on all enemies for 5 seconds, 10 hits/second."""
	var duration = ultimate.duration
	# base_damage is 0.5 (50% per hit), damage_multiplier already factors in total
	var damage_per_hit = ultimate.base_damage * (AbilityManager.get_damage_multiplier() if AbilityManager else 1.0)

	var hits_per_second = 10
	var total_hits = int(duration * hits_per_second)

	for i in range(total_hits):
		get_tree().create_timer(float(i) / hits_per_second).timeout.connect(func():
			# Hit all enemies
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				if is_instance_valid(enemy):
					_deal_damage_to_enemy(enemy, damage_per_hit)
		)

	_spawn_effect("arrow_rain", player.global_position)
	_play_sound("arrow_storm")
	_screen_shake("large")

# ============================================
# KNIGHT ULTIMATES
# ============================================

func _execute_aegis_immortal(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""5 second invulnerability, reflect 200% blocked damage."""
	var duration = ultimate.invulnerability_duration

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true, duration)

	# Visual shield effect
	var shield = _spawn_effect("divine_shield", player.global_position, player)

	# Clean up after duration
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(shield):
			shield.queue_free()
		if player.has_method("set_invulnerable"):
			player.set_invulnerable(false)
	)

	_play_sound("buff")
	_screen_shake("large")

func _execute_judgment_day(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Leap and crash, 1500% damage AoE, 3s stun."""
	var damage = _get_damage(ultimate)
	var radius = ultimate.radius
	var stun_duration = ultimate.stun_duration

	# Brief jump animation
	var original_pos = player.global_position
	var jump_height = 100

	var tween = player.create_tween()
	tween.tween_property(player, "global_position:y", original_pos.y - jump_height, 0.2)
	tween.tween_property(player, "global_position:y", original_pos.y, 0.15)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		# Land and deal damage
		var enemies = _get_enemies_in_radius(player.global_position, radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)
			_apply_stun_to_enemy(enemy, stun_duration)

		_spawn_effect("earthquake", player.global_position)
		_screen_shake("ultimate")
		_impact_pause()
	)

	_play_sound("ground_slam")

func _execute_unbreakable_will(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Passive death prevention - heal to 100% and gain 50% DR for 10s. Once per run."""
	# This is a passive that triggers on death
	# Store the state on the player
	if player.has_method("set_unbreakable_will"):
		player.set_unbreakable_will(true, ultimate.duration)

	_play_sound("buff")
	_screen_shake("medium")

func _execute_warlords_challenge(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Taunt all enemies, gain 75% DR and 100% damage for 8s."""
	var duration = ultimate.duration

	# Taunt all enemies (make them target player)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("set_forced_target"):
			enemy.set_forced_target(player, duration)

	# Apply buffs
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(2.0, duration)  # +100% damage
	if player.has_method("apply_damage_reduction"):
		player.apply_damage_reduction(0.75, duration)  # 75% DR

	_spawn_effect("battle_cry", player.global_position, player)
	_play_sound("buff")
	_screen_shake("medium")

func _execute_chains_retribution(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Bind all enemies in range for 4s, they take 50% more damage."""
	var duration = ultimate.stun_duration
	var radius = ultimate.radius

	var enemies = _get_enemies_in_radius(player.global_position, radius)
	for enemy in enemies:
		_apply_stun_to_enemy(enemy, duration)
		# Mark for increased damage taken
		if enemy.has_method("apply_vulnerability"):
			enemy.apply_vulnerability(1.5, duration)

	_spawn_effect("chains", player.global_position)
	_play_sound("chain")
	_screen_shake("large")
	_impact_pause()

# ============================================
# BEAST ULTIMATES
# ============================================

func _execute_primal_rage(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Transform for 10s: 2x attack speed, +50% damage, heal 5% on hit."""
	var duration = ultimate.duration

	# Apply buffs
	if player.has_method("apply_attack_speed_boost"):
		player.apply_attack_speed_boost(2.0, duration)
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(1.5, duration)
	if player.has_method("set_lifesteal"):
		player.set_lifesteal(0.05, duration)

	# Visual transformation
	if player.has_node("Sprite2D") or player.has_node("AnimatedSprite2D"):
		var sprite = player.get_node_or_null("Sprite2D")
		if not sprite:
			sprite = player.get_node_or_null("AnimatedSprite2D")
		if sprite:
			sprite.modulate = Color(1.5, 0.5, 0.5)
			get_tree().create_timer(duration).timeout.connect(func():
				if is_instance_valid(sprite):
					sprite.modulate = Color.WHITE
			)

	_spawn_effect("rage_aura", player.global_position, player)
	_play_sound("buff")
	_screen_shake("large")

func _execute_blood_tempest(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Spin for 4s, hit all nearby 5 times/sec for 75% damage each."""
	var duration = ultimate.duration
	var radius = ultimate.radius
	var damage_per_hit = _get_damage(ultimate) / 20.0  # 20 hits total

	var hits_per_second = 5
	var total_hits = int(duration * hits_per_second)

	for i in range(total_hits):
		get_tree().create_timer(float(i) / hits_per_second).timeout.connect(func():
			if not is_instance_valid(player):
				return
			var enemies = _get_enemies_in_radius(player.global_position, radius)
			for enemy in enemies:
				_deal_damage_to_enemy(enemy, damage_per_hit)
		)

	_spawn_effect("whirlwind", player.global_position, player)
	_play_sound("whirlwind")
	_screen_shake("medium")

func _execute_feast_carnage(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""For 12s, kills heal 10% and increase damage by 10% (stacks infinitely)."""
	var duration = ultimate.duration

	# Apply feast buff (needs to be tracked by player)
	if player.has_method("set_feast_of_carnage"):
		player.set_feast_of_carnage(true, duration)

	_spawn_effect("bloodlust", player.global_position, player)
	_play_sound("buff")
	_screen_shake("medium")

func _execute_savage_instinct(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""For 15s, enemies below 30% HP are auto-executed. Each kill extends 1s."""
	var duration = ultimate.duration

	if player.has_method("set_savage_instinct"):
		player.set_savage_instinct(true, duration)

	_spawn_effect("predator_eye", player.global_position, player)
	_play_sound("buff")
	_screen_shake("medium")

func _execute_apex_predator(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Mark all enemies. Dash through marked = 500% damage, resets dash. 8s."""
	var duration = ultimate.duration

	# Mark all enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			_spawn_effect("prey_mark", enemy.global_position, enemy)

	if player.has_method("set_apex_predator"):
		player.set_apex_predator(true, duration, _get_damage(ultimate))

	_play_sound("buff")
	_screen_shake("large")

# ============================================
# MAGE ULTIMATES
# ============================================

func _execute_meteor_swarm(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""12 meteors over 4s, each deals 300% damage in area + burning ground."""
	var duration = ultimate.duration
	var meteors = ultimate.projectile_count
	var damage_per_meteor = _get_damage(ultimate) / meteors

	for i in range(meteors):
		get_tree().create_timer(duration * i / meteors).timeout.connect(func():
			# Random position in wide area
			var offset = Vector2(
				randf_range(-300, 300),
				randf_range(-200, 200)
			)
			var impact_pos = player.global_position + offset
			impact_pos.x = clamp(impact_pos.x, -60, 1596)
			impact_pos.y = clamp(impact_pos.y, 40, 1382 - 40)

			# Deal damage
			var enemies = _get_enemies_in_radius(impact_pos, ultimate.radius)
			for enemy in enemies:
				_deal_damage_to_enemy(enemy, damage_per_meteor)

			_spawn_effect("meteor_strike", impact_pos)
			_screen_shake("medium")
		)

	_play_sound("meteor")

func _execute_arcane_singularity(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Black hole pulls enemies for 3s, then explodes for 2000% damage."""
	var duration = ultimate.duration
	var radius = ultimate.radius
	var center = player.global_position

	var singularity = _spawn_effect("black_hole", center)

	# Pull enemies
	var pull_interval = 0.1
	var pull_ticks = int(duration / pull_interval)

	for i in range(pull_ticks):
		get_tree().create_timer(pull_interval * i).timeout.connect(func():
			var enemies = _get_enemies_in_radius(center, radius)
			for enemy in enemies:
				if is_instance_valid(enemy):
					var to_center = (center - enemy.global_position).normalized()
					_apply_knockback_to_enemy(enemy, to_center, 150.0 * pull_interval)
		)

	# Explode
	get_tree().create_timer(duration).timeout.connect(func():
		var damage = _get_damage(ultimate)
		var enemies = _get_enemies_in_radius(center, radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)

		_spawn_effect("explosion_sprite", center)
		_screen_shake("ultimate")
		_impact_pause()

		if is_instance_valid(singularity):
			singularity.queue_free()
	)

	_play_sound("black_hole")
	_screen_shake("large")

func _execute_time_rewind(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Record state. After 5s or reactivation, return to that position/HP."""
	var recorded_pos = player.global_position
	var recorded_hp = player.health if "health" in player else 100.0

	# Store for potential manual reactivation
	if player.has_method("set_time_rewind_state"):
		player.set_time_rewind_state(recorded_pos, recorded_hp, ultimate.duration)

	# Auto-trigger after duration
	get_tree().create_timer(ultimate.duration).timeout.connect(func():
		if not is_instance_valid(player):
			return
		if player.has_method("get_time_rewind_triggered") and player.get_time_rewind_triggered():
			return  # Already manually triggered

		player.global_position = recorded_pos
		if player.has_method("heal"):
			var heal_amount = recorded_hp - player.health
			if heal_amount > 0:
				player.heal(heal_amount)

		_spawn_effect("time_effect", recorded_pos)
		_screen_shake("large")
	)

	_spawn_effect("time_marker", recorded_pos)
	_play_sound("time_stop")
	_screen_shake("medium")

func _execute_elemental_mastery(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Fire ring (burn) + Ice nova (freeze 2s) + Lightning storm (chain 5). Each 200%."""
	var damage_per_element = _get_damage(ultimate) / 3.0

	# Fire ring
	var enemies = _get_enemies_in_radius(player.global_position, ultimate.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage_per_element)
		# Apply burn (DoT)
		if enemy.has_method("apply_burn"):
			enemy.apply_burn(3.0, damage_per_element * 0.5)  # (duration, damage_per_tick)

	_spawn_effect("fire_ring", player.global_position)

	# Ice nova (delayed)
	get_tree().create_timer(0.3).timeout.connect(func():
		var ice_enemies = _get_enemies_in_radius(player.global_position, ultimate.radius)
		for enemy in ice_enemies:
			_deal_damage_to_enemy(enemy, damage_per_element)
			_apply_stun_to_enemy(enemy, ultimate.stun_duration)

		_spawn_effect("frost_nova", player.global_position)
	)

	# Lightning storm (delayed)
	get_tree().create_timer(0.6).timeout.connect(func():
		var first_target = _get_nearest_enemy(player.global_position)
		if first_target:
			_chain_lightning(first_target, damage_per_element, 5)

		_spawn_effect("lightning_strike", player.global_position)
	)

	_play_sound("magic")
	_screen_shake("ultimate")

func _chain_lightning(start: Node2D, damage: float, chains: int) -> void:
	"""Chain lightning between enemies."""
	var current = start
	var hit = [current]

	for i in range(chains):
		if not is_instance_valid(current):
			break

		_deal_damage_to_enemy(current, damage * pow(0.8, i))
		_spawn_effect("lightning", current.global_position)

		# Find next target
		var enemies = get_tree().get_nodes_in_group("enemies")
		var next: Node2D = null
		var next_dist = 200.0

		for enemy in enemies:
			if is_instance_valid(enemy) and enemy not in hit:
				var dist = current.global_position.distance_to(enemy.global_position)
				if dist < next_dist:
					next_dist = dist
					next = enemy

		if next:
			hit.append(next)
			current = next
		else:
			break

func _execute_mirror_dimension(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""4 mirror images cast spells at 50% damage for 10s. Explode on death."""
	var duration = ultimate.duration
	var damage_mult = ultimate.damage_multiplier

	for i in range(4):
		var angle = TAU * i / 4
		var offset = Vector2(cos(angle), sin(angle)) * 80
		_spawn_mirror_image(player, offset, duration, damage_mult)

	_spawn_effect("mirror_flash", player.global_position)
	_play_sound("summon")
	_screen_shake("medium")

func _spawn_mirror_image(player: Node2D, offset: Vector2, duration: float, damage_mult: float) -> void:
	"""Create a mirror image that casts alongside player."""
	var attack_interval = 1.0
	var attacks = int(duration / attack_interval)

	for i in range(attacks):
		get_tree().create_timer(attack_interval * i).timeout.connect(func():
			if not is_instance_valid(player):
				return

			var image_pos = player.global_position + offset
			var target = _get_nearest_enemy(image_pos, 400.0)

			if target and is_instance_valid(target):
				var base_damage = AbilityManager.get_damage_multiplier() if AbilityManager else 1.0
				_deal_damage_to_enemy(target, base_damage * damage_mult * 0.5)
				_spawn_effect("magic_bolt", image_pos)
		)

# ============================================
# MONK ULTIMATES
# ============================================

func _execute_thousand_fist_barrage(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""30 strikes in 3s to nearest enemy. Final hit = 500%."""
	var target = _get_nearest_enemy(player.global_position, 200.0)
	if not target:
		return

	var duration = ultimate.duration
	var total_strikes = 30
	var damage_per_strike = _get_damage(ultimate) / total_strikes
	var final_strike_multiplier = 10.0  # 500% / 50%

	for i in range(total_strikes):
		get_tree().create_timer(duration * i / total_strikes).timeout.connect(func():
			if not is_instance_valid(target):
				return

			var is_final = (i == total_strikes - 1)
			var strike_damage = damage_per_strike * (final_strike_multiplier if is_final else 1.0)

			_deal_damage_to_enemy(target, strike_damage, is_final)
			_spawn_effect("punch_impact", target.global_position)

			if is_final:
				_screen_shake("ultimate")
				_impact_pause()
		)

	_play_sound("punch")
	_screen_shake("medium")

func _execute_inner_peace(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Heal to full over 3s, 90% DR during, cleanse debuffs."""
	var duration = ultimate.duration

	# Apply massive DR
	if player.has_method("apply_damage_reduction"):
		player.apply_damage_reduction(0.9, duration)

	# Cleanse debuffs
	if player.has_method("cleanse_debuffs"):
		player.cleanse_debuffs()

	# Heal over time
	var tick_interval = 0.1
	var ticks = int(duration / tick_interval)
	var max_hp = player.max_health if "max_health" in player else 100.0
	var heal_per_tick = max_hp / ticks

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if is_instance_valid(player) and player.has_method("heal"):
				player.heal(heal_per_tick)
		)

	_spawn_effect("meditation", player.global_position, player)
	_play_sound("heal")
	_screen_shake("small")

func _execute_dragons_awakening(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Channel dragon spirit for 8s. Attacks create shockwaves hitting all in line."""
	var duration = ultimate.duration

	if player.has_method("set_dragons_awakening"):
		player.set_dragons_awakening(true, duration, ultimate.range_distance, _get_damage(ultimate))

	# Visual transformation
	if player.has_node("Sprite2D") or player.has_node("AnimatedSprite2D"):
		var sprite = player.get_node_or_null("Sprite2D")
		if not sprite:
			sprite = player.get_node_or_null("AnimatedSprite2D")
		if sprite:
			sprite.modulate = Color(1.2, 0.8, 0.5)  # Golden dragon aura
			get_tree().create_timer(duration).timeout.connect(func():
				if is_instance_valid(sprite):
					sprite.modulate = Color.WHITE
			)

	_spawn_effect("dragon_aura", player.global_position, player)
	_play_sound("buff")
	_screen_shake("large")

func _execute_perfect_harmony(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""For 12s, every 4th attack triggers all 3 animations simultaneously, full damage each."""
	var duration = ultimate.duration

	if player.has_method("set_perfect_harmony"):
		player.set_perfect_harmony(true, duration)

	_spawn_effect("harmony_glow", player.global_position, player)
	_play_sound("buff")
	_screen_shake("medium")

func _execute_astral_projection(ultimate: UltimateAbilityData, player: Node2D) -> void:
	"""Leave body invulnerable, spirit fights at 200% speed/damage for 6s. Return heals 25%."""
	var duration = ultimate.invulnerability_duration

	# Make body invulnerable
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true, duration)

	# Apply speed and damage boost (spirit form)
	if player.has_method("apply_speed_boost"):
		player.apply_speed_boost(2.0, duration)
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(2.0, duration)

	# Visual - make player ghostly
	if player.has_node("Sprite2D") or player.has_node("AnimatedSprite2D"):
		var sprite = player.get_node_or_null("Sprite2D")
		if not sprite:
			sprite = player.get_node_or_null("AnimatedSprite2D")
		if sprite:
			sprite.modulate = Color(0.7, 0.7, 1.0, 0.7)  # Ghostly blue
			get_tree().create_timer(duration).timeout.connect(func():
				if is_instance_valid(sprite):
					sprite.modulate = Color.WHITE
			)

	# Heal on return
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(player) and player.has_method("heal"):
			var max_hp = player.max_health if "max_health" in player else 100.0
			player.heal(max_hp * ultimate.heal_amount)

		_spawn_effect("astral_return", player.global_position)
		_screen_shake("medium")
	)

	_spawn_effect("astral_form", player.global_position, player)
	_play_sound("summon")
	_screen_shake("large")
