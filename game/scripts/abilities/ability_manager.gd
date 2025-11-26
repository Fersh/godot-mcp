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

# ============================================
# EXTENDED ABILITY EFFECTS (from modular files)
# ============================================

# Elemental on-hit effects
var has_ignite: bool = false
var ignite_chance: float = 0.0
var has_frostbite: bool = false
var frostbite_chance: float = 0.0
var has_toxic_tip: bool = false
var toxic_tip_chance: float = 0.0
var has_lightning_proc: bool = false
var lightning_proc_chance: float = 0.0
var has_chaotic_strikes: bool = false
var chaotic_bonus: float = 0.0
var has_static_charge: bool = false
var static_charge_interval: float = 5.0
var static_charge_timer: float = 0.0
var static_charge_ready: bool = false
var has_chain_reaction: bool = false
var chain_reaction_count: int = 0

# Combat mechanics
var has_berserker_fury: bool = false
var berserker_fury_bonus: float = 0.0
var berserker_fury_stacks: int = 0
var berserker_fury_timer: float = 0.0
var has_combat_momentum: bool = false
var combat_momentum_bonus: float = 0.0
var combat_momentum_target: Node2D = null
var combat_momentum_stacks: int = 0
var has_executioner: bool = false
var executioner_bonus: float = 0.0
var has_vengeance: bool = false
var vengeance_bonus: float = 0.0
var vengeance_active: bool = false
var vengeance_timer: float = 0.0
var has_last_resort: bool = false
var last_resort_bonus: float = 0.0
var has_horde_breaker: bool = false
var horde_breaker_bonus: float = 0.0
var has_arcane_absorption: bool = false
var arcane_absorption_value: float = 0.0
var has_adrenaline_rush: bool = false
var has_phalanx: bool = false
var phalanx_chance: float = 0.0
var has_homing: bool = false

# Defensive effects
var has_guardian_heart: bool = false
var guardian_heart_bonus: float = 0.0
var has_overheal_shield: bool = false
var overheal_shield_max: float = 0.0
var current_overheal_shield: float = 0.0
var has_mirror_image: bool = false
var mirror_image_chance: float = 0.0
var has_battle_medic: bool = false
var battle_medic_heal: float = 0.0
var has_mirror_shield: bool = false
var mirror_shield_interval: float = 5.0
var mirror_shield_timer: float = 0.0
var mirror_shield_ready: bool = false
var has_thundershock: bool = false
var thundershock_damage: float = 0.0

# Conditional effects
var has_warmup: bool = false
var warmup_bonus: float = 0.0
var warmup_active: bool = true
var has_practiced_stance: bool = false
var practiced_stance_bonus: float = 0.0
var has_early_bird: bool = false
var early_bird_bonus: float = 0.0

# Legendary effects
var has_ceremonial_dagger: bool = false
var ceremonial_dagger_count: int = 0
var has_missile_barrage: bool = false
var missile_barrage_chance: float = 0.0
var has_soul_reaper: bool = false
var soul_reaper_heal: float = 0.0
var soul_reaper_stacks: int = 0
var soul_reaper_timer: float = 0.0
var has_summoner: bool = false
var summoner_interval: float = 10.0
var summoner_timer: float = 0.0
var skeleton_count: int = 0
const MAX_SKELETONS: int = 3
var has_mind_control: bool = false
var mind_control_chance: float = 0.0
var has_blood_debt: bool = false
var blood_debt_bonus: float = 0.0
var has_chrono_trigger: bool = false
var chrono_trigger_interval: float = 10.0
var chrono_trigger_timer: float = 0.0
var has_unlimited_power: bool = false
var unlimited_power_bonus: float = 0.0
var unlimited_power_stacks: int = 0
var has_wind_dancer: bool = false
var has_empathic_bond: bool = false
var empathic_bond_multiplier: float = 1.0
var has_fortune_favor: bool = false

# Mythic effects
var has_immortal_oath: bool = false
var immortal_oath_duration: float = 3.0
var immortal_oath_active: bool = false
var immortal_oath_timer: float = 0.0
var immortal_oath_used: bool = false
var has_all_for_one: bool = false
var all_for_one_multiplier: float = 2.0
var has_transcendence: bool = false
var transcendence_shields: float = 0.0
var transcendence_max: float = 0.0
var has_symbiosis: bool = false
var has_pandemonium: bool = false
var pandemonium_multiplier: float = 2.0

