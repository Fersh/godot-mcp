extends Node

# Singleton for managing all ability-related functionality
# Add to autoload as "AbilityManager"

signal ability_acquired(ability: AbilityData)
signal ability_selection_requested(choices: Array)

var acquired_abilities: Array[AbilityData] = []
var all_abilities: Array[AbilityData] = []

# Cached stat modifiers (recalculated when abilities change)
var stat_modifiers: Dictionary = {
	"attack_speed": 0.0,
	"damage": 0.0,
	"max_hp": 0.0,
	"xp_gain": 0.0,
	"move_speed": 0.0,
	"pickup_range": 0.0,
	"projectile_speed": 0.0,
	"projectile_count": 0,
	"projectile_pierce": 0,
	"projectile_spread": 0.0,
	"crit_chance": 0.0,
	"luck": 0.0,
	"size": 0.0,
	"melee_area": 0.0,
	"melee_range": 0.0,
}

# Special effect flags/values
var has_regen: bool = false
var regen_rate: float = 0.0
var has_thorns: bool = false
var thorns_damage: float = 0.0
var has_orbital: bool = false
var orbital_count: int = 0
var has_tesla_coil: bool = false
var tesla_damage: float = 0.0
var has_cull_weak: bool = false
var cull_threshold: float = 0.0
var has_vampirism: bool = false
var vampirism_chance: float = 0.0
var has_knockback: bool = false
var knockback_force: float = 0.0
var has_ring_of_fire: bool = false
var ring_projectile_count: int = 0
var has_toxic_cloud: bool = false
var toxic_dps: float = 0.0
var has_death_explosion: bool = false
var explosion_damage: float = 0.0
var has_lightning_strike: bool = false
var lightning_damage: float = 0.0
var has_drone: bool = false
var drone_count: int = 0
var has_adrenaline: bool = false
var adrenaline_boost: float = 0.0
var has_frenzy: bool = false
var frenzy_boost: float = 0.0
var has_double_xp_chance: bool = false
var double_xp_chance: float = 0.0
var has_rubber_walls: bool = false
var has_rear_shot: bool = false
var has_sniper_damage: bool = false
var sniper_bonus: float = 0.0

# Melee-specific effects
var has_bleeding: bool = false
var bleeding_dps: float = 0.0
var has_deflect: bool = false
var has_whirlwind: bool = false
var whirlwind_cooldown: float = 3.0
var whirlwind_timer: float = 0.0

# New ability effects
var armor: float = 0.0  # Flat damage reduction
var coin_gain_bonus: float = 0.0
var has_focus_regen: bool = false
var focus_regen_rate: float = 0.0
var has_momentum: bool = false
var momentum_bonus: float = 0.0
var melee_knockback: float = 0.0
var has_retribution: bool = false
var retribution_damage: float = 0.0
var has_time_dilation: bool = false
var time_dilation_slow: float = 0.0
var has_giant_slayer: bool = false
var giant_slayer_bonus: float = 0.0
var has_backstab: bool = false
var backstab_crit_bonus: float = 0.0
var has_parry: bool = false
var parry_chance: float = 0.0
var has_seismic_slam: bool = false
var seismic_stun_chance: float = 0.0
var has_bloodthirst: bool = false
var bloodthirst_boost: float = 0.0
var has_double_tap: bool = false
var double_tap_chance: float = 0.0
var has_point_blank: bool = false
var point_blank_bonus: float = 0.0
var has_blade_beam: bool = false
var has_blood_money: bool = false
var blood_money_heal: float = 0.0
var has_divine_shield: bool = false
var divine_shield_duration: float = 0.0
var divine_shield_active: bool = false
var divine_shield_timer: float = 0.0
var has_ricochet: bool = false
var ricochet_bounces: int = 0
var has_phoenix: bool = false
var phoenix_hp_percent: float = 0.0
var phoenix_used: bool = false
var has_boomerang: bool = false

# Timers for periodic effects
var regen_timer: float = 0.0
var tesla_timer: float = 0.0
var ring_of_fire_timer: float = 0.0
var lightning_timer: float = 0.0
var toxic_timer: float = 0.0

# Constants for periodic effects
const TESLA_INTERVAL: float = 0.8
const RING_OF_FIRE_INTERVAL: float = 3.0
const LIGHTNING_INTERVAL: float = 2.0
const TOXIC_INTERVAL: float = 0.5
const TOXIC_RADIUS: float = 100.0

