extends Node

# Singleton for managing all ability-related functionality
# Add to autoload as "AbilityManager"

signal ability_acquired(ability: AbilityData)
signal ability_selection_requested(choices: Array)

var acquired_abilities: Array[AbilityData] = []
var all_abilities: Array[AbilityData] = []

# Passive level tracking for guaranteed upgrades
var passive_selections_since_upgrade: int = 0
const GUARANTEED_UPGRADE_INTERVAL: int = 4  # Guarantee upgrade every 4 passive selections
const SYNERGY_WEIGHT_BOOST: float = 1.5  # 50% weight increase for synergistic abilities

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
var has_double_strike: bool = false

# Level-up bonuses (5% per level)
var level_bonus_damage: float = 0.0  # Accumulated damage bonus from levels

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
var adrenaline_rush_chance: float = 0.35
var has_phalanx: bool = false
var phalanx_chance: float = 0.0
var has_homing: bool = false

# Kill streak effects
var has_rampage: bool = false
var rampage_bonus: float = 0.0
var rampage_stacks: int = 0
var rampage_timer: float = 0.0
const RAMPAGE_DECAY_TIME: float = 4.0
const RAMPAGE_MAX_STACKS: int = 20

var has_killing_frenzy: bool = false
var killing_frenzy_bonus: float = 0.0
var killing_frenzy_stacks: int = 0
var killing_frenzy_timer: float = 0.0
const KILLING_FRENZY_DECAY_TIME: float = 4.0
const KILLING_FRENZY_MAX_STACKS: int = 10  # 10 stacks × 5% = 50% max

var has_massacre: bool = false
var massacre_bonus: float = 0.0
var massacre_stacks: int = 0
var massacre_timer: float = 0.0
const MASSACRE_DECAY_TIME: float = 3.0
const MASSACRE_MAX_STACKS: int = 15

var has_cooldown_killer: bool = false
var cooldown_killer_value: float = 0.0

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
var _ceremonial_dagger_kill: bool = false  # Prevents daggers from proccing off dagger kills
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
var wind_dancer_reduction: float = 0.0  # Cooldown reduction (0.5 = 50% reduction)
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
var transcendence_accumulated_regen: float = 0.0  # Track accumulated shield regen for display
var has_symbiosis: bool = false
var has_pandemonium: bool = false
var pandemonium_multiplier: float = 2.0

# Active ability synergy effects
var has_quick_reflexes: bool = false
var quick_reflexes_reduction: float = 0.0  # Cooldown reduction (0.15 = 15%)
var has_adrenaline_surge: bool = false
var adrenaline_surge_reduction: float = 0.0  # Cooldown reduction on damage taken
var adrenaline_surge_cooldown: float = 0.0  # Internal cooldown (1 second)
var has_empowered_abilities: bool = false
var empowered_abilities_bonus: float = 0.0  # Damage bonus for active abilities
var has_elemental_infusion: bool = false  # Active abilities apply elemental effects
var has_double_charge: bool = false  # Dodge gains second charge
var has_combo_master: bool = false
var combo_master_bonus: float = 0.0  # Damage bonus from using actives
var combo_master_timer: float = 0.0  # Duration remaining
var combo_master_active: bool = false
var has_ability_echo: bool = false
var ability_echo_chance: float = 0.0  # Chance for actives to trigger twice
var has_swift_dodge: bool = false
var swift_dodge_bonus: float = 0.0  # Move speed bonus after dodging
var swift_dodge_timer: float = 0.0  # Duration remaining
var swift_dodge_active: bool = false
var has_phantom_strike: bool = false
var phantom_strike_damage: float = 0.0  # Damage dealt when dodging through enemies
var has_kill_accelerant: bool = false
var kill_accelerant_reduction: float = 0.0  # Ultimate cooldown reduction per kill
var has_passive_amplifier: bool = false
var passive_amplifier_bonus: float = 0.0  # Passive ability damage bonus

# ============================================
# NEW ORBITAL TYPES
# ============================================
var has_blade_orbit: bool = false
var blade_orbit_count: int = 0
var has_flame_orbit: bool = false
var flame_orbit_count: int = 0
var has_frost_orbit: bool = false
var frost_orbit_count: int = 0

# Orbital enhancements
var orbital_amplifier_applied: bool = false  # Track if we've applied the random +1
var orbital_mastery_count: int = 0  # +1 to all orbitals per pickup

# ============================================
# NEW SYNERGY EFFECTS
# ============================================
var has_momentum_master: bool = false
var momentum_master_bonus: float = 0.0  # Kill streak duration bonus (0.5 = 50% longer)

var has_ability_cascade: bool = false
var ability_cascade_chance: float = 0.0  # Chance to reset another ability

var has_conductor: bool = false
var conductor_bonus: int = 0  # Extra lightning chain targets

var has_blood_trail: bool = false
var blood_trail_duration: float = 0.0  # How long blood pools last

var has_toxic_traits: bool = false
var toxic_traits_damage: float = 0.0  # Damage per tick from poison pools

var has_blazing_trail: bool = false
var blazing_trail_damage: float = 0.0  # Damage per tick from fire pools

# ============================================
# NEW SUMMON TYPES
# ============================================
var has_chicken_summon: bool = false
var chicken_count: int = 0
const MAX_CHICKENS: int = 3

# Summon enhancements
var has_summon_damage: bool = false
var summon_damage_bonus: float = 0.0  # Bonus damage for all summons

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

# ============================================
# MODULAR EFFECT HANDLERS
# ============================================
var _stat_effects: StatEffects = null
var _on_hit_effects: OnHitEffects = null
var _on_kill_effects: OnKillEffects = null
var _combat_effects: CombatEffects = null
var _periodic_effects: PeriodicEffects = null
var _rank_tracker: RankTracker = null

func _ready() -> void:
	all_abilities = AbilityDatabase.get_all_abilities()

	# Initialize modular effect handlers
	_stat_effects = StatEffects.new(self)
	_on_hit_effects = OnHitEffects.new(self)
	_on_kill_effects = OnKillEffects.new(self)
	_combat_effects = CombatEffects.new(self)
	_periodic_effects = PeriodicEffects.new(self)
	_rank_tracker = RankTracker.new(self)

	# Connect equipment signals for real-time stat updates (deferred to ensure autoloads ready)
	call_deferred("_connect_equipment_signals")

func _connect_equipment_signals() -> void:
	if EquipmentManager:
		if not EquipmentManager.item_equipped.is_connected(_on_equipment_changed):
			EquipmentManager.item_equipped.connect(_on_equipment_changed)
		if not EquipmentManager.item_unequipped.is_connected(_on_equipment_changed):
			EquipmentManager.item_unequipped.connect(_on_equipment_changed)

func _on_equipment_changed(_item, _character_id: String) -> void:
	# Re-apply stats to player when equipment changes
	call_deferred("apply_stats_to_player")