# Run tracking
var run_start_time: float = 0.0
var run_duration_for_warmup: float = 120.0  # 2 minutes

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

	# Reset extended ability effects
	has_ignite = false
	ignite_chance = 0.0
	has_frostbite = false
	frostbite_chance = 0.0
	has_toxic_tip = false
	toxic_tip_chance = 0.0
	has_lightning_proc = false
	lightning_proc_chance = 0.0
	has_chaotic_strikes = false
	chaotic_bonus = 0.0
	has_static_charge = false
	static_charge_timer = 0.0
	static_charge_ready = false
	has_chain_reaction = false
	chain_reaction_count = 0

	has_berserker_fury = false
	berserker_fury_bonus = 0.0
	berserker_fury_stacks = 0
	berserker_fury_timer = 0.0
	has_combat_momentum = false
	combat_momentum_bonus = 0.0
	combat_momentum_target = null
	combat_momentum_stacks = 0
	has_executioner = false
	executioner_bonus = 0.0
	has_vengeance = false
	vengeance_bonus = 0.0
	vengeance_active = false
	vengeance_timer = 0.0
	has_last_resort = false
	last_resort_bonus = 0.0
	has_horde_breaker = false
	horde_breaker_bonus = 0.0
	has_arcane_absorption = false
	arcane_absorption_value = 0.0
	has_adrenaline_rush = false
	has_phalanx = false
	phalanx_chance = 0.0
	has_homing = false

	has_guardian_heart = false
	guardian_heart_bonus = 0.0
	has_overheal_shield = false
	overheal_shield_max = 0.0
	current_overheal_shield = 0.0
	has_mirror_image = false
	mirror_image_chance = 0.0
	has_battle_medic = false
	battle_medic_heal = 0.0
	has_mirror_shield = false
	mirror_shield_timer = 0.0
	mirror_shield_ready = false
	has_thundershock = false
	thundershock_damage = 0.0

	has_warmup = false
	warmup_bonus = 0.0
	warmup_active = true
	has_practiced_stance = false
	practiced_stance_bonus = 0.0
	has_early_bird = false
	early_bird_bonus = 0.0

	has_ceremonial_dagger = false
	ceremonial_dagger_count = 0
	has_missile_barrage = false
	missile_barrage_chance = 0.0
	has_soul_reaper = false
	soul_reaper_heal = 0.0
	soul_reaper_stacks = 0
	soul_reaper_timer = 0.0
	has_summoner = false
	summoner_timer = 0.0
	skeleton_count = 0
	has_mind_control = false
	mind_control_chance = 0.0
	has_blood_debt = false
	blood_debt_bonus = 0.0
	has_chrono_trigger = false
	chrono_trigger_timer = 0.0
	has_unlimited_power = false
	unlimited_power_bonus = 0.0
	unlimited_power_stacks = 0
	has_wind_dancer = false
	has_empathic_bond = false
	empathic_bond_multiplier = 1.0
	has_fortune_favor = false

	has_immortal_oath = false
	immortal_oath_active = false
	immortal_oath_timer = 0.0
	immortal_oath_used = false
	has_all_for_one = false
	has_transcendence = false
	transcendence_shields = 0.0
	transcendence_max = 0.0
	has_symbiosis = false
	has_pandemonium = false
	pandemonium_multiplier = 2.0

	run_start_time = 0.0

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
	# Regeneration (from abilities and permanent upgrades) - percentage based
	var total_regen = get_regen_rate()
	if total_regen > 0 or has_regen or has_permanent_regen():
		regen_timer += delta
		if regen_timer >= 1.0:
			regen_timer = 0.0
			# Heal as percentage of max HP (0.2 rate = 0.2% per second = 1% every 5 seconds)
			heal_player(player, player.max_health * total_regen * 0.01)

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

	# ============================================
	# EXTENDED PERIODIC EFFECTS
	# ============================================

	# Static Charge timer (recharges stun)
	if has_static_charge:
		static_charge_timer += delta
		if static_charge_timer >= static_charge_interval:
			static_charge_timer = 0.0
			static_charge_ready = true

	# Berserker Fury decay
	if has_berserker_fury and berserker_fury_stacks > 0:
		berserker_fury_timer -= delta
		if berserker_fury_timer <= 0:
			berserker_fury_stacks = 0

	# Vengeance window
	if vengeance_active:
		vengeance_timer -= delta
		if vengeance_timer <= 0:
			vengeance_active = false

	# Soul Reaper stack decay
	if has_soul_reaper and soul_reaper_stacks > 0:
		soul_reaper_timer -= delta
		if soul_reaper_timer <= 0:
			soul_reaper_stacks = 0

	# Warmup check (expires after 2 minutes)
	if has_warmup and warmup_active:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - run_start_time > run_duration_for_warmup:
			warmup_active = false

	# Summoner's Aid - spawn skeletons periodically
	if has_summoner:
		summoner_timer += delta
		if summoner_timer >= summoner_interval and skeleton_count < MAX_SKELETONS:
			summoner_timer = 0.0
			spawn_skeleton(player)

	# Chrono Trigger - periodic freeze
	if has_chrono_trigger:
		chrono_trigger_timer += delta
		if chrono_trigger_timer >= chrono_trigger_interval:
			chrono_trigger_timer = 0.0
			trigger_chrono_freeze()

	# Mirror Shield recharge
	if has_mirror_shield:
		mirror_shield_timer += delta
		if mirror_shield_timer >= mirror_shield_interval:
			mirror_shield_timer = 0.0
			mirror_shield_ready = true

	# Immortal Oath timer
	if immortal_oath_active:
		immortal_oath_timer -= delta
		if immortal_oath_timer <= 0:
			immortal_oath_active = false
			# If player didn't heal above 1 HP, they die
			if player.has_method("get_health") and player.get_health() <= 1:
				if player.has_method("force_death"):
					player.force_death()

	# Transcendence shield regen
	if has_transcendence and transcendence_shields < transcendence_max:
		transcendence_shields = minf(transcendence_shields + delta * 5.0, transcendence_max)

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

	# Filter to only enemies visible on screen
	var viewport_rect = get_viewport().get_visible_rect()
	var camera = get_viewport().get_camera_2d()
	var visible_enemies: Array = []

	for enemy in enemies:
		if is_instance_valid(enemy):
			var screen_pos = enemy.global_position
			if camera:
				# Convert to screen-relative position
				var cam_pos = camera.global_position
				var half_size = viewport_rect.size / 2
				if abs(screen_pos.x - cam_pos.x) < half_size.x and abs(screen_pos.y - cam_pos.y) < half_size.y:
					visible_enemies.append(enemy)
			else:
				# No camera, just check viewport bounds
				if viewport_rect.has_point(screen_pos):
					visible_enemies.append(enemy)

	if visible_enemies.size() == 0:
		return

	var target = visible_enemies[randi() % visible_enemies.size()]
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
	# Visual effect for lightning strike using sprite animation
	var lightning_scene = load("res://scenes/effects/ability_effects/lightning.tscn")
	if lightning_scene:
		var lightning = lightning_scene.instantiate()
		lightning.global_position = pos
		get_tree().current_scene.add_child(lightning)
	else:
		# Fallback to simple line effect
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

			# ============================================
			# EXTENDED ABILITY EFFECTS (from modular files)
			# ============================================

			# Elemental on-hit effects
			AbilityData.EffectType.IGNITE:
				has_ignite = true
				ignite_chance += value
			AbilityData.EffectType.FROSTBITE:
				has_frostbite = true
				frostbite_chance += value
			AbilityData.EffectType.TOXIC_TIP:
				has_toxic_tip = true
				toxic_tip_chance += value
			AbilityData.EffectType.LIGHTNING_PROC:
				has_lightning_proc = true
				lightning_proc_chance += value
			AbilityData.EffectType.CHAOTIC_STRIKES:
				has_chaotic_strikes = true
				chaotic_bonus += value
			AbilityData.EffectType.STATIC_CHARGE:
				has_static_charge = true
				static_charge_interval = value
			AbilityData.EffectType.CHAIN_REACTION:
				has_chain_reaction = true
				chain_reaction_count = int(value)

			# Combat mechanics
			AbilityData.EffectType.BERSERKER_FURY:
				has_berserker_fury = true
				berserker_fury_bonus += value
			AbilityData.EffectType.COMBAT_MOMENTUM:
				has_combat_momentum = true
				combat_momentum_bonus += value
			AbilityData.EffectType.EXECUTIONER:
				has_executioner = true
				executioner_bonus += value
			AbilityData.EffectType.VENGEANCE:
				has_vengeance = true
				vengeance_bonus += value
			AbilityData.EffectType.LAST_RESORT:
				has_last_resort = true
				last_resort_bonus += value
			AbilityData.EffectType.HORDE_BREAKER:
				has_horde_breaker = true
				horde_breaker_bonus += value
			AbilityData.EffectType.ARCANE_ABSORPTION:
				has_arcane_absorption = true
				arcane_absorption_value += value
			AbilityData.EffectType.ADRENALINE_RUSH:
				has_adrenaline_rush = true
			AbilityData.EffectType.PHALANX:
				has_phalanx = true
				phalanx_chance += value
			AbilityData.EffectType.HOMING:
				has_homing = true

			# Defensive effects
			AbilityData.EffectType.GUARDIAN_HEART:
				has_guardian_heart = true
				guardian_heart_bonus += value
			AbilityData.EffectType.OVERHEAL_SHIELD:
				has_overheal_shield = true
				overheal_shield_max = value
			AbilityData.EffectType.MIRROR_IMAGE:
				has_mirror_image = true
				mirror_image_chance += value
			AbilityData.EffectType.BATTLE_MEDIC:
				has_battle_medic = true
				battle_medic_heal += value
			AbilityData.EffectType.MIRROR_SHIELD:
				has_mirror_shield = true
				mirror_shield_interval = value
			AbilityData.EffectType.THUNDERSHOCK:
				has_thundershock = true
				thundershock_damage += value

			# Conditional effects
			AbilityData.EffectType.WARMUP:
				has_warmup = true
				warmup_bonus += value
				run_start_time = Time.get_ticks_msec() / 1000.0
			AbilityData.EffectType.PRACTICED_STANCE:
				has_practiced_stance = true
				practiced_stance_bonus += value
			AbilityData.EffectType.EARLY_BIRD:
				has_early_bird = true
				early_bird_bonus += value
				run_start_time = Time.get_ticks_msec() / 1000.0

			# Legendary effects
			AbilityData.EffectType.CEREMONIAL_DAGGER:
				has_ceremonial_dagger = true
				ceremonial_dagger_count = int(value)
			AbilityData.EffectType.MISSILE_BARRAGE:
				has_missile_barrage = true
				missile_barrage_chance += value
			AbilityData.EffectType.SOUL_REAPER:
				has_soul_reaper = true
				soul_reaper_heal += value
			AbilityData.EffectType.SUMMONER:
				has_summoner = true
				summoner_interval = value
			AbilityData.EffectType.MIND_CONTROL:
				has_mind_control = true
				mind_control_chance += value
			AbilityData.EffectType.BLOOD_DEBT:
				has_blood_debt = true
				blood_debt_bonus += value
			AbilityData.EffectType.CHRONO_TRIGGER:
				has_chrono_trigger = true
				chrono_trigger_interval = value
			AbilityData.EffectType.UNLIMITED_POWER:
				has_unlimited_power = true
				unlimited_power_bonus += value
			AbilityData.EffectType.WIND_DANCER:
				has_wind_dancer = true
			AbilityData.EffectType.EMPATHIC_BOND:
				has_empathic_bond = true
				empathic_bond_multiplier = value
			AbilityData.EffectType.FORTUNE_FAVOR:
				has_fortune_favor = true

			# Mythic effects
			AbilityData.EffectType.IMMORTAL_OATH:
				has_immortal_oath = true
				immortal_oath_duration = value
			AbilityData.EffectType.ALL_FOR_ONE:
				has_all_for_one = true
				all_for_one_multiplier = value
			AbilityData.EffectType.TRANSCENDENCE:
				has_transcendence = true
				activate_transcendence()
			AbilityData.EffectType.SYMBIOSIS:
				has_symbiosis = true
			AbilityData.EffectType.PANDEMONIUM:
				has_pandemonium = true
				pandemonium_multiplier = value

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
		heal_player(player, player.max_health * 0.01)

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
		heal_player(player, player.max_health * 0.01)

	# Adrenaline
	if has_adrenaline:
		apply_adrenaline_buff(player)

	# Death Detonation
	if has_death_explosion:
		trigger_death_explosion(enemy)

	# Bloodthirst
	if has_bloodthirst:
		apply_bloodthirst_boost(player)

	# ============================================
	# EXTENDED ON-KILL EFFECTS
	# ============================================

	# Ceremonial Dagger - fire homing daggers
	if has_ceremonial_dagger:
		fire_ceremonial_daggers(enemy.global_position, player)

	# Soul Reaper - heal and stack damage
	if has_soul_reaper:
		var heal_amount = player.max_health * soul_reaper_heal
		heal_player(player, heal_amount)
		soul_reaper_stacks = mini(soul_reaper_stacks + 1, 50)  # Cap at 50 stacks
		soul_reaper_timer = 5.0

	# Unlimited Power - permanent stacking damage
	if has_unlimited_power:
		unlimited_power_stacks += 1

	# Arcane Absorption - reduce cooldowns
	if has_arcane_absorption:
		reduce_active_cooldowns(arcane_absorption_value)

	# Chain Reaction - spread status effects
	if has_chain_reaction:
		spread_status_effects(enemy)

	# Adrenaline Rush (melee dash on kill)
	if has_adrenaline_rush:
		trigger_adrenaline_dash(player, enemy.global_position)

