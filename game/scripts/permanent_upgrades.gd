extends Node

# Permanent Upgrades Manager - Handles meta-progression upgrades that persist across runs
# Add to autoload as "PermanentUpgrades"

signal upgrade_purchased(upgrade_id: String, new_rank: int)
signal upgrades_refunded(coins_returned: int)

# Upgrade categories for UI organization
enum Category {
	COMBAT,
	SURVIVAL,
	UTILITY,
	PROGRESSION,
	SPECIAL
}

# Upgrade definition structure
class UpgradeDefinition:
	var id: String
	var name: String
	var description: String
	var icon: String  # Icon name/path for UI
	var category: int
	var sort_order: int  # Order within category for display
	var base_cost: int
	var cost_multiplier: float
	var max_rank: int
	var benefit_per_rank: float
	var benefit_type: String  # What stat this affects
	var benefit_format: String  # How to display the benefit (e.g., "+%d%%" or "+%d")

	func _init(p_id: String, p_name: String, p_desc: String, p_icon: String,
			   p_category: int, p_sort: int, p_base_cost: int, p_cost_mult: float,
			   p_max_rank: int, p_benefit: float, p_benefit_type: String, p_format: String):
		id = p_id
		name = p_name
		description = p_desc
		icon = p_icon
		category = p_category
		sort_order = p_sort
		base_cost = p_base_cost
		cost_multiplier = p_cost_mult
		max_rank = p_max_rank
		benefit_per_rank = p_benefit
		benefit_type = p_benefit_type
		benefit_format = p_format

# All upgrade definitions - easily modifiable
var upgrade_definitions: Dictionary = {}

# Current upgrade ranks (persisted)
var upgrade_ranks: Dictionary = {}

# Total coins spent (for refund calculation)
var total_coins_spent: int = 0

func _ready() -> void:
	_init_upgrade_definitions()
	load_upgrades()

