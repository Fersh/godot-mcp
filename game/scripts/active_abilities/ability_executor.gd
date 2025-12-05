extends Node
class_name AbilityExecutor

# Executes active abilities by delegating to specific ability handlers
# Each ability type has its own execution logic
#
# NEW: Routes to modular executors for tiered ability trees
# Falls back to legacy handlers for existing abilities

# Preloaded effect scenes (lazy loaded)
var _effect_scenes: Dictionary = {}

# Track base scale for gigantamax to prevent infinite scaling
var _gigantamax_base_scales: Dictionary = {}  # player instance_id -> base_scale

# Modular executors for tiered ability trees
var _melee_executor: MeleeExecutor
var _ranged_executor: RangedExecutor
var _global_executor: GlobalExecutor

func _ready() -> void:
	# Initialize modular executors with reference to this main executor
	_melee_executor = MeleeExecutor.new(self)
	_ranged_executor = RangedExecutor.new(self)
	_global_executor = GlobalExecutor.new(self)

func execute(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Main entry point - execute an ability."""
	if not ability or not player:
		return

	# Try modular executors first (for tiered ability trees)
	if _try_modular_executors(ability, player):
		return

	# Fall back to legacy handlers
	_execute_legacy(ability, player)

func _try_modular_executors(ability: ActiveAbilityData, player: Node2D) -> bool:
	"""Try to execute using modular executors. Returns true if handled."""
	# Check if ability is in a registered tree
	if not AbilityTreeRegistry.is_ability_in_tree(ability.id):
		return false

	# Route based on class type
	match ability.class_type:
		ActiveAbilityData.ClassType.MELEE:
			if _melee_executor and _melee_executor.execute(ability, player):
				return true
		ActiveAbilityData.ClassType.RANGED:
			if _ranged_executor and _ranged_executor.execute(ability, player):
				return true
		ActiveAbilityData.ClassType.GLOBAL:
			if _global_executor and _global_executor.execute(ability, player):
				return true

	return false

func _execute_legacy(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Legacy execution path for existing abilities."""
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
		# throw_net merged into frost_nova

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
		"healing_light":
			_execute_healing_light(ability, player)
		"throwing_bomb":
			_execute_throwing_bomb(ability, player)
		"blinding_flash":
			_execute_blinding_flash(ability, player)

		# Global Rare
		"frost_nova":
			_execute_frost_nova(ability, player)
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

		# ==========================================
		# NEW ABILITIES (Zone/Wall, Traps, Stealth, etc.)
		# ==========================================

		# Zone/Wall Abilities
		"flame_wall":
			_execute_flame_wall(ability, player)
		"ice_barricade":
			_execute_ice_barricade(ability, player)
		"floor_is_lava":
			_execute_floor_is_lava(ability, player)

		# Trap Abilities
		"bear_trap":
			_execute_bear_trap(ability, player)
		"glue_bomb":
			_execute_glue_bomb(ability, player)
		"pressure_mine":
			_execute_pressure_mine(ability, player)

		# Stealth Abilities
		"smoke_bomb":
			_execute_smoke_bomb(ability, player)
		"now_you_see_me":
			_execute_now_you_see_me(ability, player)
		"pocket_sand":
			_execute_pocket_sand(ability, player)

		# Crowd Control Abilities
		"terrifying_shout":
			_execute_terrifying_shout(ability, player)
		"demoralizing_shout":
			_execute_demoralizing_shout(ability, player)
		"vortex":
			_execute_vortex(ability, player)
		"repulsive":
			_execute_repulsive(ability, player)
		"dj_drop":
			_execute_dj_drop(ability, player)

		# Chaos/Trick Abilities
		"mirror_clone":
			_execute_mirror_clone(ability, player)
		"uno_reverse":
			_execute_uno_reverse(ability, player)
		"orbital_strike":
			_execute_orbital_strike(ability, player)

		# Summon Abilities
		"summon_party":
			_execute_summon_party(ability, player)
		"release_the_hounds":
			_execute_release_the_hounds(ability, player)

		# Defensive Abilities
		"panic_button":
			_execute_panic_button(ability, player)
		"pocket_healer":
			_execute_pocket_healer(ability, player)
		"safe_space":
			_execute_safe_space(ability, player)

		# Gambling/Transform Abilities
		"double_or_nothing":
			_execute_double_or_nothing(ability, player)
		"gigantamax":
			_execute_gigantamax(ability, player)
		"monster_energy":
			_execute_monster_energy(ability, player)
		"i_see_red":
			_execute_i_see_red(ability, player)

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
	"""Apply damage to an enemy. Mark for flying head effect if this kill them."""
	if enemy.has_method("take_damage"):
		# Mark for ability kill before dealing damage (flying head effect)
		if enemy.has_method("mark_ability_kill"):
			enemy.mark_ability_kill()
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
		if parent:
			parent.add_child(effect)
			effect.position = Vector2.ZERO  # Local position relative to parent
		else:
			get_tree().current_scene.add_child(effect)
			effect.global_position = position
		# Make abilities 90% opacity so game is visible beneath
		effect.modulate.a = 0.9
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
		"cleave":
			return "cleave"
		"slash", "omnislash":
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
		"ice_cast":
			return "ice_cast"

		# Totem effects
		"sentry_turret", "sentry_network":
			return "sentry_turret"
		"totem_of_frost":
			return "frost_totem"

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
		"flame_wall":
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
	explosion.modulate.a = 0.9  # 90% opacity

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
	effect.modulate.a = 0.9  # 90% opacity

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

func _impact_pause(_duration: float = 0.05) -> void:
	"""Trigger a 1-frame pause for impact feel."""
	if JuiceManager:
		JuiceManager.hitstop_micro()

func _impact_pause_large() -> void:
	"""Trigger a longer pause with chromatic pulse for legendary abilities."""
	if JuiceManager:
		JuiceManager.hitstop_medium()
		JuiceManager.chromatic_pulse(0.6)

func _impact_pause_epic() -> void:
	"""Trigger an epic pause with maximum chromatic for ultimate-tier effects."""
	if JuiceManager:
		JuiceManager.hitstop_large()
		JuiceManager.chromatic_pulse(1.0)

# ============================================
# MELEE ABILITIES - COMMON
# ============================================

func _execute_cleave(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)

	# Aim cleave TOWARDS nearest enemy (extended search range)
	var target = _get_nearest_enemy(player.global_position, ability.radius * 2.5)
	var direction: Vector2

	if target:
		direction = (target.global_position - player.global_position).normalized()
	else:
		direction = _get_attack_direction(player)

	# Hit enemies in arc in front of player (wider 153 degree arc)
	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.radius, PI * 0.85)

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
	end_pos.x = clamp(end_pos.x, -60, 1596)
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
	var spin_duration = 0.4

	# Deal damage to all enemies in radius
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	# Spawn circular slash effect attached to player
	_spawn_spinning_slash_effect(player, ability.radius, spin_duration)

	# Spin the player character
	_spin_player(player, spin_duration)

	_play_sound("swing")
	_screen_shake("small")

func _spawn_spinning_slash_effect(player: Node2D, radius: float, duration: float) -> void:
	# Create a spinning slash visual that follows the player
	var effect = Node2D.new()
	effect.name = "SpinningSlashEffect"
	player.add_child(effect)

	# Create the slash sprite
	var sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(radius / 40.0, radius / 40.0)  # Scale based on radius
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(50, 0)  # Offset from center
	effect.add_child(sprite)

	# Setup frames from slash sprite sheet
	var frames = SpriteFrames.new()
	# SpriteFrames.new() already creates "default" animation, just configure it
	frames.set_animation_speed("default", 20.0)
	frames.set_animation_loop("default", true)

	var source_path = "res://assets/sprites/effects/slash/SlashFX Combo1 sheet.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var height = img.get_height()
			var frame_count = 6
			var frame_width = total_width / frame_count

			for i in range(frame_count):
				var frame_img = Image.create(frame_width, height, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_width, 0, frame_width, height), Vector2i.ZERO)
				frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.play("default")

	# Spin the effect around the player
	var tween = effect.create_tween()
	tween.tween_property(effect, "rotation", TAU * 2, duration)  # Two full rotations
	tween.tween_callback(effect.queue_free)