func reset() -> void:
	# Reset all acquired abilities
	acquired_abilities.clear()

	# Reset passive selection tracking
	passive_selections_since_upgrade = 0

	# Reset stat modifiers
	stat_modifiers = {
		"attack_speed": 0.0,
		"damage": 0.0,
		"max_hp": 0.0,
		"max_hp_percent": 0.0,
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

	# Reset level-up bonuses
	level_bonus_damage = 0.0

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
	has_double_strike = false

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
	adrenaline_rush_chance = 0.0
	has_phalanx = false
	phalanx_chance = 0.0
	has_homing = false

	# Kill streak effects
	has_rampage = false
	rampage_bonus = 0.0
	rampage_stacks = 0
	rampage_timer = 0.0
	has_killing_frenzy = false
	killing_frenzy_bonus = 0.0
	killing_frenzy_stacks = 0
	killing_frenzy_timer = 0.0
	has_massacre = false
	massacre_bonus = 0.0
	massacre_stacks = 0
	massacre_timer = 0.0
	has_cooldown_killer = false
	cooldown_killer_value = 0.0

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
	_ceremonial_dagger_kill = false
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
	wind_dancer_reduction = 0.0
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
	transcendence_accumulated_regen = 0.0
	has_symbiosis = false
	has_pandemonium = false
	pandemonium_multiplier = 2.0

	# Reset active ability synergy effects
	has_quick_reflexes = false
	quick_reflexes_reduction = 0.0
	has_adrenaline_surge = false
	adrenaline_surge_reduction = 0.0
	adrenaline_surge_cooldown = 0.0
	has_empowered_abilities = false
	empowered_abilities_bonus = 0.0
	has_elemental_infusion = false
	has_double_charge = false
	has_combo_master = false
	combo_master_bonus = 0.0
	combo_master_timer = 0.0
	combo_master_active = false
	has_ability_echo = false
	ability_echo_chance = 0.0
	has_swift_dodge = false
	swift_dodge_bonus = 0.0
	swift_dodge_timer = 0.0
	swift_dodge_active = false
	has_phantom_strike = false
	phantom_strike_damage = 0.0
	has_kill_accelerant = false
	kill_accelerant_reduction = 0.0
	has_passive_amplifier = false
	passive_amplifier_bonus = 0.0

	# Reset new orbital types
	has_blade_orbit = false
	blade_orbit_count = 0
	has_flame_orbit = false
	flame_orbit_count = 0
	has_frost_orbit = false
	frost_orbit_count = 0
	orbital_amplifier_applied = false
	orbital_mastery_count = 0

	# Reset new synergy effects
	has_momentum_master = false
	momentum_master_bonus = 0.0
	has_ability_cascade = false
	ability_cascade_chance = 0.0
	has_conductor = false
	conductor_bonus = 0
	has_blood_trail = false
	blood_trail_duration = 0.0
	has_toxic_traits = false
	toxic_traits_damage = 0.0
	has_blazing_trail = false
	blazing_trail_damage = 0.0

	# Reset new summon types
	has_chicken_summon = false
	chicken_count = 0
	has_summon_damage = false
	summon_damage_bonus = 0.0

	run_start_time = 0.0

	# Reset timers
	regen_timer = 0.0
	tesla_timer = 0.0
	ring_of_fire_timer = 0.0
	lightning_timer = 0.0
	toxic_timer = 0.0

	# Reset rank tracking
	if _rank_tracker:
		_rank_tracker.reset()

func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	# Don't process passives if player is dead
	if player.is_dead:
		return

	process_periodic_effects(delta, player)
	_update_active_synergy_timers(delta)
	process_affix_periodic(delta, player)

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

	# Kill streak decay timers
	if has_rampage and rampage_stacks > 0:
		rampage_timer -= delta
		if rampage_timer <= 0:
			rampage_stacks = 0

	if has_killing_frenzy and killing_frenzy_stacks > 0:
		killing_frenzy_timer -= delta
		if killing_frenzy_timer <= 0:
			killing_frenzy_stacks = 0

	if has_massacre and massacre_stacks > 0:
		massacre_timer -= delta
		if massacre_timer <= 0:
			massacre_stacks = 0

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

	# Transcendence shield regen (2.5 HP/second)
	if has_transcendence and transcendence_shields < transcendence_max:
		var regen_amount = minf(delta * 2.5, transcendence_max - transcendence_shields)
		transcendence_shields += regen_amount
		transcendence_accumulated_regen += regen_amount
		# Show +x every time we accumulate 1 or more
		if transcendence_accumulated_regen >= 1.0:
			var display_amount = floor(transcendence_accumulated_regen)
			spawn_shield_gain_number(player, display_amount)
			transcendence_accumulated_regen -= display_amount

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
		closest.take_damage(tesla_damage * get_passive_damage_multiplier())
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
		target.take_damage(lightning_damage * get_passive_damage_multiplier())
		spawn_lightning_bolt(target.global_position)

func apply_toxic_damage(player: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var damage_per_tick = toxic_dps * TOXIC_INTERVAL * get_passive_damage_multiplier()

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
	var explosion_radius = 150.0  # Increased from 80 for better area coverage
	var enemies = get_tree().get_nodes_in_group("enemies")
	var actual_damage = explosion_damage * get_passive_damage_multiplier()

	for other_enemy in enemies:
		if other_enemy != enemy and is_instance_valid(other_enemy):
			var dist = enemy.global_position.distance_to(other_enemy.global_position)
			if dist <= explosion_radius and other_enemy.has_method("take_damage"):
				other_enemy.take_damage(actual_damage)

	# Visual effect - pass larger radius
	spawn_explosion_effect(enemy.global_position, Color(1.0, 0.4, 0.2), explosion_radius)

func spawn_explosion_effect(pos: Vector2, tint: Color = Color(1.0, 0.4, 0.2), radius: float = 80.0) -> void:
	# Load the script first, then create a Node2D with the script attached
	var explosion_script = load("res://scripts/abilities/explosion_effect.gd")
	if explosion_script == null:
		return

	var circle = Node2D.new()
	circle.set_script(explosion_script)
	circle.explosion_color = tint  # Red/orange tint for death detonation
	# Scale explosion visual to match actual damage radius
	circle.scale_multiplier = radius / 50.0  # Base explosion is ~50px
	circle.explosion_size = "large" if radius >= 120 else "medium"
	circle.global_position = pos
	get_tree().current_scene.add_child(circle)

func spawn_shield_gain_number(player: Node2D, amount: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var damage_number_scene = load("res://scenes/damage_number.tscn")
	if damage_number_scene == null:
		return
	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = player.global_position + Vector2(0, -40)
	get_tree().current_scene.add_child(dmg_num)
	if dmg_num.has_method("set_shield_gain"):
		dmg_num.set_shield_gain(amount)

# Get random abilities for level up selection (passives + active upgrade trigger cards)
func get_random_abilities(count: int = 3) -> Array:
	## Returns mixed array of AbilityData (passives) and trigger card Dictionaries (for active upgrades)
	var available_passives = get_available_abilities()
	var available_triggers = _get_all_active_upgrade_triggers()  # Get trigger cards, not raw upgrades
	var choices: Array = []
	var used_trigger_ability_ids: Array[String] = []  # Track which abilities we've added triggers for

	# Check if we need to guarantee an upgrade ability (passive upgrade, not active ability upgrade)
	var need_guaranteed_upgrade = passive_selections_since_upgrade >= GUARANTEED_UPGRADE_INTERVAL
	var passive_upgrade_included = false

	# If we need a guaranteed upgrade, try to include a passive upgrade first
	if need_guaranteed_upgrade:
		var available_passive_upgrades = _get_available_passive_upgrades(available_passives)
		if available_passive_upgrades.size() > 0:
			var upgrade = pick_weighted_random(available_passive_upgrades, true)
			if upgrade:
				choices.append(upgrade)
				available_passives.erase(upgrade)
				passive_upgrade_included = true

	for i in range(count - choices.size()):
		if available_passives.size() == 0 and available_triggers.size() == 0:
			break

		# Roll for active ability upgrade trigger (50% chance if triggers available)
		var use_active_upgrade = available_triggers.size() > 0 and randf() < 0.50

		if use_active_upgrade:
			# Pick a trigger card (shows current ability, click to see upgrade options)
			var trigger = available_triggers[0]
			choices.append(trigger)
			available_triggers.erase(trigger)
			# Track this ability so we don't add multiple triggers for same ability
			if trigger.ability:
				used_trigger_ability_ids.append(trigger.ability.id)
		elif available_passives.size() > 0:
			# Pick weighted passive (with synergy boost)
			var ability = pick_weighted_random(available_passives, true)
			if ability:
				choices.append(ability)
				available_passives.erase(ability)
				if ability.is_upgrade:
					passive_upgrade_included = true
		elif available_triggers.size() > 0:
			# Fallback to trigger if no passives left
			var trigger = available_triggers[0]
			choices.append(trigger)
			available_triggers.erase(trigger)

	# Shuffle to randomize positions
	choices.shuffle()

	# Track that we showed choices (counter will be incremented when ability is acquired)
	return choices

func get_passive_choices_with_active_upgrade(count: int, level: int) -> Array:
	"""
	Get passive ability choices with ONE guaranteed active upgrade trigger card.
	Used at levels 3, 7, 12 to offer active ability upgrade path.
	Returns mixed array of AbilityData (passives) and ONE trigger card Dictionary.
	"""
	var choices: Array = []
	var available_passives = get_available_abilities()

	# Check if this level should have guaranteed active upgrade
	const ACTIVE_UPGRADE_LEVELS: Array[int] = [3, 7, 12]
	print("[ABILITY_MANAGER] get_passive_choices_with_active_upgrade called for level ", level)
	if level in ACTIVE_UPGRADE_LEVELS:
		# Get ONE trigger card (first available upgradeable ability)
		var trigger = _get_active_upgrade_trigger()
		if trigger:
			print("[ABILITY_MANAGER] Adding GUARANTEED trigger card for: ", trigger.ability.name, " with ", trigger.upgrades.size(), " upgrade options")
			choices.append(trigger)
		else:
			print("[ABILITY_MANAGER] WARNING: No trigger card available! Checking why...")
			print("  - ActiveAbilityManager exists: ", ActiveAbilityManager != null)
			if ActiveAbilityManager:
				print("  - Ability slots: ", ActiveAbilityManager.ability_slots)
				for i in ActiveAbilityManager.MAX_ABILITY_SLOTS:
					var current = ActiveAbilityManager.ability_slots[i]
					if current:
						var upgrades = AbilityTreeRegistry.get_available_upgrades_for_ability(current.id)
						print("  - Slot ", i, ": ", current.name, " (id: ", current.id, ") has ", upgrades.size(), " upgrades")

	# Fill remaining slots with passives
	var passive_count = count - choices.size()
	for i in range(passive_count):
		if available_passives.size() == 0:
			break
		var ability = pick_weighted_random(available_passives, true)
		if ability:
			choices.append(ability)
			available_passives.erase(ability)

	# Shuffle to randomize position of active upgrade card
	choices.shuffle()
	return choices

func _get_all_active_upgrade_triggers() -> Array:
	"""
	Get ALL active ability upgrade TRIGGER cards (one per upgradeable ability).
	Returns an Array of Dictionaries, each with the current ability and its available upgrade branches.
	"""
	var triggers: Array = []

	if not ActiveAbilityManager:
		return triggers

	# Find ALL equipped abilities that have upgrades available
	for i in ActiveAbilityManager.MAX_ABILITY_SLOTS:
		var current = ActiveAbilityManager.ability_slots[i]
		if current == null:
			continue

		# Get available upgrades for this ability
		var upgrades = AbilityTreeRegistry.get_available_upgrades_for_ability(current.id)
		if upgrades.size() > 0:
			# Create a trigger card dictionary (not individual upgrades)
			triggers.append({
				"is_trigger": true,
				"ability": current,  # The current equipped ability
				"upgrades": upgrades  # Available upgrade branches
			})

	return triggers

func _get_active_upgrade_trigger():
	"""
	Get ONE active ability upgrade TRIGGER card (for backwards compatibility).
	Returns a Dictionary with the current ability and its available upgrade branches.
	"""
	var triggers = _get_all_active_upgrade_triggers()
	if triggers.is_empty():
		return null
	return triggers[0]

func _get_available_passive_upgrades(from_pool: Array[AbilityData]) -> Array[AbilityData]:
	"""Get only passive upgrade abilities from the available pool"""
	var upgrades: Array[AbilityData] = []
	for ability in from_pool:
		if ability.is_upgrade:
			upgrades.append(ability)
	return upgrades

func _get_active_ability_upgrades() -> Array:
	## Get available active ability upgrades from ActiveAbilityManager
	var active_manager = get_tree().get_first_node_in_group("active_ability_manager")
	if active_manager and active_manager.has_method("get_available_upgrades"):
		return active_manager.get_available_upgrades()
	return []

func get_available_abilities() -> Array[AbilityData]:
	var available: Array[AbilityData] = []

	for ability in all_abilities:
		# Skip locked abilities (must be unlocked via game completions)
		if UnlocksManager and not UnlocksManager.is_passive_unlocked(ability.id):
			continue

		# Skip melee abilities for ranged characters
		if ability.type == AbilityData.Type.MELEE_ONLY and is_ranged_character:
			continue

		# Skip ranged abilities for melee characters
		if ability.type == AbilityData.Type.RANGED_ONLY and not is_ranged_character:
			continue

		# Check if already acquired (allow stacking for some abilities)
		if not is_ability_stackable(ability) and has_ability(ability.id):
			continue

		# Check prerequisites - must have at least one prerequisite ability
		if not _meets_prerequisites(ability):
			continue

		available.append(ability)

	return available

func _meets_prerequisites(ability: AbilityData) -> bool:
	"""Check if player meets prerequisites for an ability"""
	# No prerequisites = always available
	if ability.prerequisite_ids.size() == 0:
		return true

	# Must have at least one of the prerequisite abilities
	for prereq_id in ability.prerequisite_ids:
		if has_ability(prereq_id):
			return true

	return false

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

func pick_weighted_random(abilities: Array[AbilityData], apply_synergy_boost: bool = false) -> AbilityData:
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

	for rarity in [AbilityData.Rarity.LEGENDARY, AbilityData.Rarity.EPIC, AbilityData.Rarity.RARE, AbilityData.Rarity.COMMON]:
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

			# Apply synergy weight boost if enabled
			if apply_synergy_boost and _has_synergy_with_current_build(ability):
				weight *= SYNERGY_WEIGHT_BOOST

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

func _has_synergy_with_current_build(ability: AbilityData) -> bool:
	"""Check if ability synergizes with current build"""
	# Check explicit synergy IDs from ability data
	for synergy_id in ability.synergy_ids:
		if has_ability(synergy_id):
			return true

	# Check implicit synergies based on effect types
	return _check_implicit_synergies(ability)

func _check_implicit_synergies(ability: AbilityData) -> bool:
	"""Check for implicit synergies based on ability effects"""
	for effect in ability.effects:
		var effect_type = effect.get("effect_type", -1)

		# Orbital synergies
		if effect_type in [AbilityData.EffectType.ORBITAL_AMPLIFIER, AbilityData.EffectType.ORBITAL_MASTERY]:
			if has_ability("blade_orbit") or has_ability("flame_orbit") or has_ability("frost_orbit") or has_ability("orbital_defense"):
				return true

		# Summon synergies
		if effect_type == AbilityData.EffectType.SUMMON_DAMAGE:
			if has_ability("chicken_companion") or has_ability("summoner_aid") or has_ability("drone_support"):
				return true

		# Elemental synergies
		if effect_type in [AbilityData.EffectType.CHAIN_REACTION, AbilityData.EffectType.CONDUCTOR]:
			if has_ability("ignite") or has_ability("frostbite") or has_ability("toxic_tip") or has_ability("lightning_strike_proc"):
				return true

		# Kill streak synergies
		if effect_type == AbilityData.EffectType.MOMENTUM_MASTER:
			if has_ability("rampage") or has_ability("killing_frenzy") or has_ability("massacre"):
				return true

		# Aura synergies for Empathic Bond
		if effect_type == AbilityData.EffectType.EMPATHIC_BOND:
			if has_ability("ring_of_fire") or has_ability("toxic_cloud") or has_ability("tesla_coil"):
				return true

	return false

func acquire_ability(ability: AbilityData) -> void:
	acquired_abilities.append(ability)

	# Increment rank and apply effects for that rank
	var new_rank = 1
	if _rank_tracker:
		new_rank = _rank_tracker.increment_passive_rank(ability.id)
	apply_ability_effects_for_rank(ability, new_rank)

	# Track passive selections for guaranteed upgrade logic
	if ability.is_upgrade:
		# Reset counter when player selects an upgrade
		passive_selections_since_upgrade = 0
	else:
		# Increment counter for non-upgrade selections
		passive_selections_since_upgrade += 1

	emit_signal("ability_acquired", ability)

# ============================================
# RANK TRACKING HELPERS
# ============================================

func get_ability_rank(ability_id: String) -> int:
	"""Get current rank of a passive ability (0 if not acquired)."""
	if _rank_tracker:
		return _rank_tracker.get_passive_rank(ability_id)
	return 0

func is_ability_at_max_rank(ability_id: String) -> bool:
	"""Check if passive has reached max rank (3)."""
	if _rank_tracker:
		return _rank_tracker.is_passive_at_max_rank(ability_id)
	return false

func get_next_ability_rank(ability_id: String) -> int:
	"""Get what rank this ability would be if acquired next."""
	if _rank_tracker:
		return _rank_tracker.get_next_passive_rank(ability_id)
	return 1

func is_ability_upgrade(ability_id: String) -> bool:
	"""Check if this ability would be an upgrade (already acquired at least once)."""
	return get_ability_rank(ability_id) > 0

# ============================================
# EFFECT APPLICATION
# ============================================

func apply_ability_effects_for_rank(ability: AbilityData, rank: int) -> void:
	"""Apply effects based on the ability's current rank."""
	var effects_to_apply = ability.get_effects_for_rank(rank)
	_apply_effects(effects_to_apply)

func apply_ability_effects(ability: AbilityData) -> void:
	"""Apply base effects (backwards compatible)."""
	_apply_effects(ability.effects)

func _apply_effects(effects: Array) -> void:
	"""Internal: Apply an array of effects."""
	for effect in effects:
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
			AbilityData.EffectType.MAX_HP_PERCENT:
				stat_modifiers["max_hp_percent"] += value
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
			AbilityData.EffectType.DOUBLE_STRIKE:
				has_double_strike = true

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
			AbilityData.EffectType.STUNNER_SHADES:
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
				adrenaline_rush_chance = value
			AbilityData.EffectType.PHALANX:
				has_phalanx = true
				phalanx_chance += value
			AbilityData.EffectType.HOMING:
				has_homing = true

			# Kill streak effects
			AbilityData.EffectType.RAMPAGE:
				has_rampage = true
				rampage_bonus += value
			AbilityData.EffectType.KILLING_FRENZY:
				has_killing_frenzy = true
				killing_frenzy_bonus += value
			AbilityData.EffectType.MASSACRE:
				has_massacre = true
				massacre_bonus += value
			AbilityData.EffectType.COOLDOWN_KILLER:
				has_cooldown_killer = true
				cooldown_killer_value += value

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
				wind_dancer_reduction = value  # 0.5 = 50% cooldown reduction
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

			# Active ability synergy effects
			AbilityData.EffectType.QUICK_REFLEXES:
				has_quick_reflexes = true
				quick_reflexes_reduction += value  # Stacks
			AbilityData.EffectType.ADRENALINE_SURGE:
				has_adrenaline_surge = true
				adrenaline_surge_reduction = value
			AbilityData.EffectType.EMPOWERED_ABILITIES:
				has_empowered_abilities = true
				empowered_abilities_bonus += value  # Stacks
			AbilityData.EffectType.ELEMENTAL_INFUSION:
				has_elemental_infusion = true
			AbilityData.EffectType.DOUBLE_CHARGE:
				has_double_charge = true
				_apply_double_charge()
			AbilityData.EffectType.COMBO_MASTER:
				has_combo_master = true
				combo_master_bonus = value
			AbilityData.EffectType.ABILITY_ECHO:
				has_ability_echo = true
				ability_echo_chance += value  # Stacks
			AbilityData.EffectType.SWIFT_DODGE:
				has_swift_dodge = true
				swift_dodge_bonus = value
			AbilityData.EffectType.PHANTOM_STRIKE:
				has_phantom_strike = true
				phantom_strike_damage = value
			AbilityData.EffectType.KILL_ACCELERANT:
				has_kill_accelerant = true
				kill_accelerant_reduction = value
			AbilityData.EffectType.PASSIVE_AMPLIFIER:
				has_passive_amplifier = true
				passive_amplifier_bonus += value  # Stacks

			# New Orbital Types
			AbilityData.EffectType.BLADE_ORBIT:
				has_blade_orbit = true
				blade_orbit_count += int(value)
				spawn_blade_orbital()
			AbilityData.EffectType.FLAME_ORBIT:
				has_flame_orbit = true
				flame_orbit_count += int(value)
				spawn_flame_orbital()
			AbilityData.EffectType.FROST_ORBIT:
				has_frost_orbit = true
				frost_orbit_count += int(value)
				spawn_frost_orbital()

			# Orbital Enhancements
			AbilityData.EffectType.ORBITAL_AMPLIFIER:
				_apply_orbital_amplifier()
			AbilityData.EffectType.ORBITAL_MASTERY:
				orbital_mastery_count += 1
				_apply_orbital_mastery()

			# Synergy Effects
			AbilityData.EffectType.MOMENTUM_MASTER:
				has_momentum_master = true
				momentum_master_bonus = value
			AbilityData.EffectType.ABILITY_CASCADE:
				has_ability_cascade = true
				ability_cascade_chance = value
			AbilityData.EffectType.CONDUCTOR:
				has_conductor = true
				conductor_bonus += int(value)
			AbilityData.EffectType.BLOOD_TRAIL:
				has_blood_trail = true
				blood_trail_duration = value
			AbilityData.EffectType.TOXIC_TRAITS:
				has_toxic_traits = true
				toxic_traits_damage = value
			AbilityData.EffectType.BLAZING_TRAIL:
				has_blazing_trail = true
				blazing_trail_damage = value

			# Summon Types
			AbilityData.EffectType.CHICKEN_SUMMON:
				has_chicken_summon = true
				spawn_chicken()
			AbilityData.EffectType.SUMMON_DAMAGE:
				has_summon_damage = true
				summon_damage_bonus += value

	# Apply stat changes to player immediately
	apply_stats_to_player()

func apply_stats_to_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Combine ability stat modifiers with equipment stats
	var combined_modifiers = stat_modifiers.duplicate()

	# Add equipment stats
	combined_modifiers["max_hp"] = stat_modifiers.get("max_hp", 0.0) + _get_equipment_stat("max_hp")
	combined_modifiers["move_speed"] = stat_modifiers.get("move_speed", 0.0) + _get_equipment_stat("move_speed")
	combined_modifiers["attack_speed"] = stat_modifiers.get("attack_speed", 0.0) + _get_equipment_stat("attack_speed")
	combined_modifiers["pickup_range"] = stat_modifiers.get("pickup_range", 0.0) + _get_equipment_stat("pickup_range")
	combined_modifiers["size"] = stat_modifiers.get("size", 0.0) + _get_equipment_stat("size")

	# Update player stats based on combined modifiers
	if player.has_method("update_ability_stats"):
		player.update_ability_stats(combined_modifiers)

func spawn_orbital() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var orbital_scene = load("res://scenes/abilities/orbital.tscn")
	if orbital_scene:
		var orbital = orbital_scene.instantiate()
		orbital.orbit_index = orbital_count - 1
		player.add_child(orbital)

func spawn_blade_orbital() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var orbital_scene = load("res://scenes/abilities/blade_orbital.tscn")
	if orbital_scene:
		var orbital = orbital_scene.instantiate()
		orbital.orbit_index = blade_orbit_count - 1 + orbital_mastery_count
		player.add_child(orbital)

func spawn_flame_orbital() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var orbital_scene = load("res://scenes/abilities/flame_orbital.tscn")
	if orbital_scene:
		var orbital = orbital_scene.instantiate()
		orbital.orbit_index = flame_orbit_count - 1 + orbital_mastery_count
		player.add_child(orbital)

func spawn_frost_orbital() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var orbital_scene = load("res://scenes/abilities/frost_orbital.tscn")
	if orbital_scene:
		var orbital = orbital_scene.instantiate()
		orbital.orbit_index = frost_orbit_count - 1 + orbital_mastery_count
		player.add_child(orbital)

func spawn_chicken() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if chicken_count >= MAX_CHICKENS:
		return

	chicken_count += 1
	var chicken_scene = load("res://scenes/abilities/chicken.tscn")
	if chicken_scene:
		var chicken = chicken_scene.instantiate()
		player.get_parent().add_child(chicken)

func _apply_orbital_amplifier() -> void:
	"""Add +1 to a random orbital type that the player has."""
	if orbital_amplifier_applied:
		return  # Only apply once per pickup

	var orbitals_owned: Array = []
	if has_orbital and orbital_count > 0:
		orbitals_owned.append("orbital")
	if has_blade_orbit and blade_orbit_count > 0:
		orbitals_owned.append("blade")
	if has_flame_orbit and flame_orbit_count > 0:
		orbitals_owned.append("flame")
	if has_frost_orbit and frost_orbit_count > 0:
		orbitals_owned.append("frost")

	if orbitals_owned.size() == 0:
		return  # No orbitals to amplify

	orbital_amplifier_applied = true
	var chosen = orbitals_owned[randi() % orbitals_owned.size()]

	match chosen:
		"orbital":
			orbital_count += 1
			spawn_orbital()
		"blade":
			blade_orbit_count += 1
			spawn_blade_orbital()
		"flame":
			flame_orbit_count += 1
			spawn_flame_orbital()
		"frost":
			frost_orbit_count += 1
			spawn_frost_orbital()

func _apply_orbital_mastery() -> void:
	"""Add +1 to ALL orbital types the player has."""
	# Spawn an extra of each orbital type
	if has_orbital and orbital_count > 0:
		orbital_count += 1
		spawn_orbital()
	if has_blade_orbit and blade_orbit_count > 0:
		blade_orbit_count += 1
		spawn_blade_orbital()
	if has_flame_orbit and flame_orbit_count > 0:
		flame_orbit_count += 1
		spawn_flame_orbital()
	if has_frost_orbit and frost_orbit_count > 0:
		frost_orbit_count += 1
		spawn_frost_orbital()

func spawn_blood_pool(position: Vector2) -> void:
	"""Spawn a blood pool at the given position that damages enemies."""
	if not has_blood_trail:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var blood_pool_scene = load("res://scenes/abilities/blood_pool.tscn")
	if blood_pool_scene:
		var pool = blood_pool_scene.instantiate()
		pool.global_position = position
		pool.lifetime = blood_trail_duration
		pool.damage_per_tick = 5.0 * get_summon_damage_multiplier()
		player.get_parent().add_child(pool)

func spawn_toxic_pool(position: Vector2) -> void:
	"""Spawn a poison pool at the given position that damages enemies."""
	if not has_toxic_traits:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var poison_pool_scene = load("res://scenes/abilities/poison_pool.tscn")
	if poison_pool_scene:
		var pool = poison_pool_scene.instantiate()
		pool.global_position = position
		pool.lifetime = 3.0  # Fixed 3 second duration
		pool.damage_per_tick = toxic_traits_damage * get_summon_damage_multiplier()
		player.get_parent().add_child(pool)

func spawn_fire_pool(position: Vector2) -> void:
	"""Spawn a fire pool at the given position that damages enemies."""
	if not has_blazing_trail:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var fire_pool_scene = load("res://scenes/abilities/fire_pool.tscn")
	if fire_pool_scene:
		var pool = fire_pool_scene.instantiate()
		pool.global_position = position
		pool.lifetime = 2.5  # Slightly shorter than poison
		pool.damage_per_tick = blazing_trail_damage * get_summon_damage_multiplier()
		player.get_parent().add_child(pool)

func get_summon_damage_multiplier() -> float:
	"""Get damage multiplier for all summons."""
	var mult = 1.0
	if has_summon_damage:
		mult += summon_damage_bonus
	# Add permanent upgrade bonus
	if PermanentUpgrades:
		mult += PermanentUpgrades.get_all_bonuses().get("summon_damage", 0.0)
	if has_empathic_bond:
		mult *= empathic_bond_multiplier
	return mult

func get_lightning_chain_count() -> int:
	"""Get total lightning chain count including conductor bonus."""
	var base = 3  # Default chain count
	if has_conductor:
		base += conductor_bonus
	return base

func get_kill_streak_duration_multiplier() -> float:
	"""Get duration multiplier for kill streaks (rampage, frenzy, massacre)."""
	if has_momentum_master:
		return 1.0 + momentum_master_bonus
	return 1.0

func try_ability_cascade() -> void:
	"""Try to trigger ability cascade when using an active ability."""
	if not has_ability_cascade:
		return

	if randf() < ability_cascade_chance:
		# Reset a random active ability cooldown
		if ActiveAbilityManager:
			ActiveAbilityManager.reset_random_cooldown()

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

	# Add level-up bonus (5% per level after level 1)
	base += level_bonus_damage

	# Add permanent upgrade bonus
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("damage", 0.0)

	# Add character passive bonus (Mage's Arcane Intellect)
	if CharacterManager:
		base += CharacterManager.get_passive_bonuses().get("damage", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("damage")

	# Kill streak bonuses
	if has_rampage and rampage_stacks > 0:
		base += rampage_bonus * rampage_stacks

	if has_massacre and massacre_stacks > 0:
		base += massacre_bonus * massacre_stacks

	# Combo Master bonus (from using active abilities)
	base *= get_combo_master_damage_multiplier()

	return base

func add_level_bonus() -> void:
	"""Add 5% damage bonus for leveling up."""
	level_bonus_damage += 0.05

func get_attack_speed_multiplier() -> float:
	var base = 1.0 + stat_modifiers["attack_speed"]

	# Frenzy bonus when low HP
	if has_frenzy:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.current_health / player.max_health < 0.3:
			base += frenzy_boost

	# Add equipment bonus
	base += _get_equipment_stat("attack_speed")

	# Kill streak bonuses
	if has_killing_frenzy and killing_frenzy_stacks > 0:
		base += killing_frenzy_bonus * killing_frenzy_stacks

	if has_massacre and massacre_stacks > 0:
		base += massacre_bonus * massacre_stacks

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

	# Add character passive bonus (Mage's Arcane Intellect)
	if CharacterManager:
		base += CharacterManager.get_passive_bonuses().get("crit_damage", 0.0)

	return base

# Get luck multiplier for drops
func get_luck_multiplier() -> float:
	var base = 1.0 + stat_modifiers.get("luck", 0.0)

	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("luck", 0.0)

	# Apply Jinxed curse (reduced luck)
	if CurseEffects:
		base *= CurseEffects.get_luck_multiplier()

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
	var base_value = equipment_stats.get(stat, 0.0)

	# Apply Brittle Armor curse (reduced equipment effectiveness)
	if CurseEffects:
		base_value *= CurseEffects.get_equipment_bonus_multiplier()

	return base_value

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
	var actual_damage = retribution_damage * get_passive_damage_multiplier()
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player_pos.distance_to(enemy.global_position)
			if dist <= explosion_radius and enemy.has_method("take_damage"):
				enemy.take_damage(actual_damage)
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

# Check if double strike should trigger (from passive ability)
func should_double_strike() -> bool:
	# Passive ability gives guaranteed double strike
	if has_double_strike:
		return true
	return false

# Get number of extra melee swings from permanent upgrade
func get_extra_melee_swings() -> int:
	if PermanentUpgrades:
		return PermanentUpgrades.get_all_bonuses().get("melee_swing_count", 0)
	return 0

# Called when player picks up a coin
func on_coin_pickup(player: Node2D) -> void:
	if player == null or player.is_dead:
		return
	if has_blood_money:
		# Heal 1% max HP with visual feedback
		if player.has_method("heal"):
			player.heal(player.max_health * 0.01, false, false, true)  # show_text = true

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

# Get passive ability damage multiplier
func get_passive_damage_multiplier() -> float:
	var base = 1.0

	# Add level-up bonus (5% per level)
	base += level_bonus_damage

	# Add passive amplifier bonus
	if has_passive_amplifier:
		base += passive_amplifier_bonus

	return base

# Check and trigger phoenix revive
func try_phoenix_revive(player: Node2D) -> bool:
	if not has_phoenix or phoenix_used:
		return false
	phoenix_used = true

	# Show phoenix revive screen effect
	_show_phoenix_revive_effect(player)

	return true

func _show_phoenix_revive_effect(player: Node2D) -> void:
	# Pause the game
	get_tree().paused = true

	# Create overlay canvas layer
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(canvas)

	# Black overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)

	# Phoenix Revive text
	var label = Label.new()
	label.text = "PHOENIX REVIVE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Load pixel font
	var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 50)
	label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1, 1.0))  # Orange/gold phoenix color

	# Shadow for visibility
	label.add_theme_color_override("font_shadow_color", Color(0.8, 0.2, 0.0, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)

	canvas.add_child(label)

	# Animate text scale
	label.pivot_offset = label.size / 2
	label.scale = Vector2(0.5, 0.5)
	label.modulate.a = 0.0

	var tween = canvas.create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(0.7)  # Hold for 0.7s (total 1s with animation)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		# Unpause and cleanup
		get_tree().paused = false
		canvas.queue_free()

		# Now revive the player
		if player and is_instance_valid(player) and player.has_method("revive_with_percent"):
			player.revive_with_percent(phoenix_hp_percent)

		# Trigger explosion on revive
		if player and is_instance_valid(player):
			trigger_phoenix_explosion(player.global_position)
	)

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
	# Don't trigger on-kill effects if player is dead
	if player == null or player.is_dead:
		return

	# Permanent upgrade: HP on kill (Life Leech)
	if PermanentUpgrades:
		var bonuses = PermanentUpgrades.get_all_bonuses()
		if bonuses.get("hp_on_kill", 0.0) > 0:
			heal_player(player, bonuses.get("hp_on_kill", 0.0))

	# Vampirism
	if has_vampirism and randf() < vampirism_chance:
		heal_player(player, player.max_health * 0.05)

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

	# Ceremonial Dagger - fire homing daggers (only from player kills, not dagger kills)
	if has_ceremonial_dagger and not _ceremonial_dagger_kill:
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

	# Kill Streak Effects
	if has_rampage:
		rampage_stacks = mini(rampage_stacks + 1, RAMPAGE_MAX_STACKS)
		rampage_timer = RAMPAGE_DECAY_TIME

	if has_killing_frenzy:
		killing_frenzy_stacks = mini(killing_frenzy_stacks + 1, KILLING_FRENZY_MAX_STACKS)
		killing_frenzy_timer = KILLING_FRENZY_DECAY_TIME

	if has_massacre:
		massacre_stacks = mini(massacre_stacks + 1, MASSACRE_MAX_STACKS)
		massacre_timer = MASSACRE_DECAY_TIME

	if has_cooldown_killer:
		reduce_active_cooldowns(cooldown_killer_value)

	# Kill Accelerant - reduce ultimate cooldown on kill
	if has_kill_accelerant and UltimateAbilityManager:
		UltimateAbilityManager.reduce_cooldown(kill_accelerant_reduction)

	# Blood Trail - spawn damaging blood pool at kill location
	if has_blood_trail:
		spawn_blood_pool(enemy.global_position)

	# Affix ability on-kill triggers
	process_affix_on_kill(enemy, player, 0.0)

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

func trigger_lightning_at(pos: Vector2) -> void:
	"""Trigger a lightning strike at the given position."""
	spawn_lightning_bolt(pos)

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
	# Cap at 40% max damage bonus
	return minf(unlimited_power_bonus * unlimited_power_stacks, 0.40)

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

func check_adrenaline_dash_on_hit(player: Node2D) -> void:
	"""Called when player hits an enemy - 35% chance to dash to nearest enemy."""
	if player == null or player.is_dead:
		return
	if not has_adrenaline_rush:
		return
	if randf() > adrenaline_rush_chance:
		return
	trigger_adrenaline_dash(player)

func trigger_adrenaline_dash(player: Node2D) -> void:
	if player == null or player.is_dead:
		return
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

func get_wind_dancer_cooldown_multiplier() -> float:
	# Returns 0.5 for 50% cooldown (half duration), 1.0 for full cooldown
	if has_wind_dancer:
		return 1.0 - wind_dancer_reduction
	return 1.0

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

# ============================================
# ACTIVE ABILITY SYNERGY HELPERS
# ============================================

func get_active_cooldown_multiplier() -> float:
	"""Get cooldown multiplier for active abilities (Quick Reflexes)."""
	if has_quick_reflexes:
		return 1.0 - quick_reflexes_reduction
	return 1.0

func on_player_damaged() -> void:
	"""Called when player takes damage - triggers Adrenaline Surge."""
	if not has_adrenaline_surge:
		return
	if adrenaline_surge_cooldown > 0:
		return  # Still on internal cooldown

	# Reduce all active ability cooldowns
	if ActiveAbilityManager:
		ActiveAbilityManager.reduce_all_cooldowns(adrenaline_surge_reduction)

	# Set internal cooldown (1 second)
	adrenaline_surge_cooldown = 1.0

func get_active_ability_damage_multiplier() -> float:
	"""Get damage multiplier for active abilities (Empowered Abilities)."""
	var multiplier = 1.0
	if has_empowered_abilities:
		multiplier += empowered_abilities_bonus
	return multiplier

func should_apply_elemental_to_active() -> bool:
	"""Check if active abilities should apply elemental effects."""
	return has_elemental_infusion

func apply_elemental_effects_to_enemy(enemy: Node2D) -> void:
	"""Apply the player's elemental effects to an enemy (for Elemental Infusion)."""
	if not has_elemental_infusion or enemy == null:
		return

	# Apply any elemental effects the player has
	if has_ignite and enemy.has_method("apply_burn"):
		enemy.apply_burn(3.0)
	if has_frostbite and enemy.has_method("apply_chill"):
		enemy.apply_chill(2.0)
	if has_toxic_tip and enemy.has_method("apply_poison"):
		enemy.apply_poison(30.0, 3.0)
	if has_lightning_proc and enemy.has_method("apply_shock"):
		enemy.apply_shock(15.0)

func _apply_double_charge() -> void:
	"""Apply double charge to dodge ability."""
	if ActiveAbilityManager:
		ActiveAbilityManager.add_dodge_charge()

func on_active_ability_used() -> void:
	"""Called when any active ability is used - triggers Combo Master."""
	if not has_combo_master:
		return

	combo_master_active = true
	combo_master_timer = 3.0  # 3 second duration

func get_combo_master_damage_multiplier() -> float:
	"""Get auto-attack damage multiplier from Combo Master."""
	if has_combo_master and combo_master_active:
		return 1.0 + combo_master_bonus
	return 1.0

func should_echo_ability() -> bool:
	"""Check if ability should trigger twice (Ability Echo)."""
	if not has_ability_echo:
		return false
	return randf() < ability_echo_chance

func on_dodge_used() -> void:
	"""Called when dodge is used - triggers Swift Dodge speed boost and Combo Master."""
	if has_swift_dodge:
		swift_dodge_active = true
		swift_dodge_timer = 2.0  # 2 second duration

	# Dodge counts as an active ability for Combo Master
	if has_combo_master:
		combo_master_active = true
		combo_master_timer = 3.0  # 3 second duration

func get_swift_dodge_speed_multiplier() -> float:
	"""Get move speed multiplier from Swift Dodge."""
	if has_swift_dodge and swift_dodge_active:
		return 1.0 + swift_dodge_bonus
	return 1.0

func on_dodge_through_enemy(player: Node2D, enemies_hit: Array) -> void:
	"""Called when player dodges through enemies - triggers Phantom Strike damage."""
	if not has_phantom_strike or enemies_hit.is_empty():
		return

	# Calculate damage based on player's attack damage
	var base_damage = phantom_strike_damage
	if player.has_method("get_attack_damage"):
		base_damage += player.get_attack_damage() * 0.5  # 50% of attack damage

	# Apply damage to all enemies passed through
	for enemy in enemies_hit:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(base_damage)

	# Visual effect - small explosion at player position
	_spawn_phantom_strike_effect(player.global_position)

func _spawn_phantom_strike_effect(pos: Vector2) -> void:
	"""Spawn visual effect for Phantom Strike."""
	# Create a simple particle effect
	var particles = CPUParticles2D.new()
	particles.global_position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12
	particles.lifetime = 0.3
	particles.direction = Vector2.ZERO
	particles.spread = 180
	particles.initial_velocity_min = 100
	particles.initial_velocity_max = 200
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 5.0
	particles.color = Color(0.6, 0.3, 1.0, 0.8)  # Purple

	get_tree().current_scene.add_child(particles)

	# Auto-cleanup
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func(): particles.queue_free())