# Is the player a ranged character? (for filtering abilities)
var is_ranged_character: bool = true

func _ready() -> void:
	all_abilities = AbilityDatabase.get_all_abilities()

func reset() -> void:
	# Reset all acquired abilities
	acquired_abilities.clear()

	# Reset stat modifiers
	stat_modifiers = {
		"attack_speed": 0.0,
		"damage": 0.0,
		"max_hp": 0.0,
		"xp_gain": 0.0,
		"move_speed": 0.0,
		"pickup_range": 0.0,
		"projectile_speed": 0.0,
		"projectile_count": 0,
		"projectile_pierce": 0,
		"projectile_spread": 0.0,
		"crit_chance": 0.0,
		"luck": 0.0,
		"size": 0.0,
		"melee_area": 0.0,
		"melee_range": 0.0,
	}

	# Reset special effect flags
	has_regen = false
	regen_rate = 0.0
	has_thorns = false
	thorns_damage = 0.0
	has_orbital = false
	orbital_count = 0
	has_tesla_coil = false
	tesla_damage = 0.0
	has_cull_weak = false
	cull_threshold = 0.0
	has_vampirism = false
	vampirism_chance = 0.0
	has_knockback = false
	knockback_force = 0.0
	has_ring_of_fire = false
	ring_projectile_count = 0
	has_toxic_cloud = false
	toxic_dps = 0.0
	has_death_explosion = false
	explosion_damage = 0.0
	has_lightning_strike = false
	lightning_damage = 0.0
	has_drone = false
	drone_count = 0
	has_adrenaline = false
	adrenaline_boost = 0.0
	has_frenzy = false
	frenzy_boost = 0.0
	has_double_xp_chance = false
	double_xp_chance = 0.0
	has_rubber_walls = false
	has_rear_shot = false
	has_sniper_damage = false
	sniper_bonus = 0.0

	# Reset melee effects
	has_bleeding = false
	bleeding_dps = 0.0
	has_deflect = false
	has_whirlwind = false
	whirlwind_cooldown = 3.0
	whirlwind_timer = 0.0

	# Reset new ability effects
	armor = 0.0
	coin_gain_bonus = 0.0
	has_focus_regen = false
	focus_regen_rate = 0.0
	has_momentum = false
	momentum_bonus = 0.0
	melee_knockback = 0.0
	has_retribution = false
	retribution_damage = 0.0
	has_time_dilation = false
	time_dilation_slow = 0.0
	has_giant_slayer = false
	giant_slayer_bonus = 0.0
	has_backstab = false
	backstab_crit_bonus = 0.0
	has_parry = false
	parry_chance = 0.0
	has_seismic_slam = false
	seismic_stun_chance = 0.0
	has_bloodthirst = false
	bloodthirst_boost = 0.0
	has_double_tap = false
	double_tap_chance = 0.0
	has_point_blank = false
	point_blank_bonus = 0.0
	has_blade_beam = false
	has_blood_money = false
	blood_money_heal = 0.0
	has_divine_shield = false
	divine_shield_duration = 0.0
	divine_shield_active = false
	divine_shield_timer = 0.0
	has_ricochet = false
	ricochet_bounces = 0
	has_phoenix = false
	phoenix_hp_percent = 0.0
	phoenix_used = false
	has_boomerang = false

	# Reset timers
	regen_timer = 0.0
	tesla_timer = 0.0
	ring_of_fire_timer = 0.0
	lightning_timer = 0.0
	toxic_timer = 0.0

func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	process_periodic_effects(delta, player)