func _spin_player(player: Node2D, duration: float) -> void:
	# Find the player's sprite and animate it spinning
	var sprite = player.get_node_or_null("Sprite2D")
	if not sprite:
		sprite = player.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return

	# Store original values
	var original_scale_x = abs(sprite.scale.x)
	var original_flip = sprite.flip_h

	# Create smooth spin animation using scale squash to simulate rotation
	var tween = sprite.create_tween()
	var spin_count = 2  # Number of full spins
	var spin_duration = duration / spin_count

	for i in range(spin_count):
		# Each "spin" is a smooth squash-flip-expand cycle
		# Phase 1: Squash to center
		tween.tween_property(sprite, "scale:x", 0.1, spin_duration * 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		# Phase 2: Flip and expand (back facing)
		tween.tween_callback(func(): sprite.flip_h = not sprite.flip_h)
		tween.tween_property(sprite, "scale:x", original_scale_x, spin_duration * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		# Phase 3: Squash again
		tween.tween_property(sprite, "scale:x", 0.1, spin_duration * 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		# Phase 4: Flip back and expand (front facing)
		tween.tween_callback(func(): sprite.flip_h = not sprite.flip_h)
		tween.tween_property(sprite, "scale:x", original_scale_x, spin_duration * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# Restore original state
	tween.tween_callback(func():
		sprite.scale.x = original_scale_x
		sprite.flip_h = original_flip
	)

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

	end_pos.x = clamp(end_pos.x, -60, 1596)
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
	_screen_shake("small")

# ============================================
# MELEE ABILITIES - RARE
# ============================================

func _execute_whirlwind(ability: ActiveAbilityData, player: Node2D) -> void:
	# Create a whirlwind effect that damages over time
	var effect = _spawn_effect("whirlwind", player.global_position, player)
	if effect and effect.has_method("setup"):
		effect.setup(ability.duration, ability.radius, _get_damage(ability), ability.damage_multiplier)

	# Spin the player character for the duration
	_spin_player_continuous(player, ability.duration)

	# Deal periodic damage during whirlwind
	var damage = _get_damage(ability)
	var tick_count = int(ability.duration / 0.25)  # Tick every 0.25s
	for i in range(tick_count):
		var delay = 0.25 * i
		get_tree().create_timer(delay).timeout.connect(func():
			if is_instance_valid(player):
				var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage * 0.25)  # DPS spread over ticks
		)

	_play_sound("whirlwind")
	_screen_shake("small")

func _spin_player_continuous(player: Node2D, duration: float) -> void:
	"""Spin the player character continuously for a duration."""
	if not player:
		return

	# Find the player's sprite
	var sprite = player.get_node_or_null("Sprite2D")
	if not sprite:
		sprite = player.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return

	# Store original values
	var original_scale_x = abs(sprite.scale.x)
	var original_flip = sprite.flip_h

	# Calculate spins - each full spin takes 0.3 seconds for smooth look
	var spin_time = 0.3
	var spin_count = int(duration / spin_time)

	var spin_tween = sprite.create_tween()
	for i in range(spin_count):
		# Smooth squash-flip-expand cycle for each half-spin
		# First half-spin
		spin_tween.tween_property(sprite, "scale:x", 0.1, spin_time * 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		spin_tween.tween_callback(func(): sprite.flip_h = not sprite.flip_h)
		spin_tween.tween_property(sprite, "scale:x", original_scale_x, spin_time * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		# Second half-spin
		spin_tween.tween_property(sprite, "scale:x", 0.1, spin_time * 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		spin_tween.tween_callback(func(): sprite.flip_h = not sprite.flip_h)
		spin_tween.tween_property(sprite, "scale:x", original_scale_x, spin_time * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# Restore original state
	spin_tween.tween_callback(func():
		sprite.scale.x = original_scale_x
		sprite.flip_h = original_flip
	)

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
	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	# Store original scale
	var original_scale = player.scale

	# Create leap tween for position
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

	# Animate player body - scrunch mid-jump then expand on landing
	var jump_tween = create_tween()
	# First half: scrunch vertically (compress body mid-air)
	var scrunch_scale = Vector2(original_scale.x * 1.2, original_scale.y * 0.6)
	jump_tween.tween_property(player, "scale", scrunch_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Second half: expand back and slightly squash on landing
	var land_scale = Vector2(original_scale.x * 1.1, original_scale.y * 0.9)
	jump_tween.tween_property(player, "scale", land_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Return to normal
	jump_tween.tween_property(player, "scale", original_scale, 0.1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

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
	end_pos.x = clamp(end_pos.x, -60, 1596)
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
	_screen_shake("small")

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

	# Start rapid left-right attack animation for the duration
	if player.has_method("start_bladestorm_animation"):
		player.start_bladestorm_animation(ability.duration)

	_play_sound("bladestorm")
	_screen_shake("large")
	_impact_pause_large()  # Legendary juice

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
		player.set_invulnerable(true, ability.invulnerability_duration)

	var damage_per_hit = _get_damage(ability) / 12.0  # 12 hits total
	var slash_delay = ability.invulnerability_duration / 12.0
	var dash_duration = slash_delay * 0.6  # Dash takes 60% of the time, rest is attack

	# Sort enemies by distance for more natural movement
	valid_enemies.sort_custom(func(a, b):
		return player.global_position.distance_to(a.global_position) < player.global_position.distance_to(b.global_position)
	)

	# Perform smooth dashing omnislash
	_omnislash_chain(player, valid_enemies, 0, 12, damage_per_hit, slash_delay, dash_duration, ability)

	_play_sound("omnislash")
	_screen_shake("large")
	_impact_pause()

func _omnislash_chain(player: Node2D, enemies: Array, hit_index: int, total_hits: int, damage: float, delay: float, dash_duration: float, ability: ActiveAbilityData) -> void:
	"""Recursively chain omnislash dashes between enemies."""
	if hit_index >= total_hits or not is_instance_valid(player):
		# End invulnerability after all slashes
		if player.has_method("set_invulnerable"):
			player.set_invulnerable(false)
		return

	if enemies.is_empty():
		if player.has_method("set_invulnerable"):
			player.set_invulnerable(false)
		return

	# Get target enemy (cycle through available enemies)
	var target_index = hit_index % enemies.size()
	var target = enemies[target_index]

	# Skip invalid targets, find next valid one
	while not is_instance_valid(target) and enemies.size() > 0:
		enemies.remove_at(target_index)
		if enemies.is_empty():
			if player.has_method("set_invulnerable"):
				player.set_invulnerable(false)
			return
		target_index = hit_index % enemies.size()
		target = enemies[target_index]

	if not is_instance_valid(target):
		if player.has_method("set_invulnerable"):
			player.set_invulnerable(false)
		return

	# Calculate dash target position (slightly offset from enemy)
	var direction = (target.global_position - player.global_position).normalized()
	var dash_target = target.global_position - direction * 30  # Stop 30 pixels from enemy

	# Spawn dash trail effect (like shadow dance)
	_spawn_omnislash_trail(player)

	# Smooth dash to target using tween
	var tween = player.create_tween()
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", dash_target, dash_duration)

	# On dash complete, deal damage and continue chain
	tween.tween_callback(func():
		if is_instance_valid(target):
			# Update player facing direction
			if "facing_right" in player:
				player.facing_right = target.global_position.x > player.global_position.x
			if "sprite" in player and player.sprite:
				player.sprite.flip_h = target.global_position.x < player.global_position.x

			# Deal damage
			_deal_damage_to_enemy(target, damage)
			_spawn_effect("slash", target.global_position)

			# Small screen shake per hit
			if hit_index % 3 == 0:
				_screen_shake("small")

		# Continue to next slash after a brief pause
		get_tree().create_timer(delay - dash_duration).timeout.connect(func():
			_omnislash_chain(player, enemies, hit_index + 1, total_hits, damage, delay, dash_duration, ability)
		)
	)

func _spawn_omnislash_trail(player: Node2D) -> void:
	"""Spawn a trail effect during omnislash dashes."""
	if not is_instance_valid(player):
		return

	var sprite = player.get_node_or_null("Sprite2D")
	if not sprite:
		return

	# Create multiple ghost images
	var trail_count = 4
	for i in range(trail_count):
		var ghost_delay = i * 0.02
		get_tree().create_timer(ghost_delay).timeout.connect(func():
			if not is_instance_valid(player) or not is_instance_valid(sprite):
				return

			var ghost = Sprite2D.new()
			ghost.texture = sprite.texture
			ghost.hframes = sprite.hframes
			ghost.vframes = sprite.vframes
			ghost.frame = sprite.frame
			ghost.flip_h = sprite.flip_h
			ghost.global_position = player.global_position
			ghost.scale = sprite.scale
			ghost.offset = sprite.offset
			ghost.modulate = Color(1.0, 0.8, 0.3, 0.6)  # Golden trail
			ghost.z_index = player.z_index - 1
			get_tree().current_scene.add_child(ghost)

			# Fade out
			var ghost_tween = ghost.create_tween()
			ghost_tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
			ghost_tween.tween_callback(ghost.queue_free)
		)

func _execute_avatar_of_war(ability: ActiveAbilityData, player: Node2D) -> void:
	# Transform: +50% damage, -30% damage taken
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(1.5, ability.duration)

	# Transform into barbarian visually (except if already barbarian)
	var is_barbarian = false
	if player.get("character_data") and player.character_data.id == "barbarian":
		is_barbarian = true

	if player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")

		if not is_barbarian:
			# Store original sprite configuration
			var original_texture = sprite.texture
			var original_hframes = sprite.hframes
			var original_vframes = sprite.vframes
			var original_scale = sprite.scale
			var original_offset = sprite.offset

			# Load barbarian sprite
			var barbarian_texture = load("res://assets/sprites/characters/barbarian.png")
			if barbarian_texture:
				sprite.texture = barbarian_texture
				sprite.hframes = 8
				sprite.vframes = 6
				sprite.scale = Vector2(1.6, 1.6)
				sprite.offset = Vector2.ZERO

			# Red glow effect
			sprite.modulate = Color(1.5, 0.8, 0.8)

			# Restore original after duration
			get_tree().create_timer(ability.duration).timeout.connect(func():
				if is_instance_valid(sprite):
					sprite.texture = original_texture
					sprite.hframes = original_hframes
					sprite.vframes = original_vframes
					sprite.scale = original_scale
					sprite.offset = original_offset
					sprite.modulate = Color.WHITE
			)
		else:
			# Barbarian just gets glow effect
			sprite.modulate = Color(1.5, 0.8, 0.8)
			get_tree().create_timer(ability.duration).timeout.connect(func():
				if is_instance_valid(sprite):
					sprite.modulate = Color.WHITE
			)

	_spawn_effect("avatar_of_war", player.global_position, player)
	_play_sound("buff")
	_screen_shake("large")
	_impact_pause()

func _execute_divine_shield(ability: ActiveAbilityData, player: Node2D) -> void:
	# Make player invulnerable
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true, ability.invulnerability_duration)

	_spawn_effect("divine_shield", player.global_position, player)
	_play_sound("buff")
	_screen_shake("large")
	_impact_pause()

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
	_screen_shake("small")

func _execute_explosive_arrow(ability: ActiveAbilityData, player: Node2D) -> void:
	var target = _get_nearest_enemy(player.global_position)
	if not target:
		return

	var direction = (target.global_position - player.global_position).normalized()
	_spawn_projectile("explosive_arrow", player.global_position, direction, ability)

	_play_sound("arrow")
	_screen_shake("small")

func _execute_multi_shot(ability: ActiveAbilityData, player: Node2D) -> void:
	var direction = _get_attack_direction(player)
	var spread = PI / 4  # 45 degree total spread

	for i in range(ability.projectile_count):
		var angle_offset = -spread / 2 + spread * (i / float(ability.projectile_count - 1)) if ability.projectile_count > 1 else 0
		var proj_dir = direction.rotated(angle_offset)
		_spawn_projectile("multi_shot", player.global_position, proj_dir, ability)

	_play_sound("arrow")
	_screen_shake("small")

func _execute_quick_roll(ability: ActiveAbilityData, player: Node2D) -> void:
	# Works like dodge - away from nearest enemy if no direction, otherwise in that direction
	var direction = _calculate_dodge_direction(player)

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true)

	var target_pos = player.global_position + direction * ability.range_distance
	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.15)
	tween.tween_callback(func():
		if player.has_method("set_invulnerable"):
			player.set_invulnerable(false)
	)

	_play_sound("dodge")

func _calculate_dodge_direction(player: Node2D) -> Vector2:
	"""Calculate dodge direction - uses player input direction if moving, otherwise away from nearest enemy."""
	if not player:
		return Vector2.DOWN

	# First priority: Use player's current movement direction if they're moving
	var input_direction = Vector2.ZERO

	# Check joystick direction
	if "joystick_direction" in player and player.joystick_direction.length() > 0.1:
		input_direction = player.joystick_direction.normalized()

	# Check velocity as fallback (if player is actively moving)
	if input_direction.length() < 0.1 and "velocity" in player and player.velocity.length() > 10:
		input_direction = player.velocity.normalized()

	# If player is actively holding a direction, dodge in that direction
	if input_direction.length() > 0.1:
		return input_direction

	# Fallback: Dodge away from nearest enemy when no input is being held
	var enemies = player.get_tree().get_nodes_in_group("enemies")
	var closest_enemy: Node2D = null
	var closest_dist: float = INF

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = enemy

	if closest_enemy:
		# Dodge away from the closest enemy
		return (player.global_position - closest_enemy.global_position).normalized()

	# Final fallback: dodge downward
	return Vector2.DOWN

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
		var ticks = int(ability.duration / 0.3)
		var damage_per_tick = damage / ticks

		# Spawn visual arrows falling throughout the duration
		_spawn_rain_of_arrows_visuals(target_pos, ability.radius, ability.duration, ticks)

		# Deal periodic damage
		for i in range(ticks):
			get_tree().create_timer(0.3 * i).timeout.connect(func():
				var enemies = _get_enemies_in_radius(target_pos, ability.radius)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage_per_tick)
			)
	)

	_play_sound("arrow")

func _spawn_rain_of_arrows_visuals(center: Vector2, radius: float, duration: float, ticks: int) -> void:
	"""Spawn visual arrows falling from sky into the target area."""
	var arrows_per_tick = 4  # Number of arrows per damage tick
	var total_arrows = ticks * arrows_per_tick

	for i in range(total_arrows):
		var delay = (float(i) / total_arrows) * duration
		get_tree().create_timer(delay).timeout.connect(func():
			_spawn_falling_arrow(center, radius)
		)

func _spawn_falling_arrow(center: Vector2, radius: float) -> void:
	"""Spawn a single falling arrow visual."""
	# Random position within radius
	var angle = randf() * TAU
	var dist = randf() * radius
	var land_pos = center + Vector2(cos(angle), sin(angle)) * dist

	# Arrow starts above and falls down at an angle
	var fall_height = 300.0
	var horizontal_offset = randf_range(-50, 50)
	var start_pos = land_pos + Vector2(horizontal_offset, -fall_height)

	# Create arrow visual (similar to player arrow)
	var arrow = Node2D.new()
	arrow.global_position = start_pos
	arrow.z_index = 5

	# Arrow body (white rectangle)
	var body = ColorRect.new()
	body.size = Vector2(18, 3)
	body.position = Vector2(-10, -1.5)
	body.color = Color(0.9, 0.85, 0.7, 1.0)  # Slightly golden tint
	arrow.add_child(body)

	# Arrow tip (dark triangle)
	var tip = Polygon2D.new()
	tip.position = Vector2(8, 0)
	tip.color = Color(0.15, 0.1, 0.1, 1.0)
	tip.polygon = PackedVector2Array([Vector2(0, -2), Vector2(6, 0), Vector2(0, 2)])
	arrow.add_child(tip)

	# Rotate arrow to face landing position
	var direction = (land_pos - start_pos).normalized()
	arrow.rotation = direction.angle()

	get_tree().current_scene.add_child(arrow)

	# Animate falling
	var fall_duration = randf_range(0.15, 0.25)
	var tween = arrow.create_tween()
	tween.tween_property(arrow, "global_position", land_pos, fall_duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		# Small impact effect
		_spawn_arrow_impact(land_pos)
		# Fade out arrow stuck in ground
		var fade_tween = arrow.create_tween()
		fade_tween.tween_interval(0.3)
		fade_tween.tween_property(arrow, "modulate:a", 0.0, 0.2)
		fade_tween.tween_callback(arrow.queue_free)
	)

func _spawn_arrow_impact(position: Vector2) -> void:
	"""Small dust/impact effect when arrow lands."""
	var impact = Node2D.new()
	impact.global_position = position
	impact.z_index = 4
	get_tree().current_scene.add_child(impact)

	# Small dust particles
	for i in range(4):
		var particle = ColorRect.new()
		particle.size = Vector2(3, 3)
		particle.color = Color(0.6, 0.5, 0.4, 0.8)
		particle.position = Vector2(-1.5, -1.5)
		impact.add_child(particle)

		var p_angle = (float(i) / 4) * TAU + randf_range(-0.3, 0.3)
		var end_pos = Vector2(cos(p_angle), sin(p_angle)) * randf_range(8, 15)

		var p_tween = particle.create_tween()
		p_tween.set_parallel(true)
		p_tween.tween_property(particle, "position", end_pos, 0.2).set_ease(Tween.EASE_OUT)
		p_tween.tween_property(particle, "modulate:a", 0.0, 0.15).set_delay(0.05)

	# Clean up
	var cleanup = impact.create_tween()
	cleanup.tween_interval(0.3)
	cleanup.tween_callback(impact.queue_free)

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
	_screen_shake("small")

func _execute_sentry_turret(ability: ActiveAbilityData, player: Node2D) -> void:
	# Spawn a single turret at player position
	var turret_pos = player.global_position
	turret_pos.x = clamp(turret_pos.x, -60, 1596)
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
	var duration = ability.duration
	var radius = ability.radius

	# Spawn raining arrows for the duration
	var arrows_per_second = 15
	var total_arrows = int(duration * arrows_per_second)

	for i in range(total_arrows):
		var delay = duration * float(i) / float(total_arrows)
		get_tree().create_timer(delay).timeout.connect(func():
			if not is_instance_valid(player):
				return
			_spawn_storm_arrow(player.global_position, radius, damage)
		)

	_play_sound("arrow_storm")
	_screen_shake("large")  # Legendary juice
	_impact_pause_large()

func _spawn_storm_arrow(center: Vector2, radius: float, damage: float) -> void:
	# Random target position within radius of player
	var target_pos = center + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))

	# Clamp to arena bounds
	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 50, 1332)

	# Arrow starts from above and falls down at an angle
	var start_offset = Vector2(randf_range(-50, 50), -400)
	var start_pos = target_pos + start_offset

	# Create visual arrow
	var arrow = Node2D.new()
	arrow.global_position = start_pos
	arrow.z_index = 20

	# Arrow body (white rectangle)
	var body = ColorRect.new()
	body.size = Vector2(16, 3)
	body.position = Vector2(-8, -1.5)
	body.color = Color(1.0, 0.95, 0.8, 1.0)
	arrow.add_child(body)

	# Arrow tip (dark triangle)
	var tip = Polygon2D.new()
	tip.position = Vector2(8, 0)
	tip.color = Color(0.2, 0.2, 0.2, 1.0)
	tip.polygon = PackedVector2Array([Vector2(0, -2), Vector2(5, 0), Vector2(0, 2)])
	arrow.add_child(tip)

	# Rotate arrow to face direction of travel
	var direction = (target_pos - start_pos).normalized()
	arrow.rotation = direction.angle()

	var main_node = get_tree().current_scene
	if main_node:
		main_node.add_child(arrow)

	# Animate arrow falling to target
	var tween = arrow.create_tween()
	tween.tween_property(arrow, "global_position", target_pos, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		# Deal damage at impact point
		var enemies = _get_enemies_in_radius(target_pos, 35)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)

		# Spawn impact effect
		_spawn_arrow_impact(target_pos)

		arrow.queue_free()
	)

func _execute_ballista_strike(ability: ActiveAbilityData, player: Node2D) -> void:
	var target = _get_nearest_enemy(player.global_position)
	if not target:
		return

	var direction = (target.global_position - player.global_position).normalized()
	_spawn_projectile("ballista_strike", player.global_position, direction, ability, true)

	_play_sound("ballista")
	_screen_shake("medium")
	_impact_pause()

func _execute_sentry_network(ability: ActiveAbilityData, player: Node2D) -> void:
	# Spawn 3 turrets around the player
	var turret_positions = [
		player.global_position + Vector2(-80, 0),
		player.global_position + Vector2(80, 0),
		player.global_position + Vector2(0, -80)
	]

	for pos in turret_positions:
		pos.x = clamp(pos.x, -60, 1596)
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
				arrow_pos.x = clamp(arrow_pos.x, -60, 1596)
				arrow_pos.y = clamp(arrow_pos.y, 40, 1382 - 40)

				# Spawn falling arrow visual
				_spawn_barrage_arrow(arrow_pos, damage / (waves * 2), ability.radius)
		)

	_play_sound("arrow_storm")
	_screen_shake("large")  # Legendary juice
	_impact_pause_large()