func _update_active_synergy_timers(delta: float) -> void:
	"""Update timers for active ability synergy effects."""
	# Adrenaline Surge internal cooldown
	if adrenaline_surge_cooldown > 0:
		adrenaline_surge_cooldown -= delta

	# Combo Master timer
	if combo_master_active and combo_master_timer > 0:
		combo_master_timer -= delta
		if combo_master_timer <= 0:
			combo_master_active = false

	# Swift Dodge timer
	if swift_dodge_active and swift_dodge_timer > 0:
		swift_dodge_timer -= delta
		if swift_dodge_timer <= 0:
			swift_dodge_active = false

# ============================================
# AFFIX ABILITY TRIGGERS (Equipment mini-abilities)
# ============================================

var affix_periodic_timers: Dictionary = {}  # {affix_id: current_time}
var affix_speed_boost_active: bool = false
var affix_speed_boost_timer: float = 0.0
var affix_speed_boost_mult: float = 1.0

func process_affix_on_hit(enemy: Node2D, player: Node2D, damage: float, is_crit: bool) -> void:
	"""Process affix abilities that trigger on hit."""
	if player == null or not is_instance_valid(enemy):
		return

	var character_id = ""
	if CharacterManager:
		character_id = CharacterManager.selected_character_id

	if character_id == "" or not EquipmentManager:
		return

	var on_hit_abilities = EquipmentManager.get_affix_abilities_by_trigger(character_id, "on_hit")

	for ability_data in on_hit_abilities:
		var data = ability_data.data
		var chance = data.get("chance", 1.0)

		if randf() > chance:
			continue

		match data.effect:
			"lightning":
				_affix_trigger_lightning(enemy, player, damage * data.get("damage_mult", 0.25))
			"freeze":
				_affix_trigger_freeze(enemy, data.get("slow_percent", 0.3), data.get("duration", 1.5))
			"bleed":
				_affix_trigger_bleed(enemy, damage * data.get("damage_mult", 0.15), data.get("duration", 3.0))
			"burn":
				_affix_trigger_burn(enemy, data.get("duration", 2.0))
			"poison":
				_affix_trigger_poison(enemy, damage * data.get("damage_mult", 0.08), data.get("duration", 4.0))
			"knockback":
				_affix_trigger_knockback(enemy, player, data.get("force", 150.0))

	# Also check on_crit triggers if this was a crit
	if is_crit:
		process_affix_on_crit(enemy, player, damage)