func _init_upgrade_definitions() -> void:
	# Combat Upgrades - ordered by importance/commonality
	_add_upgrade("neon_power", "Damage", "Increase all damage dealt", "damage",
		Category.COMBAT, 0, 100, 1.5, 5, 0.20, "damage", "+%d%% damage")

	_add_upgrade("overclocked_emitter", "Atk Speed", "Increase attack speed", "fire_rate",
		Category.COMBAT, 1, 200, 1.6, 5, 0.20, "attack_speed", "+%d%% attack speed")

	_add_upgrade("keen_eye", "Crit Chance", "Increase critical hit chance", "crit_chance",
		Category.COMBAT, 2, 200, 1.5, 5, 0.04, "crit_chance", "+%d%% crit chance")

	_add_upgrade("precision_core", "Crit Damage", "Increase critical hit damage", "crit_damage",
		Category.COMBAT, 3, 250, 1.5, 5, 0.40, "crit_damage", "+%d%% crit damage")

	_add_upgrade("volatile_plasma", "AoE Size", "Increase area of effect size", "aoe",
		Category.COMBAT, 4, 300, 1.5, 5, 0.30, "aoe_size", "+%d%% AoE size")

	_add_upgrade("magnetic_accelerator", "Proj. Speed", "Increase projectile speed", "projectile",
		Category.COMBAT, 5, 100, 1.3, 5, 0.20, "projectile_speed", "+%d%% projectile speed")

	_add_upgrade("split_chamber", "Multishot", "Fire additional projectiles", "multishot",
		Category.COMBAT, 6, 1000, 2.5, 5, 1.0, "projectile_count", "+%d projectile")

	_add_upgrade("twin_blades", "Multiswing", "Melee attacks swing additional times", "double",
		Category.COMBAT, 7, 1000, 2.5, 5, 1.0, "melee_swing_count", "+%d swing")

	_add_upgrade("elemental_mastery", "Elemental", "Increase elemental effect chance", "element",
		Category.COMBAT, 8, 300, 1.5, 5, 0.10, "elemental_chance", "+%d%% elemental procs")

	_add_upgrade("status_amplifier", "Status", "Status effects last longer", "status",
		Category.COMBAT, 9, 250, 1.5, 5, 0.30, "status_duration", "+%d%% status duration")

	_add_upgrade("summoner_bond", "Summons", "Summons deal more damage", "summon",
		Category.COMBAT, 10, 350, 1.6, 5, 0.30, "summon_damage", "+%d%% summon damage")

	_add_upgrade("viral_payload", "Weaken", "Enemies have reduced health", "virus",
		Category.COMBAT, 11, 400, 1.6, 5, 0.10, "enemy_health_reduction", "-%d%% enemy health")

	# Survival Upgrades - ordered by importance/commonality
	_add_upgrade("core_integrity", "Health", "Increase maximum health", "health",
		Category.SURVIVAL, 0, 100, 1.4, 5, 0.20, "max_hp", "+%d%% max HP")

	_add_upgrade("hard_light_shield", "Armor", "Reduce incoming damage", "shield",
		Category.SURVIVAL, 1, 150, 1.6, 5, 0.10, "damage_reduction", "-%d%% incoming damage")

	_add_upgrade("thruster_boost", "Speed", "Increase movement speed", "speed",
		Category.SURVIVAL, 2, 150, 1.5, 5, 0.10, "move_speed", "+%d%% speed")

	_add_upgrade("auto_repair", "Regen", "Regenerate health over time", "regen",
		Category.SURVIVAL, 3, 500, 1.8, 5, 2.0, "hp_regen", "+%d HP/second")

	_add_upgrade("evasion_matrix", "Dodge", "Chance to dodge attacks", "dodge",
		Category.SURVIVAL, 4, 300, 1.6, 5, 0.06, "dodge_chance", "+%d%% dodge")

	_add_upgrade("shield_mastery", "Block", "Chance to block incoming attacks", "block",
		Category.SURVIVAL, 5, 250, 1.6, 5, 0.04, "block_chance", "+%d%% block")

	_add_upgrade("healing_amplifier", "Healing", "Increase all healing received", "heal",
		Category.SURVIVAL, 6, 200, 1.5, 5, 0.20, "healing_received", "+%d%% healing")

	_add_upgrade("life_leech", "Life Leech", "Restore HP on each kill", "lifesteal",
		Category.SURVIVAL, 7, 150, 1.5, 5, 2.0, "hp_on_kill", "+%d HP per kill")

	# Utility Upgrades - ordered by importance/commonality
	_add_upgrade("attractor_beam", "Magnet", "Increase pickup range", "magnet",
		Category.UTILITY, 0, 100, 1.3, 5, 0.40, "pickup_range", "+%d%% range")

	_add_upgrade("cooldown_matrix", "Cooldown", "Reduce ability cooldowns", "cooldown",
		Category.UTILITY, 1, 200, 1.5, 5, 0.10, "cooldown_reduction", "-%d%% cooldowns")

	_add_upgrade("stable_fields", "Duration", "Powerups last longer", "duration",
		Category.UTILITY, 2, 200, 1.4, 5, 0.20, "powerup_duration", "+%d%% duration")

	_add_upgrade("quantum_flux", "Luck", "Increase luck for crits and drops", "luck",
		Category.UTILITY, 3, 250, 1.5, 5, 0.20, "luck", "+%d%% luck")

	_add_upgrade("aura_expansion", "Aura Range", "Increase aura and orbital range", "aura",
		Category.UTILITY, 4, 250, 1.5, 5, 0.20, "aura_range", "+%d%% aura range")

	# Progression Upgrades - ordered by importance/commonality
	_add_upgrade("data_mining", "XP Gain", "Gain more experience", "xp",
		Category.PROGRESSION, 0, 200, 1.4, 5, 0.20, "xp_gain", "+%d%% XP")

	_add_upgrade("coin_magnet", "Coins", "Find more coins", "coins",
		Category.PROGRESSION, 1, 300, 1.4, 5, 0.20, "coin_gain", "+%d%% coins")

	_add_upgrade("score_multiplier", "Score", "Earn more points", "score",
		Category.PROGRESSION, 2, 500, 1.5, 5, 0.20, "points_gain", "+%d%% points")

	# Special Upgrades - ordered by importance/commonality
	_add_upgrade("starting_arsenal", "Starter", "Begin runs with a random ability", "starter",
		Category.SPECIAL, 0, 2000, 3.0, 3, 2.0, "starting_abilities", "+%d starting abilities")

	_add_upgrade("emergency_reboot", "Revive", "Revive once per run at 50%% HP", "revive",
		Category.SPECIAL, 1, 5000, 10.0, 1, 1.0, "revive", "Revive once per run")

	_add_upgrade("daredevil_protocol", "Daredevil", "Harder enemies, more points", "skull",
		Category.SPECIAL, 2, 50, 1.4, 10, 0.20, "daredevil", "+%d0%% difficulty, +%d0%% points")

