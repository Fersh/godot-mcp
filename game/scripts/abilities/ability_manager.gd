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
	# Regeneration
	if has_regen:
		regen_timer += delta
		if regen_timer >= 1.0:
			regen_timer = 0.0
			heal_player(player, regen_rate)

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

func heal_player(player: Node2D, amount: float) -> void:
	if player.has_method("heal"):
		player.heal(amount)
	else:
		# Fallback: directly modify health
		player.current_health = min(player.current_health + amount, player.max_health)
		if player.health_bar:
			player.health_bar.set_health(player.current_health, player.max_health)

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

# Called when an enemy dies - handles on-kill effects
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
		# if ability.type == AbilityData.Type.MELEE_ONLY and is_ranged_character:
		#	continue

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

	for rarity in [AbilityData.Rarity.LEGENDARY, AbilityData.Rarity.RARE, AbilityData.Rarity.COMMON]:
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
		return by_rarity[selected_rarity][randi() % by_rarity[selected_rarity].size()]

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
	return 1.0 + stat_modifiers["damage"]

func get_attack_speed_multiplier() -> float:
	var base = 1.0 + stat_modifiers["attack_speed"]

	# Frenzy bonus when low HP
	if has_frenzy:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.current_health / player.max_health < 0.3:
			base += frenzy_boost

	return base

func get_xp_multiplier() -> float:
	return 1.0 + stat_modifiers["xp_gain"]

func get_move_speed_multiplier() -> float:
	return 1.0 + stat_modifiers["move_speed"]

func should_double_xp() -> bool:
	return has_double_xp_chance and randf() < double_xp_chance

func check_cull_weak(enemy: Node2D) -> bool:
	if not has_cull_weak:
		return false

	var health_percent = enemy.current_health / enemy.max_health
	return health_percent <= cull_threshold