func _spawn_barrage_arrow(target_pos: Vector2, damage: float, _radius: float) -> void:
	"""Spawn a visual arrow that falls from above and impacts at target position."""
	# Create arrow visual
	var arrow = Node2D.new()
	arrow.name = "FallingArrow"

	# Arrow shaft (white rectangle)
	var shaft = ColorRect.new()
	shaft.size = Vector2(18, 3)
	shaft.position = Vector2(-10, -1.5)
	shaft.color = Color(0.9, 0.85, 0.7)  # Slightly off-white
	arrow.add_child(shaft)

	# Arrow tip (dark triangle)
	var tip = Polygon2D.new()
	tip.position = Vector2(8, 0)
	tip.color = Color(0.2, 0.2, 0.2)
	tip.polygon = PackedVector2Array([Vector2(0, -2), Vector2(6, 0), Vector2(0, 2)])
	arrow.add_child(tip)

	# Start position (above target, off-screen or high up)
	var start_y = target_pos.y - randf_range(300, 500)
	var start_x = target_pos.x + randf_range(-30, 30)  # Slight horizontal offset
	arrow.global_position = Vector2(start_x, start_y)

	# Rotate arrow to point downward (towards target)
	var direction = (target_pos - arrow.global_position).normalized()
	arrow.rotation = direction.angle()

	get_tree().current_scene.add_child(arrow)

	# Animate arrow falling
	var fall_duration = randf_range(0.15, 0.25)  # Fast fall
	var tween = arrow.create_tween()
	tween.tween_property(arrow, "global_position", target_pos, fall_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# On impact: deal damage, spawn effect, remove arrow
	tween.tween_callback(func():
		# Hit enemies at this position
		var enemies = _get_enemies_in_radius(target_pos, 40)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)

		# Spawn impact effect
		_spawn_effect("arrow_impact", target_pos)

		# Remove arrow
		arrow.queue_free()
	)

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
		_impact_pause()
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
	_screen_shake("small")

func _execute_frost_nova(ability: ActiveAbilityData, player: Node2D) -> void:
	# Upgraded to Rare - now freezes then slows
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun_to_enemy(enemy, ability.stun_duration)
		# Apply slow after stun ends
		if ability.slow_percent > 0 and ability.slow_duration > 0:
			var tree = player.get_tree() if is_instance_valid(player) else null
			if tree:
				tree.create_timer(ability.stun_duration).timeout.connect(func():
					if is_instance_valid(enemy) and enemy.has_method("apply_slow"):
						enemy.apply_slow(ability.slow_percent, ability.slow_duration)
				)

	_spawn_effect("frost_nova", player.global_position)
	_play_sound("frost")
	_screen_shake("medium")
	_impact_pause_large()

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
	_impact_pause()