# ============================================
# EXTENDED ABILITY UTILITY FUNCTIONS
# ============================================

# Elemental on-hit checks
func check_ignite() -> bool:
	return has_ignite and randf() < ignite_chance

func check_frostbite() -> bool:
	return has_frostbite and randf() < frostbite_chance

func check_toxic_tip() -> bool:
	return has_toxic_tip and randf() < toxic_tip_chance

func check_lightning_proc() -> bool:
	return has_lightning_proc and randf() < lightning_proc_chance

func get_chaotic_element() -> String:
	if not has_chaotic_strikes:
		return ""
	var elements = ["fire", "ice", "lightning"]
	return elements[randi() % elements.size()]

func consume_static_charge() -> bool:
	if has_static_charge and static_charge_ready:
		static_charge_ready = false
		return true
	return false

# Combat mechanics
func trigger_berserker_fury() -> void:
	if has_berserker_fury:
		berserker_fury_stacks = mini(berserker_fury_stacks + 1, 5)  # Max 5 stacks
		berserker_fury_timer = 5.0

func get_berserker_fury_bonus() -> float:
	if not has_berserker_fury:
		return 0.0
	return berserker_fury_bonus * berserker_fury_stacks

func update_combat_momentum(target: Node2D) -> void:
	if not has_combat_momentum:
		return
	if combat_momentum_target == target:
		combat_momentum_stacks = mini(combat_momentum_stacks + 1, 5)
	else:
		combat_momentum_target = target
		combat_momentum_stacks = 1