func process_periodic_effects(delta: float, player: Node2D) -> void:
	# Regeneration (from abilities and permanent upgrades)
	var total_regen = get_regen_rate()
	if total_regen > 0 or has_regen or has_permanent_regen():
		regen_timer += delta
		if regen_timer >= 1.0:
			regen_timer = 0.0
			heal_player(player, total_regen)

	# Focus regen (only while standing still)
	if has_focus_regen and player.has_method("get_velocity"):
		var velocity = player.get_velocity() if player.has_method("get_velocity") else player.velocity
		if velocity.length() < 5.0:  # Standing still
			heal_player(player, focus_regen_rate * delta)

	# Divine Shield timer
	if divine_shield_active:
		divine_shield_timer -= delta
		if divine_shield_timer <= 0:
			divine_shield_active = false

	# Tesla Coil
	if has_tesla_coil:
		tesla_timer += delta
		if tesla_timer >= TESLA_INTERVAL:
			tesla_timer = 0.0
			fire_tesla_coil(player)

	# Ring of Fire
	if has_ring_of_fire:
		ring_of_fire_timer += delta
		if ring_of_fire_timer >= RING_OF_FIRE_INTERVAL:
			ring_of_fire_timer = 0.0
			fire_ring_of_fire(player)

	# Lightning Strike
	if has_lightning_strike:
		lightning_timer += delta
		if lightning_timer >= LIGHTNING_INTERVAL:
			lightning_timer = 0.0
			strike_lightning(player)

	# Toxic Cloud
	if has_toxic_cloud:
		toxic_timer += delta
		if toxic_timer >= TOXIC_INTERVAL:
			toxic_timer = 0.0
			apply_toxic_damage(player)

func heal_player(player: Node2D, amount: float, play_sound: bool = false) -> void:
	if player.has_method("heal"):
		player.heal(amount, play_sound)