# ============================================
# GLOBAL ABILITIES - RARE
# ============================================

func _execute_chain_lightning(ability: ActiveAbilityData, player: Node2D) -> void:
	var first_target = _get_nearest_enemy(player.global_position)
	if not first_target:
		return

	var damage = _get_damage(ability)
	var chain_count = 5
	# Apply Conductor bonus for extra chains
	if AbilityManager:
		chain_count += AbilityManager.get_lightning_chain_count()
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
	_screen_shake("small")
	_impact_pause()

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
	var start_pos = player.global_position

	# Find nearest enemy to teleport to
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	var target_pos: Vector2

	if target:
		# Teleport behind the enemy (slightly offset from their position)
		var dir_to_player = (player.global_position - target.global_position).normalized()
		target_pos = target.global_position + dir_to_player * 50  # 50px behind enemy
	else:
		# No enemy in range, teleport in attack direction
		var direction = _get_attack_direction(player)
		target_pos = player.global_position + direction * ability.range_distance

	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	# Spawn effect at start position
	_spawn_effect("shadowstep", start_pos)

	# Instant teleport
	player.global_position = target_pos

	# Spawn effect at end position too
	_spawn_effect("shadowstep", target_pos)

	# Apply damage boost buff to player
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(1.5, 3.0)  # 50% damage boost for 3 seconds

	_play_sound("shadowstep")
	_screen_shake("small")

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

	# Explode at end with epic juice
	get_tree().create_timer(ability.duration).timeout.connect(func():
		var enemies = _get_enemies_in_radius(target_pos, ability.radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)
		_spawn_effect("black_hole_explosion", target_pos)
		_screen_shake("large")
		_impact_pause_epic()  # Legendary explosion
	)

	_play_sound("black_hole")
	_screen_shake("medium")  # Initial activation shake
	_impact_pause_large()

func _execute_time_stop(ability: ActiveAbilityData, player: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if is_instance_valid(enemy):
			_apply_stun_to_enemy(enemy, ability.stun_duration)

	_spawn_effect("time_stop", player.global_position)
	_play_sound("time_stop")
	_screen_shake("large")
	_impact_pause_epic()  # Legendary - time stop needs epic feel

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
	_screen_shake("large")
	_impact_pause()

func _execute_summon_golem(ability: ActiveAbilityData, player: Node2D) -> void:
	# Spawn a golem ally that fights for the player
	var golem_pos = player.global_position + Vector2(60, 0)
	golem_pos.x = clamp(golem_pos.x, -60, 1596)
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

		spawn_pos.x = clamp(spawn_pos.x, -60, 1596)
		spawn_pos.y = clamp(spawn_pos.y, 40, 1382 - 40)

		var skeleton = _spawn_effect("skeleton_warrior", spawn_pos)
		if skeleton and skeleton.has_method("setup"):
			skeleton.setup(ability.duration, damage / skeleton_count)
		else:
			# Fallback: manual skeleton attacks
			_start_skeleton_attacks(spawn_pos, ability, player, i)

	_spawn_effect("dark_summon", player.global_position)
	_play_sound("summon")
	_screen_shake("large")  # Legendary juice
	_impact_pause_large()

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

# ============================================
# NEW ABILITIES - ZONE/WALL
# ============================================

func _execute_flame_wall(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Create a wall of fire that damages and burns enemies passing through."""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var wall_length = 350.0  # Much wider wall
	var wall_width = 120.0   # Much wider hit area

	# Burn parameters
	var burn_duration = 3.0
	var burn_damage = damage * 0.5  # Burn deals 50% of hit damage over duration

	# Calculate wall center position in front of player
	var wall_center = player.global_position + direction * 100

	# Create wall visual
	var wall = Node2D.new()
	wall.name = "FlameWall"
	wall.global_position = wall_center
	wall.rotation = direction.angle()
	wall.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(wall)

	# Visual representation - animated fire sprites along the wall
	var fire_count = 9  # More fire sprites for wider wall
	for i in range(fire_count):
		var offset = (i - fire_count / 2.0) * (wall_length / fire_count)
		var fire = _create_fire_sprite()
		fire.position = Vector2(offset, 0)
		wall.add_child(fire)

	# Track enemies that have been burned to avoid repeated burn application
	var burned_enemies: Dictionary = {}

	# Deal damage over duration
	var tick_interval = 0.3
	var ticks = int(ability.duration / tick_interval)
	var damage_per_tick = damage / ticks

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(wall):
				return
			# Check enemies intersecting the wall area
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				if is_instance_valid(enemy):
					# Check if enemy is near the wall line
					var local_pos = wall.to_local(enemy.global_position)
					if abs(local_pos.x) < wall_length / 2 and abs(local_pos.y) < wall_width / 2:
						_deal_damage_to_enemy(enemy, damage_per_tick)

						# Apply burn effect (only once per enemy per wall instance)
						var enemy_id = enemy.get_instance_id()
						if not burned_enemies.has(enemy_id):
							burned_enemies[enemy_id] = true
							if enemy.has_method("apply_burn"):
								enemy.apply_burn(burn_duration, burn_damage)
							elif enemy.has_method("apply_dot"):
								enemy.apply_dot(burn_damage, burn_duration, "burn")
		)

	# Remove wall after duration
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(wall):
			wall.queue_free()
	)

	_play_sound("fireball")
	_screen_shake("small")

func _create_fire_sprite() -> Node2D:
	"""Create an animated fire sprite for flame wall."""
	var fire = Node2D.new()

	# Create animated sprite
	var sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(1.5, 1.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames = SpriteFrames.new()
	frames.set_animation_speed("default", 15.0)
	frames.set_animation_loop("default", true)

	# Load individual fire frames from firefx001
	var base_path = "res://assets/sprites/effects/35/firefx/firefx001/"
	var loaded_frames = 0
	for i in range(10, 24):  # fire_fx_00110 to fire_fx_00123
		var frame_path = base_path + "fire_fx_001%d.png" % i
		if ResourceLoader.exists(frame_path):
			var texture = load(frame_path)
			if texture:
				frames.add_frame("default", texture)
				loaded_frames += 1

	# Fallback: draw procedural fire if no frames loaded
	if loaded_frames == 0:
		var placeholder = PlaceholderTexture2D.new()
		placeholder.size = Vector2(32, 48)
		frames.add_frame("default", placeholder)
		sprite.modulate = Color(1.0, 0.5, 0.1, 0.8)  # Orange tint

	sprite.sprite_frames = frames
	sprite.play("default")
	fire.add_child(sprite)

	return fire

func _execute_ice_barricade(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Create an ice wall that blocks and slows enemies."""
	var direction = _get_attack_direction(player)
	var wall_length = 180.0

	# Calculate wall center position in front of player
	var wall_center = player.global_position + direction * 80

	# Create wall visual
	var wall = Node2D.new()
	wall.name = "IceBarricade"
	wall.global_position = wall_center
	wall.rotation = direction.angle() + PI / 2  # Perpendicular to direction
	wall.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(wall)

	# Visual representation - ice blocks along the wall
	var block_count = 5
	for i in range(block_count):
		var offset = (i - block_count / 2.0) * (wall_length / block_count)
		var block = ColorRect.new()
		block.size = Vector2(30, 50)
		block.position = Vector2(offset - 15, -25)
		block.color = Color(0.7, 0.9, 1.0, 0.8)
		wall.add_child(block)

	# Slow enemies that touch the wall
	var tick_interval = 0.5
	var ticks = int(ability.duration / tick_interval)

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(wall):
				return
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				if is_instance_valid(enemy):
					var local_pos = wall.to_local(enemy.global_position)
					if abs(local_pos.x) < wall_length / 2 and abs(local_pos.y) < 40:
						_apply_slow_to_enemy(enemy, ability.slow_percent, ability.slow_duration)
						# Push enemy back slightly
						var push_dir = (enemy.global_position - wall_center).normalized()
						_apply_knockback_to_enemy(enemy, push_dir, 50.0)
		)

	# Remove wall after duration with shatter effect
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(wall):
			_spawn_effect("ice_shatter", wall.global_position)
			wall.queue_free()
	)

	_spawn_effect("ice_cast", wall_center)
	_play_sound("frost")
	_screen_shake("small")

