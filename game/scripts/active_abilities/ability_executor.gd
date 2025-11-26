extends Node
class_name AbilityExecutor

# Executes active abilities by delegating to specific ability handlers
# Each ability type has its own execution logic

# Preloaded effect scenes (lazy loaded)
var _effect_scenes: Dictionary = {}

func execute(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Main entry point - execute an ability."""
	if not ability or not player:
		return

	# Route to specific ability handler based on ID
	match ability.id:
		# Melee Common
		"cleave":
			_execute_cleave(ability, player)
		"shield_bash":
			_execute_shield_bash(ability, player)
		"ground_slam":
			_execute_ground_slam(ability, player)
		"spinning_attack":
			_execute_spinning_attack(ability, player)
		"dash_strike":
			_execute_dash_strike(ability, player)

		# Melee Rare
		"whirlwind":
			_execute_whirlwind(ability, player)
		"seismic_slam":
			_execute_seismic_slam(ability, player)
		"savage_leap":
			_execute_savage_leap(ability, player)
		"blade_rush":
			_execute_blade_rush(ability, player)
		"battle_cry":
			_execute_battle_cry(ability, player)

		# Melee Legendary
		"earthquake":
			_execute_earthquake(ability, player)
		"bladestorm":
			_execute_bladestorm(ability, player)
		"omnislash":
			_execute_omnislash(ability, player)
		"avatar_of_war":
			_execute_avatar_of_war(ability, player)
		"divine_shield":
			_execute_divine_shield(ability, player)

		# Ranged Common
		"power_shot":
			_execute_power_shot(ability, player)
		"explosive_arrow":
			_execute_explosive_arrow(ability, player)
		"multi_shot":
			_execute_multi_shot(ability, player)
		"quick_roll":
			_execute_quick_roll(ability, player)
		"throw_net":
			_execute_throw_net(ability, player)

		# Ranged Rare
		"rain_of_arrows":
			_execute_rain_of_arrows(ability, player)
		"piercing_volley":
			_execute_piercing_volley(ability, player)
		"cluster_bomb":
			_execute_cluster_bomb(ability, player)
		"fan_of_knives":
			_execute_fan_of_knives(ability, player)
		"sentry_turret":
			_execute_sentry_turret(ability, player)

		# Ranged Legendary
		"arrow_storm":
			_execute_arrow_storm(ability, player)
		"ballista_strike":
			_execute_ballista_strike(ability, player)
		"sentry_network":
			_execute_sentry_network(ability, player)
		"rain_of_vengeance":
			_execute_rain_of_vengeance(ability, player)
		"explosive_decoy":
			_execute_explosive_decoy(ability, player)

		# Global Common
		"fireball":
			_execute_fireball(ability, player)
		"frost_nova":
			_execute_frost_nova(ability, player)
		"healing_light":
			_execute_healing_light(ability, player)
		"throwing_bomb":
			_execute_throwing_bomb(ability, player)
		"blinding_flash":
			_execute_blinding_flash(ability, player)

		# Global Rare
		"chain_lightning":
			_execute_chain_lightning(ability, player)
		"meteor_strike":
			_execute_meteor_strike(ability, player)
		"totem_of_frost":
			_execute_totem_of_frost(ability, player)
		"shadowstep":
			_execute_shadowstep(ability, player)
		"time_slow":
			_execute_time_slow(ability, player)

		# Global Legendary
		"black_hole":
			_execute_black_hole(ability, player)
		"time_stop":
			_execute_time_stop(ability, player)
		"thunderstorm":
			_execute_thunderstorm(ability, player)
		"summon_golem":
			_execute_summon_golem(ability, player)
		"army_of_the_dead":
			_execute_army_of_the_dead(ability, player)

		_:
			push_warning("Unknown ability: " + ability.id)

# ============================================
# HELPER FUNCTIONS
# ============================================

func _get_damage(ability: ActiveAbilityData) -> float:
	"""Calculate ability damage with player stats."""
	return ActiveAbilityManager.calculate_ability_damage(ability)

func _get_enemies_in_radius(center: Vector2, radius: float) -> Array:
	"""Get all enemies within a radius."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var result = []
	for enemy in enemies:
		if is_instance_valid(enemy):
			if center.distance_to(enemy.global_position) <= radius:
				result.append(enemy)
	return result

func _get_enemies_in_arc(origin: Vector2, direction: Vector2, radius: float, arc_angle: float) -> Array:
	"""Get enemies within an arc in front of player."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var result = []
	var dir_angle = direction.angle()

	for enemy in enemies:
		if is_instance_valid(enemy):
			var to_enemy = enemy.global_position - origin
			var dist = to_enemy.length()
			if dist <= radius:
				var angle_diff = abs(to_enemy.angle() - dir_angle)
				if angle_diff > PI:
					angle_diff = TAU - angle_diff
				if angle_diff <= arc_angle / 2:
					result.append(enemy)
	return result

func _get_nearest_enemy(origin: Vector2, max_range: float = INF) -> Node2D:
	"""Get the nearest enemy to a position."""
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

func _get_enemy_cluster_center(origin: Vector2, search_radius: float = 300.0) -> Vector2:
	"""Find the center of the largest enemy cluster."""
	var enemies = _get_enemies_in_radius(origin, search_radius)
	if enemies.is_empty():
		return origin

	# Simple: return average position of all enemies in range
	var sum = Vector2.ZERO
	for enemy in enemies:
		sum += enemy.global_position
	return sum / enemies.size()

func _get_attack_direction(player: Node2D) -> Vector2:
	"""Get the direction the player is attacking/facing."""
	if player.has_method("get_attack_direction"):
		return player.get_attack_direction()
	if "attack_direction" in player:
		return player.attack_direction
	if "facing_right" in player:
		return Vector2.RIGHT if player.facing_right else Vector2.LEFT
	return Vector2.RIGHT

func _deal_damage_to_enemy(enemy: Node2D, damage: float, is_crit: bool = false) -> void:
	"""Apply damage to an enemy."""
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, is_crit)

func _apply_stun_to_enemy(enemy: Node2D, duration: float) -> void:
	"""Apply stun to an enemy."""
	if enemy.has_method("apply_stun"):
		enemy.apply_stun(duration)
	elif enemy.has_method("apply_stagger"):
		enemy.apply_stagger()

func _apply_slow_to_enemy(enemy: Node2D, percent: float, duration: float) -> void:
	"""Apply slow to an enemy."""
	if enemy.has_method("apply_slow"):
		enemy.apply_slow(percent, duration)

func _apply_knockback_to_enemy(enemy: Node2D, direction: Vector2, force: float) -> void:
	"""Apply knockback to an enemy."""
	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(direction * force)

func _spawn_effect(effect_id: String, position: Vector2, parent: Node = null) -> Node:
	"""Spawn a visual effect at a position."""
	# Map effect IDs to sprite-based effects
	var mapped_effect = _get_mapped_effect(effect_id)
	var scene_path = "res://scenes/effects/ability_effects/" + mapped_effect + ".tscn"

	# Check if effect scene exists
	if not _effect_scenes.has(mapped_effect):
		if ResourceLoader.exists(scene_path):
			_effect_scenes[mapped_effect] = load(scene_path)

	var scene = _effect_scenes.get(mapped_effect)
	if scene:
		var effect = scene.instantiate()
		effect.global_position = position
		if parent:
			parent.add_child(effect)
		else:
			get_tree().current_scene.add_child(effect)
		# Configure effect based on type
		_configure_spawned_effect(effect, effect_id)
		return effect

	# Fallback: use explosion effect for explosion-related effects
	if effect_id.contains("explosion") or effect_id.contains("explode") or effect_id == "black_hole_explosion":
		return _spawn_explosion_effect(position, parent)

	# Fallback: spawn generic impact for other effects
	return _spawn_generic_effect(position, parent)

func _get_mapped_effect(effect_id: String) -> String:
	"""Map ability effect IDs to sprite-based effect scenes."""
	match effect_id:
		# Slash/Melee effects
		"cleave", "slash", "omnislash":
			return "slash"
		"spinning_attack", "bladestorm":
			return "firespin"
		"whirlwind":
			return "tornado"

		# Impact/Smoke effects
		"ground_slam", "savage_leap_landing", "earthquake":
			return "impact_smoke"
		"shield_bash", "punch":
			return "punch_impact"
		"dash_strike", "blade_rush", "quick_roll", "dash":
			return "dash_smoke"

		# Explosion effects
		"explosion", "explosive_arrow", "cluster_bomb", "throwing_bomb", "black_hole_explosion":
			return "explosion_sprite"
		"meteor_strike":
			return "explosion_sprite"  # Large explosion
		"fireball":
			return "fireball_sprite"

		# Ice effects
		"frost_nova", "ice_shatter":
			return "ice_shatter"
		"totem_of_frost", "ice_cast":
			return "ice_cast"

		# Lightning effects
		"chain_lightning", "lightning_strike", "thunderstorm":
			return "lightning"

		# Holy/Light effects
		"healing_light", "blinding_flash", "holy":
			return "holy"
		"divine_shield":
			return "shield"
		"battle_cry":
			return "holy"  # Protection circle

		# Fire effects
		"avatar_of_war", "fire_aura":
			return "fire_cast"

		# Dark/Magic effects
		"black_hole":
			return "black_hole"
		"summon_burst", "dark_summon", "army_of_the_dead":
			return "magic_cast"
		"shadowstep":
			return "shadowstep"

		# Ground/Spike effects
		"seismic_slam", "spikes":
			return "spikes"

		# Poison effects
		"poison", "toxic":
			return "poison"

		_:
			return effect_id  # Return original if no mapping

func _configure_spawned_effect(effect: Node, effect_id: String) -> void:
	"""Configure effect properties based on original effect ID."""
	match effect_id:
		# Configure explosion sizes
		"meteor_strike", "earthquake", "black_hole_explosion":
			if effect.has_method("set_size_from_string"):
				effect.set_size_from_string("large")
		"cluster_bomb":
			if effect.has_method("set_size_from_string"):
				effect.set_size_from_string("medium")
		"explosive_arrow":
			if effect.has_method("set_size_from_string"):
				effect.set_size_from_string("small")

		# Configure impact types
		"ground_slam", "earthquake":
			if effect.has_method("set_impact_type"):
				effect.impact_type = 2  # BIG_SMOKE
		"savage_leap_landing":
			if effect.has_method("set_impact_type"):
				effect.impact_type = 3  # DUST_KICK

		# Configure holy types
		"healing_light":
			if effect.has_method("set_holy_type"):
				effect.holy_type = 0  # EXPLOSION
		"blinding_flash":
			if effect.has_method("set_holy_type"):
				effect.holy_type = 1  # CAST
		"battle_cry":
			if effect.has_method("set_holy_type"):
				effect.holy_type = 2  # PROTECTION

		# Configure fire types
		"avatar_of_war":
			if effect.has_method("set_fire_type"):
				effect.fire_type = 2  # AURA

		# Configure magic types
		"summon_burst":
			if effect.has_method("set_magic_type"):
				effect.magic_type = 2  # SUMMON
		"dark_summon", "army_of_the_dead":
			if effect.has_method("set_magic_type"):
				effect.magic_type = 1  # DARK
		"shadowstep":
			if effect.has_method("set_magic_type"):
				effect.magic_type = 3  # VORTEX

func _spawn_explosion_effect(position: Vector2, parent: Node = null) -> Node:
	"""Spawn the animated pixel explosion effect."""
	var explosion = Node2D.new()
	explosion.global_position = position

	var explosion_script = load("res://scripts/abilities/explosion_effect.gd")
	if explosion_script:
		explosion.set_script(explosion_script)

	if parent:
		parent.add_child(explosion)
	else:
		get_tree().current_scene.add_child(explosion)

	return explosion

func _spawn_generic_effect(position: Vector2, parent: Node = null) -> Node:
	"""Spawn a simple generic impact effect."""
	var effect = Node2D.new()
	effect.global_position = position

	# Simple flash effect that fades out
	var sprite = Sprite2D.new()
	sprite.texture = _get_generic_impact_texture()
	effect.add_child(sprite)

	if parent:
		parent.add_child(effect)
	else:
		get_tree().current_scene.add_child(effect)

	# Auto-cleanup after short delay
	get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

	return effect

func _get_generic_impact_texture() -> Texture2D:
	"""Get or create a simple white circle texture for generic effects."""
	if not _effect_scenes.has("_generic_texture"):
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 0))
		var center = Vector2(16, 16)
		for x in range(32):
			for y in range(32):
				var dist = Vector2(x, y).distance_to(center)
				if dist < 14:
					var alpha = 1.0 - (dist / 14.0)
					img.set_pixel(x, y, Color(1, 1, 1, alpha * 0.8))
		_effect_scenes["_generic_texture"] = ImageTexture.create_from_image(img)
	return _effect_scenes["_generic_texture"]

func _play_sound(sound_name: String) -> void:
	"""Play a sound effect."""
	if SoundManager:
		if SoundManager.has_method("play_" + sound_name):
			SoundManager.call("play_" + sound_name)
		elif SoundManager.has_method("play_ability_sound"):
			SoundManager.play_ability_sound(sound_name)

func _screen_shake(intensity: String = "medium") -> void:
	"""Trigger screen shake."""
	if JuiceManager:
		match intensity:
			"small":
				JuiceManager.shake_small()
			"medium":
				JuiceManager.shake_medium()
			"large":
				JuiceManager.shake_large()

func _impact_pause() -> void:
	"""Trigger a 1-frame pause for impact feel."""
	if JuiceManager:
		JuiceManager.hitstop_micro()

# ============================================
# MELEE ABILITIES - COMMON
# ============================================

func _execute_cleave(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)

	# Aim cleave TOWARDS nearest enemy (extended search range)
	var target = _get_nearest_enemy(player.global_position, ability.radius * 2.25)
	var direction: Vector2

	if target:
		direction = (target.global_position - player.global_position).normalized()
	else:
		direction = _get_attack_direction(player)

	# Hit enemies in arc in front of player
	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.radius, PI * 0.75)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	# Spawn effect with correct direction
	var effect = _spawn_effect("cleave", player.global_position)
	if effect and "direction" in effect:
		effect.direction = direction
	_play_sound("swing")
	_screen_shake("small")

func _execute_shield_bash(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var start_pos = player.global_position
	var dash_distance = 80.0  # Short forward dash

	# Aim shield bash TOWARDS nearest enemy (extended search range)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance * 2.25)
	var direction: Vector2

	if target:
		direction = (target.global_position - player.global_position).normalized()
	else:
		direction = _get_attack_direction(player)

	# Calculate end position with arena bounds
	var end_pos = start_pos + direction * dash_distance
	end_pos.x = clamp(end_pos.x, 40, 1536 - 40)
	end_pos.y = clamp(end_pos.y, 40, 1382 - 40)

	# Dash forward then hit
	var tween = create_tween()
	tween.tween_property(player, "global_position", end_pos, 0.1)
	tween.tween_callback(func():
		# Hit enemies in front after dash
		var enemies = _get_enemies_in_arc(player.global_position, direction, ability.range_distance, PI * 0.5)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)
			_apply_stun_to_enemy(enemy, ability.stun_duration)
			_apply_knockback_to_enemy(enemy, direction, ability.knockback_force)
		_impact_pause()
	)

	_spawn_effect("shield_bash", start_pos + direction * 30)
	_play_sound("shield_bash")
	_screen_shake("medium")

func _execute_ground_slam(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_slow_to_enemy(enemy, ability.slow_percent, ability.slow_duration)

	_spawn_effect("ground_slam", player.global_position)
	_play_sound("ground_slam")
	_screen_shake("medium")
	_impact_pause()

func _execute_spinning_attack(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	# Spawn effect and configure with ability radius
	var effect = _spawn_effect("spinning_attack", player.global_position)
	if effect and effect.has_method("setup"):
		effect.setup(0.5, ability.radius, damage, 1.0)  # Short duration, scale to radius

	_play_sound("swing")
	_screen_shake("small")

func _execute_dash_strike(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var start_pos = player.global_position

	# Dash TOWARDS nearest enemy (extended search range)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance * 3)
	var direction: Vector2
	var end_pos: Vector2

	if target:
		direction = (target.global_position - player.global_position).normalized()
		# Dash to just in front of the enemy (not through them)
		var dist_to_target = player.global_position.distance_to(target.global_position)
		var dash_dist = min(ability.range_distance, dist_to_target - 30)
		end_pos = start_pos + direction * max(dash_dist, 50)
	else:
		# No enemy, dash in attack direction
		direction = _get_attack_direction(player)
		end_pos = start_pos + direction * ability.range_distance

	end_pos.x = clamp(end_pos.x, 40, 1536 - 40)
	end_pos.y = clamp(end_pos.y, 40, 1382 - 40)

	var tween = create_tween()
	tween.tween_property(player, "global_position", end_pos, 0.15)
	tween.tween_callback(func():
		var enemies = _get_enemies_in_arc(end_pos, direction, 80, PI * 0.6)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)
			_apply_knockback_to_enemy(enemy, direction, ability.knockback_force)
		if enemies.size() > 0:
			_impact_pause()
	)

	_spawn_effect("dash_strike", start_pos)
	_play_sound("dash")

# ============================================
# MELEE ABILITIES - RARE
# ============================================

func _execute_whirlwind(ability: ActiveAbilityData, player: Node2D) -> void:
	# Create a whirlwind effect that damages over time
	var effect = _spawn_effect("whirlwind", player.global_position, player)
	if effect and effect.has_method("setup"):
		effect.setup(ability.duration, ability.radius, _get_damage(ability), ability.damage_multiplier)
	else:
		# Fallback: manual tick damage
		_start_periodic_damage(player, ability)

	_play_sound("whirlwind")

func _execute_seismic_slam(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)

	# Aim shockwave TOWARDS nearest enemy (extended search range)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance * 2.25)
	var direction: Vector2

	if target:
		direction = (target.global_position - player.global_position).normalized()
	else:
		direction = _get_attack_direction(player)

	# Shockwave travels forward
	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.range_distance, PI * 0.4)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun_to_enemy(enemy, ability.stun_duration)

	_spawn_effect("seismic_slam", player.global_position + direction * 50)
	_play_sound("ground_slam")
	_screen_shake("large")
	_impact_pause()

func _execute_savage_leap(ability: ActiveAbilityData, player: Node2D) -> void:
	# Leap to enemy cluster
	var target_pos = _get_enemy_cluster_center(player.global_position, ability.range_distance)

	# Clamp to arena
	target_pos.x = clamp(target_pos.x, 40, 1536 - 40)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	# Create leap tween
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.3).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		# Deal damage on landing
		var damage = _get_damage(ability)
		var enemies = _get_enemies_in_radius(target_pos, ability.radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)
		_spawn_effect("savage_leap_landing", target_pos)
		_screen_shake("medium")
		_impact_pause()
	)

	_play_sound("leap")

func _execute_blade_rush(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var start_pos = player.global_position

	# Dash TOWARDS nearest enemy (extended search range)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance * 2.25)
	var direction: Vector2
	var end_pos: Vector2

	if target:
		direction = (target.global_position - player.global_position).normalized()
		# Dash through the enemy and beyond
		end_pos = start_pos + direction * ability.range_distance
	else:
		# No enemy, dash in attack direction
		direction = _get_attack_direction(player)
		end_pos = start_pos + direction * ability.range_distance

	# Clamp end position to arena
	end_pos.x = clamp(end_pos.x, 40, 1536 - 40)
	end_pos.y = clamp(end_pos.y, 40, 1382 - 40)

	# Dash through enemies
	var tween = create_tween()
	tween.tween_property(player, "global_position", end_pos, 0.2)
	tween.tween_callback(func():
		# Hit all enemies along the path
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy):
				# Check if enemy was near the path
				var closest_point = _closest_point_on_line(start_pos, end_pos, enemy.global_position)
				if closest_point.distance_to(enemy.global_position) < 50:
					_deal_damage_to_enemy(enemy, damage)
	)

	_spawn_effect("blade_rush", start_pos)
	_play_sound("dash")

func _closest_point_on_line(a: Vector2, b: Vector2, p: Vector2) -> Vector2:
	var ab = b - a
	var t = clamp((p - a).dot(ab) / ab.dot(ab), 0.0, 1.0)
	return a + ab * t

func _execute_battle_cry(ability: ActiveAbilityData, player: Node2D) -> void:
	# Buff player with damage boost
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(1.3, ability.duration)  # +30% damage

	# Frighten nearby weak enemies (slow them)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
	for enemy in enemies:
		_apply_slow_to_enemy(enemy, 0.5, 2.0)

	_spawn_effect("battle_cry", player.global_position)
	_play_sound("swing")
	_screen_shake("small")

# ============================================
# MELEE ABILITIES - LEGENDARY
# ============================================

func _execute_earthquake(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)

	# Damage ALL enemies on screen
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			_deal_damage_to_enemy(enemy, damage)
			_apply_stun_to_enemy(enemy, ability.stun_duration)

	_spawn_effect("earthquake", player.global_position)
	_play_sound("earthquake")
	_screen_shake("large")
	_impact_pause()

	# Continuing ground cracks damage
	_start_periodic_damage(player, ability, true)

func _execute_bladestorm(ability: ActiveAbilityData, player: Node2D) -> void:
	# Similar to whirlwind but more powerful
	var effect = _spawn_effect("bladestorm", player.global_position, player)
	if effect and effect.has_method("setup"):
		effect.setup(ability.duration, ability.radius, _get_damage(ability), ability.damage_multiplier)
	else:
		_start_periodic_damage(player, ability)

	_play_sound("bladestorm")

func _execute_omnislash(ability: ActiveAbilityData, player: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_enemies = []

	for enemy in enemies:
		if is_instance_valid(enemy):
			if player.global_position.distance_to(enemy.global_position) <= ability.range_distance:
				valid_enemies.append(enemy)

	if valid_enemies.is_empty():
		return

	# Make player invulnerable during omnislash
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true)

	var damage_per_hit = _get_damage(ability) / 12.0  # 12 hits total
	var hit_count = 0
	var slash_delay = ability.invulnerability_duration / 12.0

	# Perform slashes
	for i in range(12):
		var delay = slash_delay * i
		get_tree().create_timer(delay).timeout.connect(func():
			if valid_enemies.is_empty():
				return
			var target = valid_enemies[hit_count % valid_enemies.size()]
			if is_instance_valid(target):
				player.global_position = target.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
				_deal_damage_to_enemy(target, damage_per_hit)
				_spawn_effect("slash", target.global_position)
			hit_count += 1
		)

	# End invulnerability after all slashes
	get_tree().create_timer(ability.invulnerability_duration).timeout.connect(func():
		if player.has_method("set_invulnerable"):
			player.set_invulnerable(false)
	)

	_play_sound("omnislash")

func _execute_avatar_of_war(ability: ActiveAbilityData, player: Node2D) -> void:
	# Transform: +50% damage, -30% damage taken
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(1.5, ability.duration)

	# Visual effect - make player glow red
	if player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		sprite.modulate = Color(1.5, 0.8, 0.8)
		get_tree().create_timer(ability.duration).timeout.connect(func():
			if is_instance_valid(sprite):
				sprite.modulate = Color.WHITE
		)

	_spawn_effect("avatar_of_war", player.global_position, player)
	_play_sound("buff")
	_screen_shake("medium")

func _execute_divine_shield(ability: ActiveAbilityData, player: Node2D) -> void:
	# Make player invulnerable
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true)

	# End after duration
	get_tree().create_timer(ability.invulnerability_duration).timeout.connect(func():
		if player.has_method("set_invulnerable"):
			player.set_invulnerable(false)
	)

	_spawn_effect("divine_shield", player.global_position, player)
	_play_sound("buff")

# ============================================
# RANGED ABILITIES - COMMON
# ============================================

func _execute_power_shot(ability: ActiveAbilityData, player: Node2D) -> void:
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if not target:
		return

	var direction = (target.global_position - player.global_position).normalized()
	_spawn_projectile("power_shot", player.global_position, direction, ability)

	_play_sound("arrow")

func _execute_explosive_arrow(ability: ActiveAbilityData, player: Node2D) -> void:
	var target = _get_nearest_enemy(player.global_position)
	if not target:
		return

	var direction = (target.global_position - player.global_position).normalized()
	_spawn_projectile("explosive_arrow", player.global_position, direction, ability)

	_play_sound("arrow")

func _execute_multi_shot(ability: ActiveAbilityData, player: Node2D) -> void:
	var direction = _get_attack_direction(player)
	var spread = PI / 4  # 45 degree total spread

	for i in range(ability.projectile_count):
		var angle_offset = -spread / 2 + spread * (i / float(ability.projectile_count - 1)) if ability.projectile_count > 1 else 0
		var proj_dir = direction.rotated(angle_offset)
		_spawn_projectile("multi_shot", player.global_position, proj_dir, ability)

	_play_sound("arrow")

func _execute_quick_roll(ability: ActiveAbilityData, player: Node2D) -> void:
	# Similar to dodge but uses ability direction
	var direction = _get_attack_direction(player)

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true)

	var target_pos = player.global_position + direction * ability.range_distance
	target_pos.x = clamp(target_pos.x, 40, 1536 - 40)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.15)
	tween.tween_callback(func():
		if player.has_method("set_invulnerable"):
			player.set_invulnerable(false)
	)

	_play_sound("dodge")

func _execute_throw_net(ability: ActiveAbilityData, player: Node2D) -> void:
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if not target:
		# Target cluster center if no single target
		var cluster_center = _get_enemy_cluster_center(player.global_position, ability.range_distance)
		_spawn_net_at(cluster_center, ability)
	else:
		_spawn_net_at(target.global_position, ability)

	_play_sound("throw")

func _spawn_net_at(position: Vector2, ability: ActiveAbilityData) -> void:
	# Net roots/slows enemies in area
	var enemies = _get_enemies_in_radius(position, ability.radius)

	for enemy in enemies:
		_apply_slow_to_enemy(enemy, ability.slow_percent, ability.slow_duration)

	_spawn_effect("throw_net", position)

# ============================================
# RANGED ABILITIES - RARE
# ============================================

func _execute_rain_of_arrows(ability: ActiveAbilityData, player: Node2D) -> void:
	var target_pos = _get_enemy_cluster_center(player.global_position, 400.0)

	# Delay for cast time
	get_tree().create_timer(ability.cast_time).timeout.connect(func():
		var damage = _get_damage(ability)
		var effect = _spawn_effect("rain_of_arrows", target_pos)
		if effect and effect.has_method("setup"):
			effect.setup(ability.duration, ability.radius, damage)
		else:
			# Manual periodic damage
			var ticks = int(ability.duration / 0.3)
			for i in range(ticks):
				get_tree().create_timer(0.3 * i).timeout.connect(func():
					var enemies = _get_enemies_in_radius(target_pos, ability.radius)
					for enemy in enemies:
						_deal_damage_to_enemy(enemy, damage / ticks)
				)
	)

	_play_sound("arrow")

func _execute_piercing_volley(ability: ActiveAbilityData, player: Node2D) -> void:
	var direction = _get_attack_direction(player)

	for i in range(ability.projectile_count):
		var offset = Vector2(0, (i - 1) * 20).rotated(direction.angle())
		var start_pos = player.global_position + offset
		_spawn_projectile("piercing_volley", start_pos, direction, ability, true)

	_play_sound("arrow")

func _execute_cluster_bomb(ability: ActiveAbilityData, player: Node2D) -> void:
	var target_pos = _get_enemy_cluster_center(player.global_position, 300.0)
	_spawn_projectile("cluster_bomb", player.global_position, (target_pos - player.global_position).normalized(), ability)

	_play_sound("throw")

func _execute_fan_of_knives(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var angle_step = TAU / ability.projectile_count

	for i in range(ability.projectile_count):
		var direction = Vector2.RIGHT.rotated(angle_step * i)
		_spawn_projectile("fan_of_knives", player.global_position, direction, ability)

	_play_sound("throw")

func _execute_sentry_turret(ability: ActiveAbilityData, player: Node2D) -> void:
	# Spawn a single turret at player position
	var turret_pos = player.global_position
	turret_pos.x = clamp(turret_pos.x, 40, 1536 - 40)
	turret_pos.y = clamp(turret_pos.y, 40, 1382 - 40)

	var turret = _spawn_effect("sentry_turret", turret_pos)
	if turret and turret.has_method("setup"):
		turret.setup(ability.duration, _get_damage(ability))
	else:
		# Fallback: manually implement turret shooting
		_start_turret_shooting(turret_pos, ability)

	_play_sound("deploy")

func _start_turret_shooting(position: Vector2, ability: ActiveAbilityData) -> void:
	"""Manual turret shooting if effect doesn't have setup."""
	var shoot_interval = 0.5
	var shots = int(ability.duration / shoot_interval)
	var damage = _get_damage(ability)

	for i in range(shots):
		get_tree().create_timer(shoot_interval * i).timeout.connect(func():
			var target = _get_nearest_enemy(position, 300.0)
			if target and is_instance_valid(target):
				_deal_damage_to_enemy(target, damage / shots)
				_spawn_effect("turret_shot", position)
		)

# ============================================
# RANGED ABILITIES - LEGENDARY
# ============================================

func _execute_arrow_storm(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)

	# Spawn continuous arrows everywhere for duration
	var effect = _spawn_effect("arrow_storm", player.global_position)
	if effect and effect.has_method("setup"):
		effect.setup(ability.duration, ability.radius, damage)
	else:
		# Manual: spawn arrows at random positions
		var arrow_count = int(ability.duration * 20)  # ~20 arrows per second
		for i in range(arrow_count):
			get_tree().create_timer(ability.duration * i / arrow_count).timeout.connect(func():
				var random_pos = player.global_position + Vector2(randf_range(-ability.radius, ability.radius), randf_range(-ability.radius, ability.radius))
				var enemies = _get_enemies_in_radius(random_pos, 30)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage / 10.0)
			)

	_play_sound("arrow_storm")
	_screen_shake("medium")