func process_affix_on_crit(enemy: Node2D, player: Node2D, damage: float) -> void:
	"""Process affix abilities that trigger on critical hit."""
	if player == null or not is_instance_valid(enemy):
		return

	var character_id = ""
	if CharacterManager:
		character_id = CharacterManager.selected_character_id

	if character_id == "" or not EquipmentManager:
		return

	var on_crit_abilities = EquipmentManager.get_affix_abilities_by_trigger(character_id, "on_crit")

	for ability_data in on_crit_abilities:
		var data = ability_data.data

		match data.effect:
			"execute":
				_affix_trigger_execute(enemy, damage * data.get("damage_mult", 0.5), data.get("hp_threshold", 0.3))
			"stun":
				_affix_trigger_stun(enemy, data.get("duration", 0.5))

func process_affix_on_kill(enemy: Node2D, player: Node2D, damage: float) -> void:
	"""Process affix abilities that trigger on enemy kill."""
	if player == null:
		return

	var character_id = ""
	if CharacterManager:
		character_id = CharacterManager.selected_character_id

	if character_id == "" or not EquipmentManager:
		return

	var on_kill_abilities = EquipmentManager.get_affix_abilities_by_trigger(character_id, "on_kill")

	for ability_data in on_kill_abilities:
		var data = ability_data.data

		match data.effect:
			"explosion":
				_affix_trigger_explosion(enemy.global_position, damage * data.get("damage_mult", 0.3), data.get("radius", 60.0))
			"heal":
				heal_player(player, data.get("heal_amount", 2.0))
			"speed_boost":
				_affix_trigger_speed_boost(data.get("speed_mult", 0.25), data.get("duration", 2.0))
			"chain_damage":
				_affix_trigger_chain_damage(enemy.global_position, damage * data.get("damage_mult", 0.2), data.get("radius", 100.0))