func _execute_floor_is_lava(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Leave a trail of lava behind you that damages enemies."""
	var damage = _get_damage(ability)
	var trail_duration = ability.duration
	var lava_pools: Array[Node2D] = []

	# Create lava pools at intervals behind player
	var spawn_interval = 0.2
	var spawns = int(trail_duration / spawn_interval)
	# Each pool deals full damage over its lifetime (not divided by spawn count)
	var pool_damage = damage * 0.5  # Each pool deals 50% of ability damage

	for i in range(spawns):
		get_tree().create_timer(spawn_interval * i).timeout.connect(func():
			if not is_instance_valid(player):
				return

			# Create lava pool at current player position
			var pool = _create_lava_pool(player.global_position, pool_damage, 3.0)
			lava_pools.append(pool)
		)

	_play_sound("fireball")

func _create_lava_pool(position: Vector2, damage: float, lifetime: float) -> Node2D:
	"""Create a single lava pool that damages enemies."""
	var pool = Node2D.new()
	pool.name = "LavaPool"
	pool.global_position = position
	pool.z_index = -1
	pool.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(pool)

	# Visual - orange/red circle
	var visual = Polygon2D.new()
	var radius = 35.0
	var points: PackedVector2Array = []
	for i in range(16):
		var angle = TAU * i / 16
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	visual.polygon = points
	visual.color = Color(1.0, 0.3, 0.0, 0.7)
	pool.add_child(visual)

	# Inner glow
	var inner = Polygon2D.new()
	var inner_points: PackedVector2Array = []
	for i in range(16):
		var angle = TAU * i / 16
		inner_points.append(Vector2(cos(angle), sin(angle)) * (radius * 0.6))
	inner.polygon = inner_points
	inner.color = Color(1.0, 0.7, 0.0, 0.8)
	pool.add_child(inner)

	# Damage enemies standing in pool
	var tick_interval = 0.3
	var ticks = int(lifetime / tick_interval)
	var damage_per_tick = damage / ticks

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(pool):
				return
			var enemies = _get_enemies_in_radius(pool.global_position, radius)
			for enemy in enemies:
				_deal_damage_to_enemy(enemy, damage_per_tick)
				# Apply burn effect (it's lava!)
				if enemy.has_method("apply_burn"):
					enemy.apply_burn(1.5, damage_per_tick * 0.5)
		)

	# Fade out and remove
	get_tree().create_timer(lifetime - 0.5).timeout.connect(func():
		if is_instance_valid(pool):
			var tween = pool.create_tween()
			tween.tween_property(pool, "modulate:a", 0.0, 0.5)
			tween.tween_callback(pool.queue_free)
	)

	return pool

# ============================================
# NEW ABILITIES - TRAPS
# ============================================

func _execute_bear_trap(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Place a hidden trap that immobilizes enemies."""
	var damage = _get_damage(ability)
	var trap_pos = player.global_position

	# Create trap visual
	var trap = Node2D.new()
	trap.name = "BearTrap"
	trap.global_position = trap_pos
	trap.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(trap)

	# Visual - metal trap jaws
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-20, -5), Vector2(20, -5), Vector2(15, 5), Vector2(-15, 5)
	])
	base.color = Color(0.4, 0.4, 0.4, 0.9)
	trap.add_child(base)

	# Teeth
	for i in range(5):
		var tooth = Polygon2D.new()
		var x_offset = (i - 2) * 8
		tooth.polygon = PackedVector2Array([
			Vector2(x_offset - 2, -5), Vector2(x_offset + 2, -5), Vector2(x_offset, -15)
		])
		tooth.color = Color(0.6, 0.6, 0.6, 1.0)
		trap.add_child(tooth)

	# Check for enemies stepping on trap using periodic checks
	var check_interval = 0.1
	var trap_radius = 30.0
	var max_duration = ability.duration + 10.0
	var checks = int(max_duration / check_interval)

	for i in range(checks):
		get_tree().create_timer(check_interval * i).timeout.connect(func():
			if not is_instance_valid(trap):
				return

			var enemies = _get_enemies_in_radius(trap_pos, trap_radius)
			if enemies.size() > 0:
				var target = enemies[0]

				# Snap trap - visual feedback
				_spawn_effect("punch_impact", trap_pos)
				_screen_shake("small")
				_play_sound("swing")

				# Deal damage and stun
				_deal_damage_to_enemy(target, damage)
				_apply_stun_to_enemy(target, ability.stun_duration)

				# Remove trap
				trap.queue_free()
		)

	# Trap expires after max duration
	get_tree().create_timer(max_duration).timeout.connect(func():
		if is_instance_valid(trap):
			trap.queue_free()
	)

	_play_sound("deploy")

func _execute_glue_bomb(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Throw a bomb that creates a slowing puddle."""
	var target_pos = _get_enemy_cluster_center(player.global_position, 250.0)
	var direction = (target_pos - player.global_position).normalized()

	# Create projectile
	var bomb = Node2D.new()
	bomb.name = "GlueBomb"
	bomb.global_position = player.global_position
	get_tree().current_scene.add_child(bomb)

	# Bomb visual
	var visual = ColorRect.new()
	visual.size = Vector2(16, 16)
	visual.position = Vector2(-8, -8)
	visual.color = Color(0.2, 0.8, 0.2, 1.0)
	bomb.add_child(visual)

	# Animate throw
	var tween = bomb.create_tween()
	tween.tween_property(bomb, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		# Create glue puddle
		_create_glue_puddle(target_pos, ability)
		bomb.queue_free()
	)

	_play_sound("throw")

func _create_glue_puddle(position: Vector2, ability: ActiveAbilityData) -> void:
	"""Create a puddle that slows enemies."""
	var puddle = Node2D.new()
	puddle.name = "GluePuddle"
	puddle.global_position = position
	puddle.z_index = -1
	puddle.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(puddle)

	var radius = ability.radius

	# Visual - green sticky puddle
	var visual = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(12):
		var angle = TAU * i / 12
		var r = radius * (0.8 + randf() * 0.4)
		points.append(Vector2(cos(angle), sin(angle)) * r)
	visual.polygon = points
	visual.color = Color(0.3, 0.7, 0.2, 0.6)
	puddle.add_child(visual)

	# Slow enemies in puddle
	var tick_interval = 0.3
	var ticks = int(ability.duration / tick_interval)

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(puddle):
				return
			var enemies = _get_enemies_in_radius(position, radius)
			for enemy in enemies:
				_apply_slow_to_enemy(enemy, ability.slow_percent, 0.5)
		)

	# Remove puddle
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(puddle):
			var fade = puddle.create_tween()
			fade.tween_property(puddle, "modulate:a", 0.0, 0.3)
			fade.tween_callback(puddle.queue_free)
	)

	_spawn_effect("poison", position)
	_screen_shake("small")

func _execute_pressure_mine(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Place an explosive mine that detonates when enemies approach."""
	var damage = _get_damage(ability)
	var mine_pos = player.global_position

	# Create mine visual
	var mine = Node2D.new()
	mine.name = "PressureMine"
	mine.global_position = mine_pos
	mine.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(mine)

	# Visual - circular mine with warning light
	var base = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(8):
		var angle = TAU * i / 8
		points.append(Vector2(cos(angle), sin(angle)) * 15)
	base.polygon = points
	base.color = Color(0.3, 0.3, 0.3, 1.0)
	mine.add_child(base)

	# Blinking light
	var light = ColorRect.new()
	light.size = Vector2(6, 6)
	light.position = Vector2(-3, -3)
	light.color = Color(1.0, 0.0, 0.0, 1.0)
	mine.add_child(light)

	# Blink animation
	var blink_tween = mine.create_tween().set_loops()
	blink_tween.tween_property(light, "modulate:a", 0.3, 0.5)
	blink_tween.tween_property(light, "modulate:a", 1.0, 0.5)

	# Check for enemies using periodic checks
	var check_interval = 0.1
	var trigger_radius = 40.0
	var explosion_radius = ability.radius
	var max_duration = ability.duration + 15.0
	var checks = int(max_duration / check_interval)

	for i in range(checks):
		get_tree().create_timer(check_interval * i).timeout.connect(func():
			if not is_instance_valid(mine):
				return

			var enemies = _get_enemies_in_radius(mine_pos, trigger_radius)
			if enemies.size() > 0:
				# Explosion!
				_spawn_effect("explosion", mine_pos)
				_screen_shake("medium")
				_play_sound("explosion")
				_impact_pause()

				# Deal damage to all enemies in explosion radius
				var blast_enemies = _get_enemies_in_radius(mine_pos, explosion_radius)
				for enemy in blast_enemies:
					_deal_damage_to_enemy(enemy, damage)
					_apply_stun_to_enemy(enemy, ability.stun_duration)

				mine.queue_free()
		)

	# Mine expires after max duration
	get_tree().create_timer(max_duration).timeout.connect(func():
		if is_instance_valid(mine):
			mine.queue_free()
	)

	_play_sound("deploy")

# ============================================
# NEW ABILITIES - STEALTH
# ============================================

func _execute_smoke_bomb(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Drop a smoke bomb that makes you invisible and slows enemies."""
	var smoke_pos = player.global_position

	# Create smoke cloud
	var smoke = Node2D.new()
	smoke.name = "SmokeCloud"
	smoke.global_position = smoke_pos
	smoke.z_index = 10
	smoke.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(smoke)

	# Visual - multiple semi-transparent circles
	for i in range(5):
		var cloud = Polygon2D.new()
		var radius = ability.radius * (0.5 + randf() * 0.5)
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		var points: PackedVector2Array = []
		for j in range(12):
			var angle = TAU * j / 12
			points.append(Vector2(cos(angle), sin(angle)) * radius + offset)
		cloud.polygon = points
		cloud.color = Color(0.3, 0.3, 0.3, 0.4)
		smoke.add_child(cloud)

	# Make player semi-invisible
	var player_sprite = player.get_node_or_null("Sprite2D")
	if not player_sprite:
		player_sprite = player.get_node_or_null("AnimatedSprite2D")

	if player_sprite:
		player_sprite.modulate.a = 0.3

	# Apply invulnerability
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true, ability.invulnerability_duration)

	# Slow enemies in smoke
	var tick_interval = 0.3
	var ticks = int(ability.duration / tick_interval)

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(smoke):
				return
			var enemies = _get_enemies_in_radius(smoke_pos, ability.radius)
			for enemy in enemies:
				_apply_slow_to_enemy(enemy, ability.slow_percent, 0.5)
		)

	# End effects
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(smoke):
			var fade = smoke.create_tween()
			fade.tween_property(smoke, "modulate:a", 0.0, 0.5)
			fade.tween_callback(smoke.queue_free)

		if is_instance_valid(player_sprite):
			player_sprite.modulate.a = 1.0
	)

	_play_sound("dash")
	_screen_shake("small")

func _execute_now_you_see_me(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Become completely invisible and untargetable, then reappear with a damaging burst."""
	var damage = _get_damage(ability)
	var start_pos = player.global_position

	# Make player invisible
	var player_sprite = player.get_node_or_null("Sprite2D")
	if not player_sprite:
		player_sprite = player.get_node_or_null("AnimatedSprite2D")

	if player_sprite:
		var fade_out = player_sprite.create_tween()
		fade_out.tween_property(player_sprite, "modulate:a", 0.0, 0.2)

	# Make player invulnerable
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true, ability.invulnerability_duration)

	# Spawn vanish effect
	_spawn_effect("shadowstep", start_pos)

	# Reappear after duration with damage burst
	get_tree().create_timer(ability.invulnerability_duration).timeout.connect(func():
		if not is_instance_valid(player):
			return

		# Fade back in
		if is_instance_valid(player_sprite):
			var fade_in = player_sprite.create_tween()
			fade_in.tween_property(player_sprite, "modulate:a", 1.0, 0.2)

		# Damage burst on reappear
		var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)

		_spawn_effect("magic_cast", player.global_position)
		_screen_shake("medium")
		_impact_pause()
	)

	_play_sound("shadowstep")