func _execute_ballista_strike(ability: ActiveAbilityData, player: Node2D) -> void:
	var target = _get_nearest_enemy(player.global_position)
	if not target:
		return

	var direction = (target.global_position - player.global_position).normalized()
	_spawn_projectile("ballista_strike", player.global_position, direction, ability, true)

	_play_sound("ballista")
	_screen_shake("medium")

func _execute_sentry_network(ability: ActiveAbilityData, player: Node2D) -> void:
	# Spawn 3 turrets around the player
	var turret_positions = [
		player.global_position + Vector2(-80, 0),
		player.global_position + Vector2(80, 0),
		player.global_position + Vector2(0, -80)
	]

	for pos in turret_positions:
		pos.x = clamp(pos.x, 40, 1536 - 40)
		pos.y = clamp(pos.y, 40, 1382 - 40)
		var turret = _spawn_effect("sentry_turret", pos)
		if turret and turret.has_method("setup"):
			turret.setup(ability.duration, _get_damage(ability))

	_play_sound("deploy")

func _execute_rain_of_vengeance(ability: ActiveAbilityData, player: Node2D) -> void:
	# Massive arrow storm covering most of the screen
	var damage = _get_damage(ability)

	# Create waves of arrows raining down
	var waves = 10
	var arrows_per_wave = 15

	for wave in range(waves):
		get_tree().create_timer(ability.duration * wave / waves).timeout.connect(func():
			for i in range(arrows_per_wave):
				# Random position in wide area around player
				var random_offset = Vector2(
					randf_range(-ability.radius, ability.radius),
					randf_range(-ability.radius, ability.radius)
				)
				var arrow_pos = player.global_position + random_offset

				# Clamp to screen
				arrow_pos.x = clamp(arrow_pos.x, 40, 1536 - 40)
				arrow_pos.y = clamp(arrow_pos.y, 40, 1382 - 40)

				# Hit enemies at this position
				var enemies = _get_enemies_in_radius(arrow_pos, 40)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage / (waves * 2))

				# Spawn arrow impact effect
				_spawn_effect("arrow_impact", arrow_pos)
		)

	_play_sound("arrow_storm")
	_screen_shake("medium")