func get_combat_momentum_bonus() -> float:
	if not has_combat_momentum:
		return 0.0
	return combat_momentum_bonus * combat_momentum_stacks

func get_executioner_bonus(enemy_hp_percent: float) -> float:
	if not has_executioner or enemy_hp_percent > 0.3:
		return 0.0
	return executioner_bonus

func trigger_vengeance() -> void:
	if has_vengeance:
		vengeance_active = true
		vengeance_timer = 3.0

func consume_vengeance() -> float:
	if vengeance_active:
		vengeance_active = false
		return vengeance_bonus
	return 0.0

func get_last_resort_bonus(hp_percent: float) -> float:
	if not has_last_resort or hp_percent > 0.1:
		return 0.0
	return last_resort_bonus

func get_horde_breaker_bonus(player_pos: Vector2) -> float:
	if not has_horde_breaker:
		return 0.0
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearby_count = 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			if player_pos.distance_to(enemy.global_position) < 160.0:  # ~5 tiles
				nearby_count += 1
	return minf(horde_breaker_bonus * nearby_count, 0.2)  # Cap at 20%

func check_phalanx(projectile_direction: Vector2, player_facing: Vector2) -> bool:
	if not has_phalanx:
		return false
	# Check if projectile is coming from the front
	if projectile_direction.dot(player_facing) < -0.5:
		return randf() < phalanx_chance
	return false