func _execute_pocket_sand(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Throw sand and flash a blinding light - now with stun and damage!"""
	var damage = _get_damage(ability)

	# Get ALL enemies in radius (360 degree AoE)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		if ability.base_damage > 0:
			_deal_damage_to_enemy(enemy, damage)
		_apply_slow_to_enemy(enemy, ability.slow_percent, ability.slow_duration)
		if ability.stun_duration > 0:
			_apply_stun_to_enemy(enemy, ability.stun_duration)
		# Visual feedback - yellow particles on enemy
		_spawn_sand_effect(enemy.global_position)

	# Sand throw visual - now 360 degrees
	var sand = Node2D.new()
	sand.global_position = player.global_position
	get_tree().current_scene.add_child(sand)

	# Particles spreading outward in all directions
	for i in range(24):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(0.9, 0.8, 0.5, 1.0)
		sand.add_child(particle)

		var angle = (float(i) / 24.0) * TAU + randf_range(-0.2, 0.2)
		var dist = randf_range(50, ability.radius)
		var end_pos = Vector2(cos(angle), sin(angle)) * dist

		var ptween = particle.create_tween()
		ptween.set_parallel(true)
		ptween.tween_property(particle, "position", end_pos, 0.3)
		ptween.tween_property(particle, "modulate:a", 0.0, 0.3)

	# Flash effect (from Blinding Flash)
	_spawn_effect("blinding_flash", player.global_position)

	get_tree().create_timer(0.4).timeout.connect(func():
		if is_instance_valid(sand):
			sand.queue_free()
	)

	_play_sound("flash")
	_screen_shake("medium")
	_impact_pause()

func _spawn_sand_effect(position: Vector2) -> void:
	"""Spawn sand particles at position."""
	var effect = Node2D.new()
	effect.global_position = position
	get_tree().current_scene.add_child(effect)

	for i in range(8):
		var p = ColorRect.new()
		p.size = Vector2(3, 3)
		p.color = Color(0.9, 0.8, 0.4, 0.8)
		effect.add_child(p)

		var angle = randf() * TAU
		var dist = randf_range(10, 30)
		var end = Vector2(cos(angle), sin(angle)) * dist

		var tw = p.create_tween()
		tw.tween_property(p, "position", end, 0.3)

	get_tree().create_timer(0.4).timeout.connect(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

# ============================================
# NEW ABILITIES - CROWD CONTROL
# ============================================

func _execute_terrifying_shout(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Let out a terrifying shout that fears enemies, making them run away."""
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		# Push enemies away (fear effect)
		var away_dir = (enemy.global_position - player.global_position).normalized()
		_apply_knockback_to_enemy(enemy, away_dir, ability.knockback_force * 2)
		_apply_slow_to_enemy(enemy, 0.3, ability.slow_duration)

	# Visual - shockwave effect
	_spawn_shout_wave(player.global_position, ability.radius, Color(0.8, 0.2, 0.2, 0.5))

	_spawn_effect("battle_cry", player.global_position)
	_play_sound("swing")
	_screen_shake("medium")

func _execute_demoralizing_shout(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Shout that weakens enemies, reducing their damage."""
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_apply_slow_to_enemy(enemy, ability.slow_percent, ability.slow_duration)
		# Visual indicator on affected enemies
		_spawn_debuff_indicator(enemy)

	# Visual - purple shockwave
	_spawn_shout_wave(player.global_position, ability.radius, Color(0.5, 0.2, 0.8, 0.5))

	_spawn_effect("battle_cry", player.global_position)
	_play_sound("swing")
	_screen_shake("small")

func _spawn_shout_wave(position: Vector2, radius: float, color: Color) -> void:
	"""Create expanding shockwave visual."""
	var wave = Node2D.new()
	wave.global_position = position
	wave.z_index = 5
	get_tree().current_scene.add_child(wave)

	var ring = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(32):
		var angle = TAU * i / 32
		points.append(Vector2(cos(angle), sin(angle)) * 20)
	ring.polygon = points
	ring.color = color
	wave.add_child(ring)

	var tween = wave.create_tween()
	tween.set_parallel(true)
	tween.tween_property(wave, "scale", Vector2(radius / 20, radius / 20), 0.3)
	tween.tween_property(wave, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(wave.queue_free)

func _spawn_debuff_indicator(enemy: Node2D) -> void:
	"""Show a debuff indicator above enemy."""
	if not is_instance_valid(enemy):
		return

	var indicator = ColorRect.new()
	indicator.size = Vector2(20, 5)
	indicator.position = Vector2(-10, -50)
	indicator.color = Color(0.5, 0.2, 0.8, 0.8)
	enemy.add_child(indicator)

	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(indicator):
			indicator.queue_free()
	)

func _execute_vortex(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Create a vortex that pulls enemies toward the center."""
	var target_pos = _get_enemy_cluster_center(player.global_position, 200.0)
	var damage = _get_damage(ability)

	# Create vortex visual
	var vortex = Node2D.new()
	vortex.name = "Vortex"
	vortex.global_position = target_pos
	vortex.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(vortex)

	# Spinning visual
	var spiral = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(24):
		var angle = TAU * i / 24
		var r = ability.radius * (0.3 + 0.7 * (i / 24.0))
		points.append(Vector2(cos(angle), sin(angle)) * r)
	spiral.polygon = points
	spiral.color = Color(0.3, 0.5, 0.8, 0.4)
	vortex.add_child(spiral)

	# Spin and pull enemies
	var tick_interval = 0.1
	var ticks = int(ability.duration / tick_interval)
	var damage_per_tick = damage / ticks

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(vortex):
				return

			vortex.rotation += 0.3

			var enemies = _get_enemies_in_radius(target_pos, ability.radius)
			for enemy in enemies:
				# Pull toward center
				var to_center = (target_pos - enemy.global_position).normalized()
				_apply_knockback_to_enemy(enemy, to_center, 80.0 * tick_interval)
				_deal_damage_to_enemy(enemy, damage_per_tick)
		)

	# Remove vortex
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(vortex):
			var fade = vortex.create_tween()
			fade.tween_property(vortex, "modulate:a", 0.0, 0.3)
			fade.tween_callback(vortex.queue_free)
	)

	_play_sound("whirlwind")
	_screen_shake("small")

func _execute_repulsive(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Blast all nearby enemies away from you."""
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
	var damage = _get_damage(ability)

	for enemy in enemies:
		var away_dir = (enemy.global_position - player.global_position).normalized()
		_apply_knockback_to_enemy(enemy, away_dir, ability.knockback_force)
		_deal_damage_to_enemy(enemy, damage)

	# Visual - expanding ring
	_spawn_shout_wave(player.global_position, ability.radius, Color(1.0, 0.8, 0.3, 0.6))

	_spawn_effect("holy", player.global_position)
	_play_sound("swing")
	_screen_shake("medium")
	_impact_pause()

func _execute_dj_drop(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Drop the bass! Stun all enemies on screen briefly."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var damage = _get_damage(ability)

	for enemy in enemies:
		if is_instance_valid(enemy):
			_apply_stun_to_enemy(enemy, ability.stun_duration)
			_deal_damage_to_enemy(enemy, damage)
			# Apply DANCE status effect label
			_apply_dance_status(enemy, ability.stun_duration)

	# Epic visual - screen-wide effect
	var drop = Node2D.new()
	drop.global_position = player.global_position
	drop.z_index = 100
	drop.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(drop)

	# Multiple expanding rings
	for i in range(3):
		get_tree().create_timer(i * 0.1).timeout.connect(func():
			if not is_instance_valid(drop):
				return
			var ring = Polygon2D.new()
			var points: PackedVector2Array = []
			for j in range(32):
				var angle = TAU * j / 32
				points.append(Vector2(cos(angle), sin(angle)) * 50)
			ring.polygon = points
			ring.color = Color(1.0, 0.5, 0.0, 0.6)
			drop.add_child(ring)

			var tw = ring.create_tween()
			tw.set_parallel(true)
			tw.tween_property(ring, "scale", Vector2(20, 20), 0.5)
			tw.tween_property(ring, "modulate:a", 0.0, 0.5)
		)

	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(drop):
			drop.queue_free()
	)

	_play_sound("ground_slam")
	_screen_shake("large")
	_impact_pause()

func _apply_dance_status(enemy: Node2D, duration: float) -> void:
	"""Apply a pink DANCE status label above an enemy's health bar."""
	if not is_instance_valid(enemy):
		return

	# Create the DANCE label
	var dance_label = Label.new()
	dance_label.name = "DanceStatus"
	dance_label.text = "DANCE"
	dance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dance_label.position = Vector2(-25, -75)  # Above health bar

	# Pink styling
	dance_label.add_theme_font_size_override("font_size", 12)
	dance_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.7))  # Pink
	dance_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.1, 0.3, 0.8))
	dance_label.add_theme_constant_override("shadow_offset_x", 1)
	dance_label.add_theme_constant_override("shadow_offset_y", 1)

	# Try to load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
		dance_label.add_theme_font_override("font", pixel_font)

	enemy.add_child(dance_label)

	# Animate: bob up and down while active
	var bob_tween = dance_label.create_tween().set_loops(int(duration / 0.3))
	bob_tween.tween_property(dance_label, "position:y", -80.0, 0.15).set_ease(Tween.EASE_IN_OUT)
	bob_tween.tween_property(dance_label, "position:y", -75.0, 0.15).set_ease(Tween.EASE_IN_OUT)

	# Remove after duration
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(dance_label):
			var fade = dance_label.create_tween()
			fade.tween_property(dance_label, "modulate:a", 0.0, 0.2)
			fade.tween_callback(dance_label.queue_free)
	)

# ============================================
# NEW ABILITIES - CHAOS/TRICK
# ============================================