func process_affix_on_damage_taken(player: Node2D, damage: float, attacker: Node2D) -> float:
	"""Process affix abilities that trigger when player takes damage. Returns modified damage."""
	if player == null:
		return damage

	var character_id = ""
	if CharacterManager:
		character_id = CharacterManager.selected_character_id

	if character_id == "" or not EquipmentManager:
		return damage

	var on_damage_abilities = EquipmentManager.get_affix_abilities_by_trigger(character_id, "on_damage_taken")
	var modified_damage = damage

	for ability_data in on_damage_abilities:
		var data = ability_data.data
		var chance = data.get("chance", 1.0)

		match data.effect:
			"reflect":
				if attacker != null and is_instance_valid(attacker) and attacker.has_method("take_damage"):
					var reflect_damage = damage * data.get("reflect_percent", 0.15)
					attacker.take_damage(reflect_damage)
			"block":
				if randf() < chance:
					modified_damage = 0.0  # Block all damage
					_spawn_block_effect(player.global_position)
			"counter_attack":
				_affix_trigger_counter_attack(player.global_position, damage * data.get("damage_mult", 0.2), data.get("radius", 80.0))

	return modified_damage

func process_affix_periodic(delta: float, player: Node2D) -> void:
	"""Process periodic affix abilities."""
	if player == null or player.is_dead:
		return

	# Update speed boost timer
	if affix_speed_boost_active:
		affix_speed_boost_timer -= delta
		if affix_speed_boost_timer <= 0:
			affix_speed_boost_active = false
			affix_speed_boost_mult = 1.0

	var character_id = ""
	if CharacterManager:
		character_id = CharacterManager.selected_character_id

	if character_id == "" or not EquipmentManager:
		return

	var periodic_abilities = EquipmentManager.get_affix_abilities_by_trigger(character_id, "periodic")

	for ability_data in periodic_abilities:
		var affix_id = ability_data.id
		var data = ability_data.data
		var interval = data.get("interval", 1.0)

		# Initialize timer if needed
		if not affix_periodic_timers.has(affix_id):
			affix_periodic_timers[affix_id] = 0.0

		affix_periodic_timers[affix_id] += delta

		if affix_periodic_timers[affix_id] >= interval:
			affix_periodic_timers[affix_id] = 0.0

			match data.effect:
				"aura_damage":
					_affix_trigger_aura_damage(player, data.get("damage_mult", 0.05), data.get("radius", 80.0))
				"aura_slow":
					_affix_trigger_aura_slow(player, data.get("slow_percent", 0.15), data.get("radius", 100.0))