func check_missile_barrage() -> bool:
	return has_missile_barrage and randf() < missile_barrage_chance

func check_mind_control() -> bool:
	return has_mind_control and randf() < mind_control_chance

# Defensive utilities
func get_healing_multiplier() -> float:
	if has_guardian_heart:
		return 1.0 + guardian_heart_bonus
	return 1.0

func process_overheal(player: Node2D, heal_amount: float) -> float:
	if not has_overheal_shield:
		return heal_amount

	var current_hp = player.current_health if player.has_method("get_health") else 0.0
	var max_hp = player.max_health if "max_health" in player else 100.0
	var overflow = (current_hp + heal_amount) - max_hp

	if overflow > 0:
		var max_shield = max_hp * overheal_shield_max
		current_overheal_shield = minf(current_overheal_shield + overflow, max_shield)
		return heal_amount - overflow
	return heal_amount

func get_overheal_shield() -> float:
	return current_overheal_shield

func damage_overheal_shield(damage: float) -> float:
	if current_overheal_shield <= 0:
		return damage
	var absorbed = minf(damage, current_overheal_shield)
	current_overheal_shield -= absorbed
	return damage - absorbed

func check_mirror_image() -> bool:
	return has_mirror_image and randf() < mirror_image_chance

func consume_mirror_shield() -> bool:
	if has_mirror_shield and mirror_shield_ready:
		mirror_shield_ready = false
		return true
	return false