func _execute_explosive_decoy(ability: ActiveAbilityData, player: Node2D) -> void:
	# Spawn a decoy that attracts enemies then explodes
	var decoy_pos = player.global_position

	# Spawn decoy visual
	var decoy = _spawn_effect("explosive_decoy", decoy_pos)

	# Make player briefly invisible/stealthed
	if player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		sprite.modulate.a = 0.3

		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(sprite):
				sprite.modulate.a = 1.0
		)

	# After delay, decoy explodes
	get_tree().create_timer(ability.duration).timeout.connect(func():
		var damage = _get_damage(ability)
		var enemies = _get_enemies_in_radius(decoy_pos, ability.radius)

		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)

		_spawn_effect("explosion", decoy_pos)
		_screen_shake("large")
		_play_sound("explosion")
	)

	_play_sound("deploy")

# ============================================
# GLOBAL ABILITIES - COMMON
# ============================================

func _execute_fireball(ability: ActiveAbilityData, player: Node2D) -> void:
	var target = _get_nearest_enemy(player.global_position)
	if not target:
		return

	var direction = (target.global_position - player.global_position).normalized()
	_spawn_projectile("fireball", player.global_position, direction, ability)

	_play_sound("fireball")

func _execute_frost_nova(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun_to_enemy(enemy, ability.stun_duration)

	_spawn_effect("frost_nova", player.global_position)
	_play_sound("frost")
	_impact_pause()

func _execute_healing_light(ability: ActiveAbilityData, player: Node2D) -> void:
	# Heal over time
	var heal_amount = player.max_health * 0.20  # 20% max HP
	var ticks = int(ability.duration / 0.5)
	var heal_per_tick = heal_amount / ticks

	for i in range(ticks):
		get_tree().create_timer(0.5 * i).timeout.connect(func():
			if is_instance_valid(player) and player.has_method("heal"):
				player.heal(heal_per_tick)
		)

	_spawn_effect("healing_light", player.global_position, player)
	_play_sound("heal")

func _execute_throwing_bomb(ability: ActiveAbilityData, player: Node2D) -> void:
	var target_pos = _get_enemy_cluster_center(player.global_position, 250.0)
	_spawn_projectile("throwing_bomb", player.global_position, (target_pos - player.global_position).normalized(), ability)

	_play_sound("throw")

func _execute_blinding_flash(ability: ActiveAbilityData, player: Node2D) -> void:
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_apply_slow_to_enemy(enemy, ability.slow_percent, ability.slow_duration)

	_spawn_effect("blinding_flash", player.global_position)
	_play_sound("flash")
	_screen_shake("small")

# ============================================
# GLOBAL ABILITIES - RARE
# ============================================

func _execute_chain_lightning(ability: ActiveAbilityData, player: Node2D) -> void:
	var first_target = _get_nearest_enemy(player.global_position)
	if not first_target:
		return

	var damage = _get_damage(ability)
	var chain_count = 5
	var current_target = first_target
	var hit_enemies = [current_target]

	for i in range(chain_count):
		if not is_instance_valid(current_target):
			break

		_deal_damage_to_enemy(current_target, damage * pow(0.8, i))  # 20% reduction per jump
		_spawn_effect("chain_lightning", current_target.global_position)

		# Find next target
		var enemies = get_tree().get_nodes_in_group("enemies")
		var next_target: Node2D = null
		var next_dist = ability.range_distance

		for enemy in enemies:
			if is_instance_valid(enemy) and enemy not in hit_enemies:
				var dist = current_target.global_position.distance_to(enemy.global_position)
				if dist < next_dist:
					next_dist = dist
					next_target = enemy

		if next_target:
			hit_enemies.append(next_target)
			current_target = next_target
		else:
			break

	_play_sound("lightning")

func _execute_meteor_strike(ability: ActiveAbilityData, player: Node2D) -> void:
	var target_pos = _get_enemy_cluster_center(player.global_position, 300.0)

	# Spawn warning indicator
	_spawn_effect("meteor_warning", target_pos)

	# Delay for cast time
	get_tree().create_timer(ability.cast_time).timeout.connect(func():
		var damage = _get_damage(ability)
		var enemies = _get_enemies_in_radius(target_pos, ability.radius)

		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)

		_spawn_effect("meteor_strike", target_pos)
		_screen_shake("large")
		_impact_pause()
	)

	_play_sound("meteor")