func get_affix_speed_multiplier() -> float:
	"""Get speed multiplier from affix abilities."""
	if affix_speed_boost_active:
		return 1.0 + affix_speed_boost_mult
	return 1.0

# ============================================
# AFFIX ABILITY EFFECT IMPLEMENTATIONS
# ============================================

func _affix_trigger_lightning(enemy: Node2D, player: Node2D, damage: float) -> void:
	"""Trigger mini lightning chain."""
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	if enemy.has_method("apply_shock"):
		enemy.apply_shock(damage * 0.5)
	trigger_lightning_at(enemy.global_position)

func _affix_trigger_freeze(enemy: Node2D, slow_percent: float, duration: float) -> void:
	"""Apply slow to enemy."""
	if enemy.has_method("apply_slow"):
		enemy.apply_slow(slow_percent, duration)
	elif enemy.has_method("apply_chill"):
		enemy.apply_chill(duration)

func _affix_trigger_bleed(enemy: Node2D, damage: float, duration: float) -> void:
	"""Apply bleed DoT to enemy."""
	if enemy.has_method("apply_bleed"):
		enemy.apply_bleed(damage, duration)

func _affix_trigger_burn(enemy: Node2D, duration: float) -> void:
	"""Apply burn to enemy."""
	if enemy.has_method("apply_burn"):
		enemy.apply_burn(duration)