func trigger_thundershock(player_pos: Vector2) -> void:
	if not has_thundershock:
		return
	var enemies = get_tree().get_nodes_in_group("enemies")
	var targets_hit = 0
	for enemy in enemies:
		if targets_hit >= 3:
			break
		if is_instance_valid(enemy):
			var dist = player_pos.distance_to(enemy.global_position)
			if dist <= 200.0 and enemy.has_method("take_damage"):
				enemy.take_damage(thundershock_damage)
				spawn_lightning_effect(player_pos, enemy.global_position)
				targets_hit += 1

func trigger_battle_medic(player: Node2D) -> void:
	if not has_battle_medic:
		return
	# Heal nova around player
	heal_player(player, battle_medic_heal)
	# Damage nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist <= 80.0 and enemy.has_method("take_damage"):
				enemy.take_damage(battle_medic_heal)
	spawn_explosion_effect(player.global_position)

# Conditional effect getters
func get_warmup_attack_speed_bonus() -> float:
	if has_warmup and warmup_active:
		return warmup_bonus
	return 0.0

func get_practiced_stance_bonus(player_velocity: Vector2) -> float:
	if not has_practiced_stance:
		return 0.0
	if player_velocity.length() < 5.0:
		return practiced_stance_bonus
	return 0.0

func get_early_bird_xp_multiplier() -> float:
	if not has_early_bird:
		return 0.0
	var current_time = Time.get_ticks_msec() / 1000.0
	var run_time = current_time - run_start_time
	# Assume run duration is ~10 minutes, so halfway is 5 minutes
	if run_time < 300.0:  # First 5 minutes
		return early_bird_bonus
	else:
		return -early_bird_bonus

