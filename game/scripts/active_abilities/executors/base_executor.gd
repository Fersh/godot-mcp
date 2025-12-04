extends RefCounted
class_name BaseExecutor

# Base class for ability executors
# Contains shared utility functions used by all ability types

# Reference to the main executor (for accessing scenes, sounds, etc.)
var _main_executor: Node = null

func _init(main_executor: Node = null) -> void:
	_main_executor = main_executor

# ============================================
# DAMAGE CALCULATION
# ============================================

func _get_damage(ability: ActiveAbilityData) -> float:
	"""Calculate ability damage with player modifiers"""
	var player = _get_player()
	if not player:
		return ability.base_damage * ability.damage_multiplier

	var base_damage = ability.base_damage
	var player_damage = player.get_damage() if player.has_method("get_damage") else 10.0

	# Apply multipliers
	var final_damage = base_damage + (player_damage * ability.damage_multiplier)

	# Apply ability manager bonuses
	if AbilityManager:
		final_damage *= AbilityManager.get_active_ability_damage_multiplier()

	return final_damage

func _deal_damage_to_enemy(enemy: Node2D, damage: float, is_crit: bool = false) -> void:
	"""Deal damage to an enemy"""
	if not is_instance_valid(enemy):
		return

	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	# Apply elemental effects if ability has them
	if AbilityManager and AbilityManager.should_apply_elemental_to_active():
		AbilityManager.apply_elemental_effects_to_enemy(enemy)

# ============================================
# TARGETING
# ============================================

func _get_player() -> Node2D:
	"""Get the player node"""
	if _main_executor:
		return _main_executor.get_tree().get_first_node_in_group("player")
	return null

func _get_nearest_enemy(from_pos: Vector2, max_range: float = 999999.0) -> Node2D:
	"""Find the nearest enemy within range"""
	var player = _get_player()
	if not player:
		return null

	var enemies = player.get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist = max_range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = from_pos.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy

	return nearest

func _get_enemies_in_radius(center: Vector2, radius: float) -> Array:
	"""Get all enemies within a radius"""
	var player = _get_player()
	if not player:
		return []

	var enemies = player.get_tree().get_nodes_in_group("enemies")
	var in_range: Array = []

	for enemy in enemies:
		if is_instance_valid(enemy):
			if center.distance_to(enemy.global_position) <= radius:
				in_range.append(enemy)

	return in_range

func _get_enemies_in_arc(center: Vector2, direction: Vector2, radius: float, arc_angle: float) -> Array:
	"""Get all enemies within an arc"""
	var player = _get_player()
	if not player:
		return []

	var enemies = player.get_tree().get_nodes_in_group("enemies")
	var in_arc: Array = []
	var half_angle = arc_angle / 2.0

	for enemy in enemies:
		if is_instance_valid(enemy):
			var to_enemy = enemy.global_position - center
			var dist = to_enemy.length()

			if dist <= radius:
				var angle_to_enemy = direction.angle_to(to_enemy.normalized())
				if abs(angle_to_enemy) <= half_angle:
					in_arc.append(enemy)

	return in_arc

func _get_attack_direction(player: Node2D) -> Vector2:
	"""Get the direction the player is attacking"""
	if player.has_method("get_attack_direction"):
		return player.get_attack_direction()
	elif player.has_method("get_facing"):
		return player.get_facing()
	elif "facing" in player:
		return player.facing
	return Vector2.RIGHT

# ============================================
# EFFECTS AND FEEDBACK
# ============================================

func _spawn_effect(effect_id: String, position: Vector2) -> Node2D:
	"""Spawn a visual effect at position"""
	if _main_executor and _main_executor.has_method("_spawn_effect"):
		return _main_executor._spawn_effect(effect_id, position)
	return null

func _play_sound(sound_id: String) -> void:
	"""Play a sound effect"""
	if _main_executor and _main_executor.has_method("_play_sound"):
		_main_executor._play_sound(sound_id)

func _screen_shake(intensity: String) -> void:
	"""Trigger screen shake"""
	if _main_executor and _main_executor.has_method("_screen_shake"):
		_main_executor._screen_shake(intensity)

func _impact_pause(duration: float = 0.05) -> void:
	"""Brief pause for impact feedback"""
	if _main_executor and _main_executor.has_method("_impact_pause"):
		_main_executor._impact_pause(duration)

# ============================================
# STATUS EFFECTS
# ============================================

func _apply_stun(enemy: Node2D, duration: float) -> void:
	"""Apply stun to enemy"""
	if is_instance_valid(enemy) and enemy.has_method("apply_stun"):
		enemy.apply_stun(duration)

func _apply_slow(enemy: Node2D, percent: float, duration: float) -> void:
	"""Apply slow to enemy"""
	if is_instance_valid(enemy) and enemy.has_method("apply_slow"):
		enemy.apply_slow(percent, duration)

func _apply_knockback(enemy: Node2D, direction: Vector2, force: float) -> void:
	"""Apply knockback to enemy"""
	if is_instance_valid(enemy) and enemy.has_method("apply_knockback"):
		enemy.apply_knockback(direction * force)

func _apply_burn(enemy: Node2D, duration: float = 3.0) -> void:
	"""Apply burn DoT to enemy"""
	if is_instance_valid(enemy) and enemy.has_method("apply_burn"):
		enemy.apply_burn(duration)

# ============================================
# PROJECTILES
# ============================================

func _spawn_projectile(player: Node2D, direction: Vector2, speed: float = 500.0) -> Node2D:
	"""Spawn a projectile from the player"""
	if not player or not player.has_method("spawn_arrow"):
		return null

	if player.arrow_scene:
		var arrow = player.arrow_scene.instantiate()
		arrow.global_position = player.global_position
		arrow.direction = direction
		if "speed" in arrow:
			arrow.speed = speed
		player.get_parent().add_child(arrow)
		return arrow

	return null

# ============================================
# MOVEMENT
# ============================================

func _dash_player(player: Node2D, direction: Vector2, distance: float, duration: float = 0.2) -> void:
	"""Dash the player in a direction"""
	if player.has_method("dash"):
		player.dash(direction, distance, duration)
	elif player.has_method("apply_knockback"):
		player.apply_knockback(direction * distance)