func _affix_trigger_poison(enemy: Node2D, damage: float, duration: float) -> void:
	"""Apply poison to enemy."""
	if enemy.has_method("apply_poison"):
		enemy.apply_poison(damage, duration)

func _affix_trigger_knockback(enemy: Node2D, player: Node2D, force: float) -> void:
	"""Knock enemy back from player."""
	if enemy.has_method("apply_knockback"):
		var direction = (enemy.global_position - player.global_position).normalized()
		enemy.apply_knockback(direction * force)

func _affix_trigger_execute(enemy: Node2D, bonus_damage: float, hp_threshold: float) -> void:
	"""Deal bonus damage if enemy below HP threshold."""
	if enemy.has_method("get_health_percent"):
		if enemy.get_health_percent() < hp_threshold:
			if enemy.has_method("take_damage"):
				enemy.take_damage(bonus_damage)

func _affix_trigger_stun(enemy: Node2D, duration: float) -> void:
	"""Stun enemy briefly."""
	if enemy.has_method("apply_stun"):
		enemy.apply_stun(duration)

func _affix_trigger_explosion(pos: Vector2, damage: float, radius: float) -> void:
	"""Create small explosion at position."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(pos) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
	spawn_explosion_effect(pos)

func _affix_trigger_speed_boost(speed_mult: float, duration: float) -> void:
	"""Apply temporary speed boost."""
	affix_speed_boost_active = true
	affix_speed_boost_timer = duration
	affix_speed_boost_mult = speed_mult

func _affix_trigger_chain_damage(pos: Vector2, damage: float, radius: float) -> void:
	"""Deal damage to nearest enemy within radius."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_dist = radius

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = enemy.global_position.distance_to(pos)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = enemy

	if closest_enemy != null and closest_enemy.has_method("take_damage"):
		closest_enemy.take_damage(damage)