func _execute_mirror_clone(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Create a mirror clone that attacks alongside you."""
	var damage = _get_damage(ability)

	# Spawn clone slightly behind player
	var offset = Vector2(0, 40)
	var clone_pos = player.global_position + offset

	_spawn_mirror_clone(clone_pos, damage, ability.duration, player)

	_spawn_effect("magic_cast", player.global_position)
	_play_sound("summon")

func _spawn_mirror_clone(position: Vector2, damage: float, duration: float, player: Node2D) -> void:
	"""Spawn a single mirror clone that perfectly mirrors the player's appearance and attacks."""
	var clone = Node2D.new()
	clone.name = "MirrorClone"
	clone.global_position = position
	get_tree().current_scene.add_child(clone)

	# Get player sprite and copy all properties exactly
	var player_sprite = player.get_node_or_null("Sprite")
	var clone_sprite: Sprite2D = null

	if player_sprite and player_sprite.texture:
		clone_sprite = Sprite2D.new()
		clone_sprite.name = "Sprite"
		clone_sprite.texture = player_sprite.texture
		clone_sprite.hframes = player_sprite.hframes
		clone_sprite.vframes = player_sprite.vframes
		clone_sprite.frame = player_sprite.frame
		clone_sprite.flip_h = player_sprite.flip_h
		clone_sprite.scale = player_sprite.scale
		clone_sprite.offset = player_sprite.offset
		clone_sprite.modulate = Color(0.5, 0.8, 1.0, 0.8)  # Blue tint
		clone.add_child(clone_sprite)
	else:
		# Fallback visual
		var visual = ColorRect.new()
		visual.size = Vector2(30, 40)
		visual.position = Vector2(-15, -20)
		visual.color = Color(0.5, 0.8, 1.0, 0.6)
		clone.add_child(visual)

	# Get player's attack cooldown for synced attacks
	var player_attack_cooldown = player.attack_cooldown if "attack_cooldown" in player else 0.5
	var player_animation_speed = player.animation_speed if "animation_speed" in player else 10.0

	# Store reference to sync animations
	var clone_data = {
		"sprite": clone_sprite,
		"player": player,
		"player_sprite": player_sprite,
		"attack_timer": 0.0,
		"attack_cooldown": player_attack_cooldown,
		"animation_speed": player_animation_speed,
		"damage_per_attack": damage / (duration / player_attack_cooldown),
		"is_attacking": false,
		"attack_frame": 0.0
	}

	# Sync animation with player every frame
	var sync_timer = 0.0
	var attack_timer = 0.0

	# Create a timer node to process clone logic
	var process_timer = Timer.new()
	process_timer.wait_time = 0.016  # ~60fps
	process_timer.autostart = true
	clone.add_child(process_timer)

	process_timer.timeout.connect(func():
		if not is_instance_valid(clone) or not is_instance_valid(player):
			return

		# Sync sprite frame and flip with player
		if clone_sprite and player_sprite:
			clone_sprite.frame = player_sprite.frame
			clone_sprite.flip_h = player_sprite.flip_h

		# Clone attacks when player attacks (check if player is attacking)
		if "is_attacking" in player and player.is_attacking:
			# Find and damage nearest enemy during attack
			var target = _get_nearest_enemy(clone.global_position, 150.0)
			if target and is_instance_valid(target):
				# Only deal damage once per attack animation
				if not clone_data.is_attacking:
					clone_data.is_attacking = true
					_deal_damage_to_enemy(target, clone_data.damage_per_attack)
					_spawn_effect("slash", target.global_position)
		else:
			clone_data.is_attacking = false

		# Move clone to maintain offset from player
		var to_player = player.global_position - clone.global_position
		if to_player.length() > 100:
			# Teleport if too far
			var angle = clone.global_position.angle_to_point(player.global_position)
			clone.global_position = player.global_position + Vector2(cos(angle + PI), sin(angle + PI)) * 60
		elif to_player.length() > 70:
			# Smoothly follow
			clone.global_position += to_player.normalized() * 200 * 0.016
	)

	# Remove clone after duration
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(clone):
			var fade = clone.create_tween()
			fade.tween_property(clone, "modulate:a", 0.0, 0.3)
			fade.tween_callback(clone.queue_free)
	)

func _execute_uno_reverse(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Reflect the next attack back at enemies for massive damage."""
	var damage = _get_damage(ability)

	# Apply a reflect buff to player
	if player.has_method("apply_reflect_shield"):
		player.apply_reflect_shield(damage, ability.duration)

	# Visual shield effect
	var shield = Node2D.new()
	shield.name = "UnoReverseShield"
	player.add_child(shield)

	var visual = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(16):
		var angle = TAU * i / 16
		points.append(Vector2(cos(angle), sin(angle)) * 40)
	visual.polygon = points
	visual.color = Color(1.0, 0.3, 0.3, 0.4)
	shield.add_child(visual)

	# Spin effect
	var spin = shield.create_tween().set_loops()
	spin.tween_property(shield, "rotation", TAU, 1.0)

	# For now, just deal damage to nearest enemies as "reflected"
	get_tree().create_timer(0.5).timeout.connect(func():
		var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)

		_spawn_effect("holy", player.global_position)
		_screen_shake("medium")
	)

	# Remove shield after duration
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(shield):
			shield.queue_free()
	)

	_play_sound("buff")

func _execute_orbital_strike(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Call down a devastating orbital strike on enemy positions."""
	var damage = _get_damage(ability)
	var target_pos = _get_enemy_cluster_center(player.global_position, 300.0)

	# Warning indicator
	var warning = Node2D.new()
	warning.global_position = target_pos
	get_tree().current_scene.add_child(warning)

	var indicator = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(16):
		var angle = TAU * i / 16
		points.append(Vector2(cos(angle), sin(angle)) * ability.radius)
	indicator.polygon = points
	indicator.color = Color(1.0, 0.0, 0.0, 0.3)
	warning.add_child(indicator)

	# Blink warning
	var blink = warning.create_tween().set_loops(int(ability.cast_time * 4))
	blink.tween_property(indicator, "modulate:a", 0.1, 0.125)
	blink.tween_property(indicator, "modulate:a", 1.0, 0.125)

	# Strike after cast time
	get_tree().create_timer(ability.cast_time).timeout.connect(func():
		if is_instance_valid(warning):
			warning.queue_free()

		# Create laser beam visual from above
		var beam = ColorRect.new()
		beam.size = Vector2(ability.radius * 2, 800)
		beam.position = Vector2(-ability.radius, -800)
		beam.color = Color(1.0, 0.8, 0.0, 0.8)

		var beam_node = Node2D.new()
		beam_node.global_position = target_pos
		beam_node.z_index = 50
		beam_node.add_child(beam)
		get_tree().current_scene.add_child(beam_node)

		# Deal massive damage
		var enemies = _get_enemies_in_radius(target_pos, ability.radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)
			_apply_stun_to_enemy(enemy, 1.0)

		_spawn_effect("explosion", target_pos)
		_screen_shake("large")
		_impact_pause()
		_play_sound("explosion")

		# Fade beam
		var fade = beam_node.create_tween()
		fade.tween_property(beam_node, "modulate:a", 0.0, 0.3)
		fade.tween_callback(beam_node.queue_free)
	)

	_play_sound("meteor")

# ============================================
# NEW ABILITIES - SUMMONS
# ============================================

func _execute_summon_party(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Summon a party of adventurers to fight alongside you."""
	var damage = _get_damage(ability)
	var party_size = 3
	var summon_types = ["warrior", "mage", "archer"]

	for i in range(party_size):
		var angle = TAU * i / party_size
		var offset = Vector2(cos(angle), sin(angle)) * 70
		var spawn_pos = player.global_position + offset

		spawn_pos.x = clamp(spawn_pos.x, -60, 1596)
		spawn_pos.y = clamp(spawn_pos.y, 40, 1382 - 40)

		_spawn_party_member(spawn_pos, damage / party_size, ability.duration, summon_types[i])

	_spawn_effect("magic_cast", player.global_position)
	_play_sound("summon")
	_screen_shake("small")

func _spawn_party_member(position: Vector2, damage: float, duration: float, member_type: String) -> void:
	"""Spawn a single party member summon."""
	var member = Node2D.new()
	member.name = "PartyMember_" + member_type
	member.global_position = position
	member.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(member)

	# Color based on type
	var color: Color
	match member_type:
		"warrior":
			color = Color(0.8, 0.3, 0.3, 0.8)  # Red
		"mage":
			color = Color(0.3, 0.3, 0.8, 0.8)  # Blue
		"archer":
			color = Color(0.3, 0.8, 0.3, 0.8)  # Green
		_:
			color = Color(0.8, 0.8, 0.8, 0.8)

	var visual = ColorRect.new()
	visual.size = Vector2(24, 32)
	visual.position = Vector2(-12, -16)
	visual.color = color
	member.add_child(visual)

	# Attack behavior
	var attack_interval = 0.6
	var attacks = int(duration / attack_interval)
	var damage_per_attack = damage / attacks
	var attack_range = 120.0 if member_type == "archer" else 60.0

	for i in range(attacks):
		get_tree().create_timer(attack_interval * i).timeout.connect(func():
			if not is_instance_valid(member):
				return

			var target = _get_nearest_enemy(member.global_position, attack_range)
			if target and is_instance_valid(target):
				# Move toward target if melee
				if member_type == "warrior":
					member.global_position = member.global_position.lerp(target.global_position, 0.3)

				_deal_damage_to_enemy(target, damage_per_attack)

				match member_type:
					"warrior":
						_spawn_effect("slash", target.global_position)
					"mage":
						_spawn_effect("magic_cast", target.global_position)
					"archer":
						_spawn_effect("arrow_impact", target.global_position)
		)

	# Remove after duration
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(member):
			var fade = member.create_tween()
			fade.tween_property(member, "modulate:a", 0.0, 0.3)
			fade.tween_callback(member.queue_free)
	)

func _execute_release_the_hounds(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Release attack dogs that chase and bite enemies."""
	var damage = _get_damage(ability)
	var hound_count = 3

	for i in range(hound_count):
		var angle = randf() * TAU
		var offset = Vector2(cos(angle), sin(angle)) * 40
		var spawn_pos = player.global_position + offset

		_spawn_hound(spawn_pos, damage / hound_count, ability.duration)

	_spawn_effect("dash_smoke", player.global_position)
	_play_sound("summon")

func _spawn_hound(position: Vector2, damage: float, duration: float) -> void:
	"""Spawn an attack hound."""
	var hound = Node2D.new()
	hound.name = "AttackHound"
	hound.global_position = position
	hound.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(hound)

	# Simple dog visual
	var body = ColorRect.new()
	body.size = Vector2(25, 15)
	body.position = Vector2(-12, -7)
	body.color = Color(0.5, 0.35, 0.2, 1.0)
	hound.add_child(body)

	# Head
	var head = ColorRect.new()
	head.size = Vector2(12, 12)
	head.position = Vector2(10, -10)
	head.color = Color(0.5, 0.35, 0.2, 1.0)
	hound.add_child(head)

	# Chase and attack behavior
	var tick_interval = 0.15
	var ticks = int(duration / tick_interval)
	var damage_per_bite = damage / (ticks / 3)  # Bite every ~0.45s
	var bite_counter = 0

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(hound):
				return

			var target = _get_nearest_enemy(hound.global_position, 300.0)
			if target and is_instance_valid(target):
				# Chase target
				var to_target = (target.global_position - hound.global_position)
				var chase_speed = 8.0
				hound.global_position += to_target.normalized() * chase_speed

				# Flip based on direction
				if to_target.x < 0:
					hound.scale.x = -1
				else:
					hound.scale.x = 1

				# Bite if close
				if to_target.length() < 30:
					bite_counter += 1
					if bite_counter >= 3:
						bite_counter = 0
						_deal_damage_to_enemy(target, damage_per_bite)
						_spawn_effect("punch_impact", target.global_position)
		)

	# Remove after duration
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(hound):
			hound.queue_free()
	)

# ============================================
# NEW ABILITIES - DEFENSIVE
# ============================================