func _execute_totem_of_frost(ability: ActiveAbilityData, player: Node2D) -> void:
	var totem = _spawn_effect("totem_of_frost", player.global_position)
	if totem and totem.has_method("setup"):
		totem.setup(ability.duration, ability.radius, _get_damage(ability), ability.slow_percent, ability.slow_duration)

	_play_sound("frost")

func _execute_shadowstep(ability: ActiveAbilityData, player: Node2D) -> void:
	var direction = _get_attack_direction(player)
	var target_pos = player.global_position + direction * ability.range_distance

	target_pos.x = clamp(target_pos.x, 40, 1536 - 40)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	# Instant teleport
	player.global_position = target_pos

	# Apply damage boost buff to player
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(1.5, 3.0)  # 50% damage boost for 3 seconds

	_spawn_effect("shadowstep", target_pos)
	_play_sound("shadowstep")

func _execute_time_slow(ability: ActiveAbilityData, player: Node2D) -> void:
	# Slow all enemies in radius significantly
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_apply_slow_to_enemy(enemy, ability.slow_percent, ability.slow_duration)

	# Visual effect - tint screen/area blue briefly
	_spawn_effect("time_slow", player.global_position)
	_play_sound("time_stop")

# ============================================
# GLOBAL ABILITIES - LEGENDARY
# ============================================