func _affix_trigger_counter_attack(pos: Vector2, damage: float, radius: float) -> void:
	"""Counter attack nearby enemies."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(pos) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

func _affix_trigger_aura_damage(player: Node2D, damage_mult: float, radius: float) -> void:
	"""Deal periodic damage to nearby enemies."""
	var base_damage = 10.0
	if player.has_method("get_attack_damage"):
		base_damage = player.get_attack_damage()
	var damage = base_damage * damage_mult

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

func _affix_trigger_aura_slow(player: Node2D, slow_percent: float, radius: float) -> void:
	"""Apply slow aura to nearby enemies."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) <= radius:
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(slow_percent, 0.6)

func _spawn_block_effect(pos: Vector2) -> void:
	"""Spawn visual effect for blocked damage."""
	var particles = CPUParticles2D.new()
	particles.global_position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.2
	particles.direction = Vector2.UP
	particles.spread = 60
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.8, 0.8, 1.0, 0.9)  # Light blue/white

	get_tree().current_scene.add_child(particles)
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(func(): particles.queue_free())

func reset_affix_abilities() -> void:
	"""Reset affix ability state (called on run start)."""
	affix_periodic_timers.clear()
	affix_speed_boost_active = false
	affix_speed_boost_timer = 0.0
	affix_speed_boost_mult = 1.0