# Legendary effect functions
func fire_ceremonial_daggers(origin: Vector2, player: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var targets: Array = []

	for enemy in enemies:
		if is_instance_valid(enemy) and targets.size() < ceremonial_dagger_count:
			targets.append(enemy)

	for target in targets:
		spawn_homing_projectile(origin, target, player)

func spawn_homing_projectile(origin: Vector2, target: Node2D, player: Node2D) -> void:
	# Create a simple homing projectile
	var projectile = Node2D.new()
	projectile.global_position = origin
	projectile.set_script(load("res://scripts/abilities/homing_projectile.gd"))
	projectile.target = target
	projectile.damage = get_damage_multiplier() * 20.0  # Base damage
	projectile.source = player
	get_tree().current_scene.add_child(projectile)

func fire_homing_missiles(origin: Vector2, player: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return

	for i in 2:
		var target = enemies[randi() % enemies.size()]
		if is_instance_valid(target):
			spawn_homing_projectile(origin, target, player)

func spawn_skeleton(player: Node2D) -> void:
	skeleton_count += 1
	var skeleton = Node2D.new()
	skeleton.global_position = player.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	skeleton.set_script(load("res://scripts/abilities/skeleton_minion.gd"))
	skeleton.owner_player = player
	skeleton.tree_exited.connect(func(): skeleton_count -= 1)
	get_tree().current_scene.add_child(skeleton)

func trigger_chrono_freeze() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("apply_freeze"):
			enemy.apply_freeze(1.0)
		elif is_instance_valid(enemy) and enemy.has_method("apply_stun"):
			enemy.apply_stun(1.0)

func get_soul_reaper_damage_bonus() -> float:
	if not has_soul_reaper:
		return 0.0
	return 0.01 * soul_reaper_stacks  # 1% per stack

func get_unlimited_power_bonus() -> float:
	if not has_unlimited_power:
		return 0.0
	return unlimited_power_bonus * unlimited_power_stacks

func reduce_active_cooldowns(amount: float) -> void:
	# Signal to active ability system to reduce cooldowns
	var active_manager = get_tree().get_first_node_in_group("active_ability_manager")
	if active_manager and active_manager.has_method("reduce_all_cooldowns"):
		active_manager.reduce_all_cooldowns(amount)

func spread_status_effects(dead_enemy: Node2D) -> void:
	if not has_chain_reaction:
		return
	# Find nearby enemies to spread effects to
	var enemies = get_tree().get_nodes_in_group("enemies")
	var spread_count = 0
	for enemy in enemies:
		if spread_count >= chain_reaction_count:
			break
		if enemy == dead_enemy or not is_instance_valid(enemy):
			continue
		var dist = dead_enemy.global_position.distance_to(enemy.global_position)
		if dist <= 100.0:
			# Apply a random status effect
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(3.0)
			elif enemy.has_method("apply_poison"):
				enemy.apply_poison(50.0, 5.0)
			spread_count += 1

func trigger_adrenaline_dash(player: Node2D, target_pos: Vector2) -> void:
	if not has_adrenaline_rush:
		return
	# Find nearest enemy to dash toward
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist = 200.0

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	if closest and player.has_method("dash_toward"):
		player.dash_toward(closest.global_position)

func spawn_decoy(player: Node2D) -> void:
	var decoy = Node2D.new()
	decoy.global_position = player.global_position
	decoy.set_script(load("res://scripts/abilities/decoy.gd"))
	decoy.owner_player = player
	get_tree().current_scene.add_child(decoy)

func get_blood_debt_damage_bonus() -> float:
	if has_blood_debt:
		return blood_debt_bonus
	return 0.0

func apply_blood_debt_self_damage(player: Node2D, damage_dealt: float) -> void:
	if not has_blood_debt:
		return
	var self_damage = damage_dealt * 0.1
	if player.has_method("take_damage_no_callback"):
		player.take_damage_no_callback(self_damage)

func has_wind_dancer_ability() -> bool:
	return has_wind_dancer

func get_empathic_bond_multiplier() -> float:
	return empathic_bond_multiplier

func has_fortune_favor_ability() -> bool:
	return has_fortune_favor

# Mythic effect functions
func try_immortal_oath(player: Node2D) -> bool:
	if not has_immortal_oath or immortal_oath_used:
		return false
	immortal_oath_used = true
	immortal_oath_active = true
	immortal_oath_timer = immortal_oath_duration
	# Make player temporarily invulnerable
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true, immortal_oath_duration)
	return true

func has_all_for_one_ability() -> bool:
	return has_all_for_one

func get_all_for_one_cooldown_multiplier() -> float:
	if has_all_for_one:
		return all_for_one_multiplier
	return 1.0

func activate_transcendence() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		transcendence_max = player.max_health
		transcendence_shields = transcendence_max
		# Reduce HP to 1
		if player.has_method("set_health"):
			player.set_health(1)

func get_transcendence_shields() -> float:
	return transcendence_shields

func damage_transcendence_shields(damage: float) -> float:
	if not has_transcendence or transcendence_shields <= 0:
		return damage
	var absorbed = minf(damage, transcendence_shields)
	transcendence_shields -= absorbed
	return damage - absorbed

func has_symbiosis_ability() -> bool:
	return has_symbiosis

func get_symbiosis_choice_count() -> int:
	if has_symbiosis:
		return 2
	return 1

func has_pandemonium_ability() -> bool:
	return has_pandemonium

func get_pandemonium_spawn_multiplier() -> float:
	if has_pandemonium:
		return pandemonium_multiplier
	return 1.0

func get_pandemonium_damage_multiplier() -> float:
	if has_pandemonium:
		return pandemonium_multiplier
	return 1.0

# Projectile helpers
func should_apply_homing() -> bool:
	return has_homing