func _execute_black_hole(ability: ActiveAbilityData, player: Node2D) -> void:
	var target_pos = _get_enemy_cluster_center(player.global_position, 300.0)
	var damage = _get_damage(ability)

	var effect = _spawn_effect("black_hole", target_pos)

	# Pull enemies toward center over duration
	var pull_timer = 0.0
	var pull_interval = 0.1
	var pull_force = 200.0

	# Create pulling effect
	var pull_ticks = int(ability.duration / pull_interval)
	for i in range(pull_ticks):
		get_tree().create_timer(pull_interval * i).timeout.connect(func():
			var enemies = _get_enemies_in_radius(target_pos, ability.radius)
			for enemy in enemies:
				if is_instance_valid(enemy):
					var to_center = (target_pos - enemy.global_position).normalized()
					if enemy.has_method("apply_knockback"):
						enemy.apply_knockback(to_center * pull_force * pull_interval)
		)

	# Explode at end
	get_tree().create_timer(ability.duration).timeout.connect(func():
		var enemies = _get_enemies_in_radius(target_pos, ability.radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)
		_spawn_effect("black_hole_explosion", target_pos)
		_screen_shake("large")
	)

	_play_sound("black_hole")

func _execute_time_stop(ability: ActiveAbilityData, player: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if is_instance_valid(enemy):
			_apply_stun_to_enemy(enemy, ability.stun_duration)

	_spawn_effect("time_stop", player.global_position)
	_play_sound("time_stop")

func _execute_thunderstorm(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)

	var effect = _spawn_effect("thunderstorm", player.global_position)

	# Strike random enemies over duration
	var strike_count = int(ability.duration * 5)  # ~5 strikes per second
	for i in range(strike_count):
		get_tree().create_timer(ability.duration * i / strike_count).timeout.connect(func():
			var enemies = get_tree().get_nodes_in_group("enemies")
			if enemies.is_empty():
				return
			var target = enemies[randi() % enemies.size()]
			if is_instance_valid(target):
				_deal_damage_to_enemy(target, damage / 5.0)
				_apply_stun_to_enemy(target, ability.stun_duration)
				_spawn_effect("lightning_strike", target.global_position)
		)

	_play_sound("thunder")
	_screen_shake("medium")

func _execute_summon_golem(ability: ActiveAbilityData, player: Node2D) -> void:
	# Spawn a golem ally that fights for the player
	var golem_pos = player.global_position + Vector2(60, 0)
	golem_pos.x = clamp(golem_pos.x, 40, 1536 - 40)
	golem_pos.y = clamp(golem_pos.y, 40, 1382 - 40)

	var golem = _spawn_effect("summon_golem", golem_pos)
	if golem and golem.has_method("setup"):
		golem.setup(ability.duration, _get_damage(ability))
	else:
		# Fallback: manually implement golem attacking
		_start_golem_attacks(golem_pos, ability, player)

	_spawn_effect("summon_burst", golem_pos)
	_play_sound("summon")
	_screen_shake("small")

func _start_golem_attacks(position: Vector2, ability: ActiveAbilityData, player: Node2D) -> void:
	"""Manual golem AI if effect doesn't have setup."""
	var attack_interval = 1.0
	var attacks = int(ability.duration / attack_interval)
	var damage = _get_damage(ability)
	var golem_pos = position

	for i in range(attacks):
		get_tree().create_timer(attack_interval * i).timeout.connect(func():
			# Golem follows player loosely
			if is_instance_valid(player):
				golem_pos = golem_pos.lerp(player.global_position + Vector2(60, 0), 0.3)

			# Attack nearest enemy
			var target = _get_nearest_enemy(golem_pos, 150.0)
			if target and is_instance_valid(target):
				_deal_damage_to_enemy(target, damage / attacks)
				_spawn_effect("golem_slam", target.global_position)
		)

func _execute_army_of_the_dead(ability: ActiveAbilityData, player: Node2D) -> void:
	# Summon multiple skeleton warriors
	var skeleton_count = 5
	var damage = _get_damage(ability)

	for i in range(skeleton_count):
		var angle = TAU * i / skeleton_count
		var offset = Vector2(cos(angle), sin(angle)) * 80
		var spawn_pos = player.global_position + offset

		spawn_pos.x = clamp(spawn_pos.x, 40, 1536 - 40)
		spawn_pos.y = clamp(spawn_pos.y, 40, 1382 - 40)

		var skeleton = _spawn_effect("skeleton_warrior", spawn_pos)
		if skeleton and skeleton.has_method("setup"):
			skeleton.setup(ability.duration, damage / skeleton_count)
		else:
			# Fallback: manual skeleton attacks
			_start_skeleton_attacks(spawn_pos, ability, player, i)

	_spawn_effect("dark_summon", player.global_position)
	_play_sound("summon")
	_screen_shake("medium")

func _start_skeleton_attacks(position: Vector2, ability: ActiveAbilityData, player: Node2D, index: int) -> void:
	"""Manual skeleton AI if effect doesn't have setup."""
	var attack_interval = 0.8
	var attacks = int(ability.duration / attack_interval)
	var damage = _get_damage(ability) / 5.0  # Split among 5 skeletons
	var skeleton_pos = position

	for i in range(attacks):
		get_tree().create_timer(attack_interval * i + index * 0.1).timeout.connect(func():
			# Find nearest enemy
			var target = _get_nearest_enemy(skeleton_pos, 200.0)
			if target and is_instance_valid(target):
				# Move toward and attack
				skeleton_pos = skeleton_pos.lerp(target.global_position, 0.4)
				_deal_damage_to_enemy(target, damage / attacks)
				_spawn_effect("skeleton_attack", target.global_position)
		)

# ============================================
# PROJECTILE SPAWNING
# ============================================

func _spawn_projectile(type: String, position: Vector2, direction: Vector2, ability: ActiveAbilityData, piercing: bool = false) -> void:
	"""Spawn a projectile for ability effects."""
	var projectile_scene_path = "res://scenes/projectiles/ability_projectile.tscn"
	if not ResourceLoader.exists(projectile_scene_path):
		# Fallback: use arrow scene
		projectile_scene_path = "res://scenes/arrow.tscn"

	var scene = load(projectile_scene_path)
	if not scene:
		return

	var projectile = scene.instantiate()
	projectile.direction = direction

	# Set ability_id BEFORE adding to scene (so _ready can use it for sprite setup)
	if "ability_id" in projectile:
		projectile.ability_id = ability.id

	# Configure projectile based on ability
	if projectile.has_method("setup_from_ability"):
		projectile.setup_from_ability(ability, _get_damage(ability), piercing)
	else:
		# Manual setup for arrow-like projectiles
		if "damage" in projectile:
			projectile.damage = _get_damage(ability)
		if "speed" in projectile:
			projectile.speed = ability.projectile_speed
		if "pierce_count" in projectile and piercing:
			projectile.pierce_count = 99

	projectile.global_position = position
	get_tree().current_scene.add_child(projectile)

# ============================================
# PERIODIC DAMAGE HELPER
# ============================================

func _start_periodic_damage(player: Node2D, ability: ActiveAbilityData, screen_wide: bool = false) -> void:
	"""Start dealing periodic damage around player for ability duration."""
	var damage = _get_damage(ability)
	var tick_interval = 0.2
	var ticks = int(ability.duration / tick_interval)
	var damage_per_tick = damage / ticks

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(player):
				return

			var enemies: Array
			if screen_wide:
				enemies = get_tree().get_nodes_in_group("enemies")
			else:
				enemies = _get_enemies_in_radius(player.global_position, ability.radius)

			for enemy in enemies:
				if is_instance_valid(enemy):
					_deal_damage_to_enemy(enemy, damage_per_tick)
		)