func _add_upgrade(id: String, uname: String, desc: String, icon: String,
				  category: int, sort_order: int, base_cost: int, cost_mult: float,
				  max_rank: int, benefit: float, benefit_type: String, format: String) -> void:
	upgrade_definitions[id] = UpgradeDefinition.new(
		id, uname, desc, icon, category, sort_order, base_cost, cost_mult, max_rank, benefit, benefit_type, format
	)
	# Initialize rank to 0 if not loaded
	if not upgrade_ranks.has(id):
		upgrade_ranks[id] = 0

# Get all upgrades in a category
func get_upgrades_by_category(category: int) -> Array:
	var result: Array = []
	for id in upgrade_definitions:
		if upgrade_definitions[id].category == category:
			result.append(upgrade_definitions[id])
	return result

# Get all upgrade definitions
func get_all_upgrades() -> Array:
	return upgrade_definitions.values()

# Get upgrade by ID
func get_upgrade(id: String) -> UpgradeDefinition:
	return upgrade_definitions.get(id)

# Get current rank of an upgrade
func get_rank(id: String) -> int:
	return upgrade_ranks.get(id, 0)

# Calculate cost for next rank
func get_upgrade_cost(id: String) -> int:
	var upgrade = get_upgrade(id)
	if upgrade == null:
		return 0

	var current_rank = get_rank(id)
	if current_rank >= upgrade.max_rank:
		return 0  # Already maxed

	# Cost = baseCost × (costMultiplier ^ currentRank)
	var base_calculated_cost = upgrade.base_cost * pow(upgrade.cost_multiplier, current_rank)

	# Apply additional rank multiplier for rank 2+ (next rank is current_rank + 1)
	# Rank 2: +50%, Rank 3: +45%, Rank 4: +40%, Rank 5+: +35%
	var next_rank = current_rank + 1
	var rank_multiplier = 1.0
	if next_rank >= 2:
		match next_rank:
			2:
				rank_multiplier = 1.50  # +50%
			3:
				rank_multiplier = 1.45  # +45%
			4:
				rank_multiplier = 1.40  # +40%
			_:
				rank_multiplier = 1.35  # +35% for rank 5+

	return int(base_calculated_cost * rank_multiplier)

# Check if upgrade can be purchased
func can_purchase(id: String) -> bool:
	var upgrade = get_upgrade(id)
	if upgrade == null:
		return false

	var current_rank = get_rank(id)
	if current_rank >= upgrade.max_rank:
		return false

	var cost = get_upgrade_cost(id)
	return StatsManager.spendable_coins >= cost

# Purchase an upgrade
func purchase_upgrade(id: String) -> bool:
	if not can_purchase(id):
		return false

	var cost = get_upgrade_cost(id)
	StatsManager.spendable_coins -= cost
	total_coins_spent += cost
	upgrade_ranks[id] = get_rank(id) + 1

	save_upgrades()
	StatsManager.save_stats()

	emit_signal("upgrade_purchased", id, upgrade_ranks[id])
	return true

# Get the total benefit for an upgrade at its current rank
func get_total_benefit(id: String) -> float:
	var upgrade = get_upgrade(id)
	if upgrade == null:
		return 0.0

	return upgrade.benefit_per_rank * get_rank(id)

# Get formatted benefit string for display
func get_benefit_string(id: String) -> String:
	var upgrade = get_upgrade(id)
	if upgrade == null:
		return ""

	var rank = get_rank(id)
	var total_benefit = upgrade.benefit_per_rank * rank

	# Handle percentage vs flat values
	if "%d%%" in upgrade.benefit_format:
		return upgrade.benefit_format % [int(total_benefit * 100)]
	elif upgrade.id == "daredevil_protocol":
		# Special formatting for daredevil
		return upgrade.benefit_format % [rank, rank * 2]
	else:
		return upgrade.benefit_format % [int(total_benefit)]