func _execute_panic_button(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Emergency escape - become invulnerable and dash away."""
	var start_pos = player.global_position

	# Find safest direction (away from most enemies)
	var enemies = get_tree().get_nodes_in_group("enemies")
	var avg_enemy_pos = Vector2.ZERO
	var count = 0

	for enemy in enemies:
		if is_instance_valid(enemy) and start_pos.distance_to(enemy.global_position) < 300:
			avg_enemy_pos += enemy.global_position
			count += 1

	var escape_dir: Vector2
	if count > 0:
		avg_enemy_pos /= count
		escape_dir = (start_pos - avg_enemy_pos).normalized()
	else:
		escape_dir = Vector2.DOWN

	# Make invulnerable
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true, ability.invulnerability_duration)

	# Dash away
	var end_pos = start_pos + escape_dir * ability.range_distance
	end_pos.x = clamp(end_pos.x, -60, 1596)
	end_pos.y = clamp(end_pos.y, 40, 1382 - 40)

	var tween = create_tween()
	tween.tween_property(player, "global_position", end_pos, 0.2)

	# Heal a bit
	if player.has_method("heal"):
		player.heal(player.max_health * 0.1)  # 10% heal

	_spawn_effect("dash_smoke", start_pos)
	_spawn_effect("holy", end_pos)
	_play_sound("dash")
	_screen_shake("small")

func _execute_pocket_healer(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Summon a healing fairy that follows and heals you."""
	var total_heal = player.max_health * 0.3  # 30% max HP over duration

	# Create healer visual
	var healer = Node2D.new()
	healer.name = "PocketHealer"
	healer.modulate.a = 0.9  # 90% opacity
	player.add_child(healer)
	healer.position = Vector2(30, -30)

	# Fairy visual
	var fairy = ColorRect.new()
	fairy.size = Vector2(12, 12)
	fairy.position = Vector2(-6, -6)
	fairy.color = Color(0.3, 1.0, 0.5, 0.8)
	healer.add_child(fairy)

	# Glow
	var glow = ColorRect.new()
	glow.size = Vector2(20, 20)
	glow.position = Vector2(-10, -10)
	glow.color = Color(0.3, 1.0, 0.5, 0.3)
	healer.add_child(glow)

	# Bob animation
	var bob = healer.create_tween().set_loops()
	bob.tween_property(healer, "position:y", -40, 0.5).set_trans(Tween.TRANS_SINE)
	bob.tween_property(healer, "position:y", -30, 0.5).set_trans(Tween.TRANS_SINE)

	# Heal over time
	var tick_interval = 0.5
	var ticks = int(ability.duration / tick_interval)
	var heal_per_tick = total_heal / ticks

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if is_instance_valid(player) and player.has_method("heal"):
				player.heal(heal_per_tick)
				# Small heal visual
				_spawn_effect("healing_light", player.global_position)
		)

	# Remove after duration
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(healer):
			healer.queue_free()
	)

	_play_sound("heal")

func _execute_safe_space(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Create a protective barrier that blocks projectiles and slows enemies."""
	var barrier_pos = player.global_position

	# Create barrier visual
	var barrier = Node2D.new()
	barrier.name = "SafeSpace"
	barrier.global_position = barrier_pos
	barrier.modulate.a = 0.9  # 90% opacity
	get_tree().current_scene.add_child(barrier)

	# Dome visual
	var dome = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(24):
		var angle = TAU * i / 24
		points.append(Vector2(cos(angle), sin(angle)) * ability.radius)
	dome.polygon = points
	dome.color = Color(0.3, 0.8, 1.0, 0.3)
	barrier.add_child(dome)

	# Border
	var border = Line2D.new()
	border.width = 3.0
	border.default_color = Color(0.3, 0.8, 1.0, 0.8)
	for i in range(25):
		var angle = TAU * i / 24
		border.add_point(Vector2(cos(angle), sin(angle)) * ability.radius)
	barrier.add_child(border)

	# Slow enemies entering barrier and give player slight damage reduction
	var tick_interval = 0.2
	var ticks = int(ability.duration / tick_interval)

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(barrier):
				return
			var enemies = _get_enemies_in_radius(barrier_pos, ability.radius)
			for enemy in enemies:
				_apply_slow_to_enemy(enemy, ability.slow_percent, 0.3)
		)

	# Remove barrier
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(barrier):
			var fade = barrier.create_tween()
			fade.tween_property(barrier, "modulate:a", 0.0, 0.3)
			fade.tween_callback(barrier.queue_free)
	)

	_spawn_effect("shield", barrier_pos)
	_play_sound("buff")

# ============================================
# NEW ABILITIES - GAMBLING/TRANSFORM
# ============================================

func _execute_double_or_nothing(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Gamble! 50% chance to deal double damage, 50% chance to deal nothing."""
	var base_damage = _get_damage(ability)
	var roll = randf()

	if roll < 0.5:
		# WIN - Double damage!
		var damage = base_damage * 2
		var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)

		# Gold effect
		_spawn_effect("holy", player.global_position)
		_screen_shake("large")
		_impact_pause()

		# Visual feedback - gold burst
		var win = Node2D.new()
		win.global_position = player.global_position
		get_tree().current_scene.add_child(win)

		for i in range(20):
			var coin = ColorRect.new()
			coin.size = Vector2(8, 8)
			coin.color = Color(1.0, 0.85, 0.0, 1.0)
			win.add_child(coin)

			var angle = randf() * TAU
			var dist = randf_range(50, 150)
			var end = Vector2(cos(angle), sin(angle)) * dist

			var tw = coin.create_tween()
			tw.set_parallel(true)
			tw.tween_property(coin, "position", end, 0.5)
			tw.tween_property(coin, "modulate:a", 0.0, 0.5)

		get_tree().create_timer(0.6).timeout.connect(func():
			if is_instance_valid(win):
				win.queue_free()
		)
	else:
		# LOSE - Nothing happens
		_spawn_effect("magic_cast", player.global_position)

		# Sad effect - gray poof
		var lose = ColorRect.new()
		lose.size = Vector2(50, 50)
		lose.position = player.global_position - Vector2(25, 25)
		lose.color = Color(0.5, 0.5, 0.5, 0.5)
		get_tree().current_scene.add_child(lose)

		var tw = lose.create_tween()
		tw.tween_property(lose, "modulate:a", 0.0, 0.3)
		tw.tween_callback(lose.queue_free)

	_play_sound("swing")

func _execute_gigantamax(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Grow to giant size! Increased damage and knockback, but bigger hitbox."""
	var player_id = player.get_instance_id()

	# Store base scale on first use, or use existing base scale
	if not _gigantamax_base_scales.has(player_id):
		_gigantamax_base_scales[player_id] = player.scale

	var base_scale = _gigantamax_base_scales[player_id]
	var max_scale = base_scale * 2.0

	# If already at max size, don't grow further (still apply effects)
	var already_at_max = player.scale.x >= max_scale.x - 0.01

	if not already_at_max:
		# Grow animation to max size
		var grow = player.create_tween()
		grow.tween_property(player, "scale", max_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Apply damage boost
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(1.5, ability.duration)  # 50% more damage

	# Stomp damage while giant
	var stomp_interval = 0.5
	var stomps = int(ability.duration / stomp_interval)
	var damage = _get_damage(ability)

	for i in range(stomps):
		get_tree().create_timer(stomp_interval * i).timeout.connect(func():
			if not is_instance_valid(player):
				return
			var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
			for enemy in enemies:
				_deal_damage_to_enemy(enemy, damage / stomps)
				var away = (enemy.global_position - player.global_position).normalized()
				_apply_knockback_to_enemy(enemy, away, ability.knockback_force)
		)

	# Shrink back to base scale after duration
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(player):
			var shrink = player.create_tween()
			shrink.tween_property(player, "scale", base_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	)

	_spawn_effect("impact_smoke", player.global_position)
	_play_sound("buff")
	_screen_shake("medium")

func _execute_monster_energy(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Drink a monster energy! Massive speed and attack speed boost."""
	# Speed boost (applied via player method or stat)
	if player.has_method("apply_speed_boost"):
		player.apply_speed_boost(1.5, ability.duration)  # 50% speed

	# Attack speed boost
	if player.has_method("apply_attack_speed_boost"):
		player.apply_attack_speed_boost(1.3, ability.duration)  # 30% attack speed

	# Fire aura effect below player's feet
	var fire_aura = AnimatedSprite2D.new()
	fire_aura.name = "MonsterEnergyAura"
	fire_aura.position = Vector2(0, 20)  # Below player's feet
	fire_aura.z_index = -1  # Render behind the player
	fire_aura.scale = Vector2(0.5, 0.5)

	# Create sprite frames from the fire aura images
	var frames = SpriteFrames.new()
	frames.add_animation("fire")
	frames.set_animation_loop("fire", true)
	frames.set_animation_speed("fire", 24.0)  # 24 FPS

	# Load all 67 frames (1_0.png to 1_66.png)
	for i in range(67):
		var path = "res://assets/sprites/effects/Fire Aura/5/1_%d.png" % i
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture:
				frames.add_frame("fire", texture)

	fire_aura.sprite_frames = frames
	fire_aura.play("fire")
	player.add_child(fire_aura)

	# Remove after duration
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(fire_aura):
			fire_aura.queue_free()
	)

	_spawn_effect("holy", player.global_position)
	_play_sound("buff")

func _execute_i_see_red(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Enter a berserker rage! Deal more damage but take more damage."""
	var damage = _get_damage(ability)

	# Damage boost (high)
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(2.0, ability.duration)  # Double damage!

	# Red visual tint on player
	var player_sprite = player.get_node_or_null("Sprite2D")
	if not player_sprite:
		player_sprite = player.get_node_or_null("AnimatedSprite2D")

	if player_sprite:
		player_sprite.modulate = Color(1.5, 0.5, 0.5, 1.0)

	# Red screen overlay
	var red_overlay = CanvasLayer.new()
	red_overlay.layer = 90
	var red_rect = ColorRect.new()
	red_rect.color = Color(1.0, 0.0, 0.0, 0.15)  # Transparent red
	red_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	red_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_overlay.add_child(red_rect)
	get_tree().root.add_child(red_overlay)

	# Periodic damage around player (rage aura)
	var tick_interval = 0.3
	var ticks = int(ability.duration / tick_interval)
	var damage_per_tick = damage / ticks

	for i in range(ticks):
		get_tree().create_timer(tick_interval * i).timeout.connect(func():
			if not is_instance_valid(player):
				return
			var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
			for enemy in enemies:
				_deal_damage_to_enemy(enemy, damage_per_tick)
		)

	# End rage
	get_tree().create_timer(ability.duration).timeout.connect(func():
		if is_instance_valid(player_sprite):
			player_sprite.modulate = Color.WHITE
		if is_instance_valid(red_overlay):
			red_overlay.queue_free()
	)

	_spawn_effect("fire_cast", player.global_position)
	_play_sound("battle_cry")
	_screen_shake("medium")