func fire_tesla_coil(player: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = 200.0  # Tesla range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	if closest and closest.has_method("take_damage"):
		closest.take_damage(tesla_damage)
		spawn_lightning_effect(player.global_position, closest.global_position)

func fire_ring_of_fire(player: Node2D) -> void:
	if not player.has_method("spawn_arrow"):
		return

	var angle_step = TAU / ring_projectile_count
	for i in ring_projectile_count:
		var angle = i * angle_step
		var direction = Vector2(cos(angle), sin(angle))
		spawn_ring_projectile(player, direction)

func spawn_ring_projectile(player: Node2D, direction: Vector2) -> void:
	if player.arrow_scene == null:
		return

	var arrow = player.arrow_scene.instantiate()
	arrow.global_position = player.global_position
	arrow.direction = direction
	player.get_parent().add_child(arrow)

func strike_lightning(player: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return

	var target = enemies[randi() % enemies.size()]
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(lightning_damage)
		spawn_lightning_bolt(target.global_position)

func apply_toxic_damage(player: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var damage_per_tick = toxic_dps * TOXIC_INTERVAL

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist <= TOXIC_RADIUS and enemy.has_method("take_damage"):
				enemy.take_damage(damage_per_tick)

func spawn_lightning_effect(from: Vector2, to: Vector2) -> void:
	# Visual effect for tesla coil - create a simple line
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 3.0
	line.default_color = Color(0.5, 0.8, 1.0, 0.8)
	get_tree().current_scene.add_child(line)

	# Fade out
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)

func spawn_lightning_bolt(pos: Vector2) -> void:
	# Visual effect for lightning strike
	var bolt = Line2D.new()
	bolt.add_point(pos + Vector2(0, -500))
	bolt.add_point(pos)
	bolt.width = 4.0
	bolt.default_color = Color(1.0, 1.0, 0.5, 1.0)
	get_tree().current_scene.add_child(bolt)

	var tween = create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, 0.3)
	tween.tween_callback(bolt.queue_free)

func apply_adrenaline_buff(player: Node2D) -> void:
	# Temporary speed boost
	if player.has_method("apply_temporary_speed_boost"):
		player.apply_temporary_speed_boost(adrenaline_boost, 2.0)

func trigger_death_explosion(enemy: Node2D) -> void:
	var explosion_radius = 80.0
	var enemies = get_tree().get_nodes_in_group("enemies")

	for other_enemy in enemies:
		if other_enemy != enemy and is_instance_valid(other_enemy):
			var dist = enemy.global_position.distance_to(other_enemy.global_position)
			if dist <= explosion_radius and other_enemy.has_method("take_damage"):
				other_enemy.take_damage(explosion_damage)

	# Visual effect
	spawn_explosion_effect(enemy.global_position)

func spawn_explosion_effect(pos: Vector2) -> void:
	var circle = Node2D.new()
	circle.global_position = pos
	get_tree().current_scene.add_child(circle)

	circle.set_script(load("res://scripts/abilities/explosion_effect.gd"))

# Get random abilities for level up selection
func get_random_abilities(count: int = 3) -> Array[AbilityData]:
	var available = get_available_abilities()
	var choices: Array[AbilityData] = []

	for i in count:
		if available.size() == 0:
			break

		var ability = pick_weighted_random(available)
		if ability:
			choices.append(ability)
			available.erase(ability)

	return choices

func get_available_abilities() -> Array[AbilityData]:
	var available: Array[AbilityData] = []

	for ability in all_abilities:
		# Skip melee abilities for ranged characters
		if ability.type == AbilityData.Type.MELEE_ONLY and is_ranged_character:
			continue

		# Skip ranged abilities for melee characters
		if ability.type == AbilityData.Type.RANGED_ONLY and not is_ranged_character:
			continue

		# Check if already acquired (allow stacking for some abilities)
		if not is_ability_stackable(ability) and has_ability(ability.id):
			continue

		available.append(ability)

	return available

func is_ability_stackable(ability: AbilityData) -> bool:
	# Most stat boost abilities can stack
	if ability.type == AbilityData.Type.STAT_BOOST:
		return true

	# Some specific abilities can stack
	match ability.id:
		"split_shot", "laser_drill", "scattergun":
			return true

	return false

func has_ability(id: String) -> bool:
	for ability in acquired_abilities:
		if ability.id == id:
			return true
	return false

func get_ability_acquisition_count(ability_id: String) -> int:
	var count = 0
	for ability in acquired_abilities:
		if ability.id == ability_id:
			count += 1
	return count

func pick_weighted_random(abilities: Array[AbilityData]) -> AbilityData:
	if abilities.size() == 0:
		return null

	# Group by rarity
	var by_rarity: Dictionary = {}
	for ability in abilities:
		if not by_rarity.has(ability.rarity):
			by_rarity[ability.rarity] = []
		by_rarity[ability.rarity].append(ability)

	# Roll for rarity
	var roll = randf() * 100.0
	var cumulative = 0.0
	var selected_rarity = AbilityData.Rarity.COMMON

	for rarity in [AbilityData.Rarity.MYTHIC, AbilityData.Rarity.LEGENDARY, AbilityData.Rarity.RARE, AbilityData.Rarity.COMMON]:
		cumulative += AbilityData.RARITY_WEIGHTS[rarity]
		if roll <= cumulative and by_rarity.has(rarity) and by_rarity[rarity].size() > 0:
			selected_rarity = rarity
			break

	# Fallback to any available rarity
	if not by_rarity.has(selected_rarity) or by_rarity[selected_rarity].size() == 0:
		for rarity in by_rarity.keys():
			if by_rarity[rarity].size() > 0:
				selected_rarity = rarity
				break

	if by_rarity.has(selected_rarity) and by_rarity[selected_rarity].size() > 0:
		var rarity_pool = by_rarity[selected_rarity]

		# Weight abilities by how many times they've been acquired (diversity bonus)
		# Each acquisition reduces the weight by 40%, encouraging variety
		var weights: Array[float] = []
		var total_weight: float = 0.0

		for ability in rarity_pool:
			var acquisition_count = get_ability_acquisition_count(ability.id)
			# Base weight of 1.0, reduced by 40% for each time already acquired
			var weight = pow(0.6, acquisition_count)
			weights.append(weight)
			total_weight += weight

		# Pick based on weights
		if total_weight > 0:
			var weight_roll = randf() * total_weight
			var weight_cumulative = 0.0
			for i in rarity_pool.size():
				weight_cumulative += weights[i]
				if weight_roll <= weight_cumulative:
					return rarity_pool[i]

		# Fallback to random if weighting fails
		return rarity_pool[randi() % rarity_pool.size()]

	return null

func acquire_ability(ability: AbilityData) -> void:
	acquired_abilities.append(ability)
	apply_ability_effects(ability)
	emit_signal("ability_acquired", ability)

func apply_ability_effects(ability: AbilityData) -> void:
	for effect in ability.effects:
		var effect_type = effect.effect_type
		var value = effect.value

		match effect_type:
			# Stat modifiers
			AbilityData.EffectType.ATTACK_SPEED:
				stat_modifiers["attack_speed"] += value
			AbilityData.EffectType.DAMAGE:
				stat_modifiers["damage"] += value
			AbilityData.EffectType.MAX_HP:
				stat_modifiers["max_hp"] += value
			AbilityData.EffectType.XP_GAIN:
				stat_modifiers["xp_gain"] += value
			AbilityData.EffectType.MOVE_SPEED:
				stat_modifiers["move_speed"] += value
			AbilityData.EffectType.PICKUP_RANGE:
				stat_modifiers["pickup_range"] += value
			AbilityData.EffectType.PROJECTILE_SPEED:
				stat_modifiers["projectile_speed"] += value
			AbilityData.EffectType.PROJECTILE_COUNT:
				stat_modifiers["projectile_count"] += int(value)
			AbilityData.EffectType.PROJECTILE_PIERCE:
				stat_modifiers["projectile_pierce"] += int(value)
			AbilityData.EffectType.PROJECTILE_SPREAD:
				stat_modifiers["projectile_spread"] += value
			AbilityData.EffectType.CRIT_CHANCE:
				stat_modifiers["crit_chance"] += value
			AbilityData.EffectType.LUCK:
				stat_modifiers["luck"] += value
			AbilityData.EffectType.SIZE:
				stat_modifiers["size"] += value

			# Special effects
			AbilityData.EffectType.REGEN:
				has_regen = true
				regen_rate += value
			AbilityData.EffectType.THORNS:
				has_thorns = true
				thorns_damage += value
			AbilityData.EffectType.ORBITAL:
				has_orbital = true
				orbital_count += int(value)
				spawn_orbital()
			AbilityData.EffectType.TESLA_COIL:
				has_tesla_coil = true
				tesla_damage += value
			AbilityData.EffectType.CULL_WEAK:
				has_cull_weak = true
				cull_threshold = max(cull_threshold, value)
			AbilityData.EffectType.VAMPIRISM:
				has_vampirism = true
				vampirism_chance += value
			AbilityData.EffectType.KNOCKBACK:
				has_knockback = true
				knockback_force += value
			AbilityData.EffectType.RING_OF_FIRE:
				has_ring_of_fire = true
				ring_projectile_count += int(value)
			AbilityData.EffectType.TOXIC_CLOUD:
				has_toxic_cloud = true
				toxic_dps += value
				spawn_toxic_aura()
			AbilityData.EffectType.DEATH_EXPLOSION:
				has_death_explosion = true
				explosion_damage += value
			AbilityData.EffectType.LIGHTNING_STRIKE:
				has_lightning_strike = true
				lightning_damage += value
			AbilityData.EffectType.DRONE:
				has_drone = true
				drone_count += int(value)
				spawn_drone()
			AbilityData.EffectType.ADRENALINE:
				has_adrenaline = true
				adrenaline_boost += value
			AbilityData.EffectType.FRENZY:
				has_frenzy = true
				frenzy_boost += value
			AbilityData.EffectType.DOUBLE_XP_CHANCE:
				has_double_xp_chance = true
				double_xp_chance += value
			AbilityData.EffectType.RUBBER_WALLS:
				has_rubber_walls = true
			AbilityData.EffectType.REAR_SHOT:
				has_rear_shot = true
			AbilityData.EffectType.SNIPER_DAMAGE:
				has_sniper_damage = true
				sniper_bonus += value

			# Melee effects
			AbilityData.EffectType.MELEE_AREA:
				stat_modifiers["melee_area"] += value
			AbilityData.EffectType.MELEE_RANGE:
				stat_modifiers["melee_range"] += value
			AbilityData.EffectType.BLEEDING:
				has_bleeding = true
				bleeding_dps += value
			AbilityData.EffectType.DEFLECT:
				has_deflect = true
			AbilityData.EffectType.WHIRLWIND:
				has_whirlwind = true
				whirlwind_cooldown = value

			# New ability effects
			AbilityData.EffectType.ARMOR:
				armor += value
			AbilityData.EffectType.COIN_GAIN:
				coin_gain_bonus += value
			AbilityData.EffectType.FOCUS_REGEN:
				has_focus_regen = true
				focus_regen_rate += value
			AbilityData.EffectType.MOMENTUM:
				has_momentum = true
				momentum_bonus += value
			AbilityData.EffectType.MELEE_KNOCKBACK:
				melee_knockback += value
			AbilityData.EffectType.RETRIBUTION:
				has_retribution = true
				retribution_damage += value
			AbilityData.EffectType.TIME_DILATION:
				has_time_dilation = true
				time_dilation_slow += value
			AbilityData.EffectType.GIANT_SLAYER:
				has_giant_slayer = true
				giant_slayer_bonus += value
			AbilityData.EffectType.BACKSTAB:
				has_backstab = true
				backstab_crit_bonus += value
			AbilityData.EffectType.PARRY:
				has_parry = true
				parry_chance += value
			AbilityData.EffectType.SEISMIC_SLAM:
				has_seismic_slam = true
				seismic_stun_chance += value
			AbilityData.EffectType.BLOODTHIRST:
				has_bloodthirst = true
				bloodthirst_boost += value
			AbilityData.EffectType.DOUBLE_TAP:
				has_double_tap = true
				double_tap_chance += value
			AbilityData.EffectType.POINT_BLANK:
				has_point_blank = true
				point_blank_bonus += value
			AbilityData.EffectType.BLADE_BEAM:
				has_blade_beam = true
			AbilityData.EffectType.BLOOD_MONEY:
				has_blood_money = true
				blood_money_heal += value
			AbilityData.EffectType.DIVINE_SHIELD:
				has_divine_shield = true
				divine_shield_duration = maxf(divine_shield_duration, value)
			AbilityData.EffectType.RICOCHET:
				has_ricochet = true
				ricochet_bounces += int(value)
			AbilityData.EffectType.PHOENIX:
				has_phoenix = true
				phoenix_hp_percent = value
			AbilityData.EffectType.BOOMERANG:
				has_boomerang = true

	# Apply stat changes to player immediately
	apply_stats_to_player()

func apply_stats_to_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Update player stats based on modifiers
	if player.has_method("update_ability_stats"):
		player.update_ability_stats(stat_modifiers)

func spawn_orbital() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var orbital_scene = load("res://scenes/abilities/orbital.tscn")
	if orbital_scene:
		var orbital = orbital_scene.instantiate()
		orbital.orbit_index = orbital_count - 1
		player.add_child(orbital)

func spawn_toxic_aura() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Check if aura already exists
	if player.has_node("ToxicAura"):
		return

	var aura_scene = load("res://scenes/abilities/toxic_aura.tscn")
	if aura_scene:
		var aura = aura_scene.instantiate()
		aura.name = "ToxicAura"
		player.add_child(aura)

func spawn_drone() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var drone_scene = load("res://scenes/abilities/drone.tscn")
	if drone_scene:
		var drone = drone_scene.instantiate()
		drone.drone_index = drone_count - 1
		player.get_parent().add_child(drone)

# Utility functions for other scripts
func get_damage_multiplier() -> float:
	var base = 1.0 + stat_modifiers["damage"]

	# Add permanent upgrade bonus
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("damage", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("damage")

	return base

func get_attack_speed_multiplier() -> float:
	var base = 1.0 + stat_modifiers["attack_speed"]

	# Frenzy bonus when low HP
	if has_frenzy:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.current_health / player.max_health < 0.3:
			base += frenzy_boost

	# Add equipment bonus
	base += _get_equipment_stat("attack_speed")

	return base

func get_xp_multiplier() -> float:
	var base = 1.0 + stat_modifiers["xp_gain"]

	# Add permanent upgrade bonus
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("xp_gain", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("xp_gain")

	return base

func get_move_speed_multiplier() -> float:
	var base = 1.0 + stat_modifiers["move_speed"]

	# Add equipment bonus
	base += _get_equipment_stat("move_speed")

	return base

func should_double_xp() -> bool:
	return has_double_xp_chance and randf() < double_xp_chance

func check_cull_weak(enemy: Node2D) -> bool:
	if not has_cull_weak:
		return false

	var health_percent = enemy.current_health / enemy.max_health
	return health_percent <= cull_threshold

# Get total projectile count including permanent upgrades
func get_total_projectile_count() -> int:
	var count = stat_modifiers.get("projectile_count", 0)

	if PermanentUpgrades:
		count += PermanentUpgrades.get_all_bonuses().get("projectile_count", 0)

	return count

# Get total projectile speed multiplier including permanent upgrades and character passive
func get_projectile_speed_multiplier() -> float:
	var base = 1.0 + stat_modifiers.get("projectile_speed", 0.0)

	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("projectile_speed", 0.0)

	# Add character passive bonus (Archer's Eagle Eye)
	if CharacterManager:
		base += CharacterManager.get_passive_bonuses().get("projectile_speed", 0.0)

	return base

# Get total crit chance including permanent upgrades and character passive
func get_crit_chance() -> float:
	var base = stat_modifiers.get("crit_chance", 0.0)

	# Add character base crit rate
	if CharacterManager:
		base += CharacterManager.get_base_combat_stats().get("crit_rate", 0.0)

	# Add permanent upgrade crit chance
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("crit_chance", 0.0)
		base += PermanentUpgrades.get_all_bonuses().get("luck", 0.0)

	# Add character passive bonus (Archer's Eagle Eye)
	if CharacterManager:
		base += CharacterManager.get_passive_bonuses().get("crit_chance", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("crit_chance")

	return base

# Get total block chance including character base, permanent upgrades
func get_block_chance() -> float:
	var base = 0.0

	# Add character base block rate
	if CharacterManager:
		base += CharacterManager.get_base_combat_stats().get("block_rate", 0.0)

	# Add permanent upgrade block chance
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("block_chance", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("block_chance")

	return base

# Get total dodge chance including character base, permanent upgrades
func get_dodge_chance() -> float:
	var base = 0.0

	# Add character base dodge rate
	if CharacterManager:
		base += CharacterManager.get_base_combat_stats().get("dodge_rate", 0.0)

	# Add permanent upgrade dodge chance
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("dodge_chance", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("dodge_chance")

	return base

# Get crit damage multiplier from permanent upgrades
func get_crit_damage_multiplier() -> float:
	var base = 2.0  # Default crit is 2x damage

	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("crit_damage", 0.0)

	return base

# Get luck multiplier for drops
func get_luck_multiplier() -> float:
	var base = 1.0 + stat_modifiers.get("luck", 0.0)

	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("luck", 0.0)

	return base

# Get regen rate including permanent upgrades
func get_regen_rate() -> float:
	var base = regen_rate

	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("hp_regen", 0.0)

	return base

# Check if player has permanent regen
func has_permanent_regen() -> bool:
	if PermanentUpgrades:
		return PermanentUpgrades.get_all_bonuses().get("hp_regen", 0.0) > 0
	return false

# Melee-specific getters
func get_melee_area_multiplier() -> float:
	return 1.0 + stat_modifiers.get("melee_area", 0.0) + _get_equipment_stat("melee_area")

func get_melee_range_multiplier() -> float:
	return 1.0 + stat_modifiers.get("melee_range", 0.0) + _get_equipment_stat("melee_range")

# Get max HP bonus from equipment
func get_equipment_max_hp_bonus() -> float:
	return _get_equipment_stat("max_hp")

# Get damage reduction from equipment
func get_equipment_damage_reduction() -> float:
	return _get_equipment_stat("damage_reduction")

# Helper to get equipment stat for current character
func _get_equipment_stat(stat: String) -> float:
	if not EquipmentManager:
		return 0.0
	if not CharacterManager:
		return 0.0

	var character_id = CharacterManager.selected_character_id
	var equipment_stats = EquipmentManager.get_equipment_stats(character_id)
	return equipment_stats.get(stat, 0.0)

# Apply equipment abilities at start of run
func apply_equipment_abilities() -> void:
	if not EquipmentManager or not CharacterManager:
		return

	var character_id = CharacterManager.selected_character_id
	var abilities = EquipmentManager.get_equipment_abilities(character_id)

	for ability_id in abilities:
		# Find ability in database and apply its effects
		for ability in all_abilities:
			if ability.id == ability_id:
				apply_ability_effects(ability)
				break

# Check if player has a specific equipment-exclusive ability
func has_equipment_ability(ability_id: String) -> bool:
	if not EquipmentManager or not CharacterManager:
		return false

	var character_id = CharacterManager.selected_character_id
	var abilities = EquipmentManager.get_equipment_exclusive_abilities(character_id)
	return ability_id in abilities

# ============================================
# NEW ABILITY UTILITY FUNCTIONS
# ============================================

# Get armor (flat damage reduction)
func get_armor() -> float:
	return armor

# Get coin gain multiplier
func get_coin_gain_multiplier() -> float:
	return 1.0 + coin_gain_bonus

# Get momentum damage bonus based on player velocity
func get_momentum_damage_bonus(player_velocity: Vector2) -> float:
	if not has_momentum:
		return 0.0
	var speed_ratio = clampf(player_velocity.length() / 300.0, 0.0, 1.0)  # Normalized to 300 speed
	return momentum_bonus * speed_ratio

# Get melee knockback force
func get_melee_knockback() -> float:
	return melee_knockback

# Trigger retribution explosion when player takes damage
func trigger_retribution(player_pos: Vector2) -> void:
	if not has_retribution:
		return
	var enemies = get_tree().get_nodes_in_group("enemies")
	var explosion_radius = 100.0
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player_pos.distance_to(enemy.global_position)
			if dist <= explosion_radius and enemy.has_method("take_damage"):
				enemy.take_damage(retribution_damage)
	spawn_explosion_effect(player_pos)

# Get time dilation slow factor for enemies
func get_time_dilation_slow() -> float:
	return time_dilation_slow

# Get giant slayer damage bonus
func get_giant_slayer_bonus(enemy_hp_percent: float) -> float:
	if not has_giant_slayer:
		return 0.0
	if enemy_hp_percent > 0.8:
		return giant_slayer_bonus
	return 0.0

# Get total crit chance including backstab
func get_total_crit_chance() -> float:
	var base = get_crit_chance()
	if has_backstab:
		base += backstab_crit_bonus
	return base

# Check if parry blocks damage
func check_parry() -> bool:
	if not has_parry:
		return false
	return randf() < parry_chance

# Check if seismic slam stuns
func check_seismic_stun() -> bool:
	if not has_seismic_slam:
		return false
	return randf() < seismic_stun_chance

# Apply bloodthirst attack speed boost on kill
func apply_bloodthirst_boost(player: Node2D) -> void:
	if not has_bloodthirst:
		return
	if player.has_method("apply_temporary_attack_speed_boost"):
		player.apply_temporary_attack_speed_boost(bloodthirst_boost, 3.0)

# Check if double tap triggers
func check_double_tap() -> bool:
	if not has_double_tap:
		return false
	return randf() < double_tap_chance

# Get point blank damage bonus
func get_point_blank_bonus(distance: float) -> float:
	if not has_point_blank:
		return 0.0
	if distance < 100.0:  # Close range threshold
		return point_blank_bonus
	return 0.0

# Check if blade beam should fire
func should_fire_blade_beam() -> bool:
	return has_blade_beam

# Called when player picks up a coin
func on_coin_pickup(player: Node2D) -> void:
	if has_blood_money:
		heal_player(player, blood_money_heal)

# Trigger divine shield invulnerability
func trigger_divine_shield() -> void:
	if has_divine_shield and not divine_shield_active:
		divine_shield_active = true
		divine_shield_timer = divine_shield_duration

# Check if player is currently invulnerable from divine shield
func is_divine_shield_active() -> bool:
	return divine_shield_active

# Get ricochet bounce count
func get_ricochet_bounces() -> int:
	return ricochet_bounces

# Check and trigger phoenix revive
func try_phoenix_revive(player: Node2D) -> bool:
	if not has_phoenix or phoenix_used:
		return false
	phoenix_used = true
	if player.has_method("revive_with_percent"):
		player.revive_with_percent(phoenix_hp_percent)
	# Trigger explosion on revive
	trigger_phoenix_explosion(player.global_position)
	return true

func trigger_phoenix_explosion(pos: Vector2) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var explosion_radius = 150.0
	var explosion_damage = 50.0
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = pos.distance_to(enemy.global_position)
			if dist <= explosion_radius and enemy.has_method("take_damage"):
				enemy.take_damage(explosion_damage)
	spawn_explosion_effect(pos)

# Check if projectiles should boomerang
func should_boomerang() -> bool:
	return has_boomerang

# Called when enemy dies - handle bloodthirst
func on_enemy_killed(enemy: Node2D, player: Node2D) -> void:
	# Vampirism
	if has_vampirism and randf() < vampirism_chance:
		heal_player(player, 1.0)

	# Adrenaline
	if has_adrenaline:
		apply_adrenaline_buff(player)

	# Death Detonation
	if has_death_explosion:
		trigger_death_explosion(enemy)

	# Bloodthirst
	if has_bloodthirst:
		apply_bloodthirst_boost(player)