# Refund all upgrades
func refund_all() -> int:
	var refunded = total_coins_spent

	# Reset all ranks
	for id in upgrade_ranks:
		upgrade_ranks[id] = 0

	# Return coins
	StatsManager.spendable_coins += total_coins_spent
	total_coins_spent = 0

	save_upgrades()
	StatsManager.save_stats()

	emit_signal("upgrades_refunded", refunded)
	return refunded

# Get all permanent stat bonuses as a dictionary
func get_all_bonuses() -> Dictionary:
	var bonuses: Dictionary = {
		"damage": 0.0,
		"damage_reduction": 0.0,
		"attack_speed": 0.0,
		"aoe_size": 0.0,
		"projectile_speed": 0.0,
		"projectile_count": 0,
		"enemy_health_reduction": 0.0,
		"crit_damage": 0.0,
		"crit_chance": 0.0,
		"block_chance": 0.0,
		"max_hp": 0.0,
		"hp_regen": 0.0,
		"hp_on_kill": 0.0,
		"move_speed": 0.0,
		"dodge_chance": 0.0,
		"powerup_duration": 0.0,
		"pickup_range": 0.0,
		"luck": 0.0,
		"cooldown_reduction": 0.0,
		"elemental_chance": 0.0,
		"status_duration": 0.0,
		"healing_received": 0.0,
		"summon_damage": 0.0,
		"aura_range": 0.0,
		"xp_gain": 0.0,
		"points_gain": 0.0,
		"coin_gain": 0.0,
		"daredevil": 0.0,
		"revive": 0,
		"starting_abilities": 0,
		"melee_swing_count": 0,
	}

	for id in upgrade_ranks:
		var upgrade = get_upgrade(id)
		if upgrade and upgrade_ranks[id] > 0:
			var benefit = upgrade.benefit_per_rank * upgrade_ranks[id]
			if bonuses.has(upgrade.benefit_type):
				if upgrade.benefit_type in ["projectile_count", "revive", "starting_abilities", "melee_swing_count"]:
					bonuses[upgrade.benefit_type] += int(benefit)
				else:
					bonuses[upgrade.benefit_type] += benefit

	return bonuses

# Save upgrades to file
func save_upgrades() -> void:
	var save_data = {
		"upgrade_ranks": upgrade_ranks,
		"total_coins_spent": total_coins_spent
	}

	var file = FileAccess.open("user://upgrades.save", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

# Reset all upgrades (for settings reset)
func reset_all_upgrades() -> void:
	for id in upgrade_ranks:
		upgrade_ranks[id] = 0
	total_coins_spent = 0
	save_upgrades()

# Load upgrades from file
func load_upgrades() -> void:
	if not FileAccess.file_exists("user://upgrades.save"):
		return

	var file = FileAccess.open("user://upgrades.save", FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()

		if data is Dictionary:
			if data.has("upgrade_ranks"):
				for id in data["upgrade_ranks"]:
					upgrade_ranks[id] = data["upgrade_ranks"][id]
			total_coins_spent = data.get("total_coins_spent", 0)

# Get category name for display
func get_category_name(category: int) -> String:
	match category:
		Category.COMBAT:
			return "Combat"
		Category.SURVIVAL:
			return "Survival"
		Category.UTILITY:
			return "Utility"
		Category.PROGRESSION:
			return "Progression"
		Category.SPECIAL:
			return "Special"
	return "Unknown"

# Check if player has revive available
func has_revive() -> bool:
	return get_rank("emergency_reboot") > 0

# Get number of starting abilities
func get_starting_ability_count() -> int:
	return get_rank("starting_arsenal")

# Get daredevil difficulty multiplier
func get_daredevil_multiplier() -> float:
	return 1.0 + get_total_benefit("daredevil_protocol")

# Get daredevil points multiplier
func get_daredevil_points_multiplier() -> float:
	return 1.0 + (get_total_benefit("daredevil_protocol") * 2.0)
