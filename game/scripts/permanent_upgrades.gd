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
	var base_cost: int
	var cost_multiplier: float
	var max_rank: int
	var benefit_per_rank: float
	var benefit_type: String  # What stat this affects
	var benefit_format: String  # How to display the benefit (e.g., "+%d%%" or "+%d")

	func _init(p_id: String, p_name: String, p_desc: String, p_icon: String,
			   p_category: int, p_base_cost: int, p_cost_mult: float,
			   p_max_rank: int, p_benefit: float, p_benefit_type: String, p_format: String):
		id = p_id
		name = p_name
		description = p_desc
		icon = p_icon
		category = p_category
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
	# Combat Upgrades
	_add_upgrade("neon_power", "Neon Power", "Increase all damage dealt", "damage",
		Category.COMBAT, 100, 1.5, 5, 0.10, "damage", "+%d%% damage")

	_add_upgrade("hard_light_shield", "Hard Light Shield", "Reduce incoming damage", "shield",
		Category.COMBAT, 150, 1.6, 5, 0.05, "damage_reduction", "-%d%% incoming damage")

	_add_upgrade("overclocked_emitter", "Overclocked Emitter", "Increase fire rate", "fire_rate",
		Category.COMBAT, 200, 1.6, 5, 0.10, "attack_speed", "+%d%% fire rate")

	_add_upgrade("volatile_plasma", "Volatile Plasma", "Increase area of effect size", "aoe",
		Category.COMBAT, 300, 1.5, 5, 0.15, "aoe_size", "+%d%% AoE size")

	_add_upgrade("magnetic_accelerator", "Magnetic Accelerator", "Increase projectile speed", "projectile",
		Category.COMBAT, 100, 1.3, 5, 0.10, "projectile_speed", "+%d%% projectile speed")

	_add_upgrade("split_chamber", "Split Chamber", "Fire additional projectiles", "multishot",
		Category.COMBAT, 1000, 2.5, 5, 1.0, "projectile_count", "+%d projectile")

	_add_upgrade("viral_payload", "Viral Payload", "Enemies have reduced health", "virus",
		Category.COMBAT, 400, 1.6, 5, 0.05, "enemy_health_reduction", "-%d%% enemy health")

	_add_upgrade("precision_core", "Precision Core", "Increase critical hit damage", "crit_damage",
		Category.COMBAT, 250, 1.5, 5, 0.20, "crit_damage", "+%d%% crit damage")

	# Survival Upgrades
	_add_upgrade("core_integrity", "Core Integrity", "Increase maximum health", "health",
		Category.SURVIVAL, 100, 1.4, 5, 0.10, "max_hp", "+%d%% max HP")

	_add_upgrade("auto_repair", "Auto-Repair", "Regenerate health over time", "regen",
		Category.SURVIVAL, 500, 1.8, 5, 1.0, "hp_regen", "+%d HP/second")

	_add_upgrade("thruster_boost", "Thruster Boost", "Increase movement speed", "speed",
		Category.SURVIVAL, 150, 1.5, 5, 0.05, "move_speed", "+%d%% speed")

	_add_upgrade("evasion_matrix", "Evasion Matrix", "Chance to dodge attacks", "dodge",
		Category.SURVIVAL, 300, 1.6, 5, 0.03, "dodge_chance", "+%d%% dodge")

	# Utility Upgrades
	_add_upgrade("stable_fields", "Stable Fields", "Powerups last longer", "duration",
		Category.UTILITY, 200, 1.4, 5, 0.10, "powerup_duration", "+%d%% duration")

	_add_upgrade("attractor_beam", "Attractor Beam", "Increase pickup range", "magnet",
		Category.UTILITY, 100, 1.3, 5, 0.20, "pickup_range", "+%d%% range")

	_add_upgrade("quantum_flux", "Quantum Flux", "Increase luck for crits and drops", "luck",
		Category.UTILITY, 250, 1.5, 5, 0.10, "luck", "+%d%% luck")

	_add_upgrade("cooldown_matrix", "Cooldown Matrix", "Reduce ability cooldowns", "cooldown",
		Category.UTILITY, 200, 1.5, 5, 0.05, "cooldown_reduction", "-%d%% cooldowns")

	# Progression Upgrades
	_add_upgrade("data_mining", "Data Mining", "Gain more experience", "xp",
		Category.PROGRESSION, 200, 1.4, 5, 0.10, "xp_gain", "+%d%% XP")

	_add_upgrade("score_multiplier", "Score Multiplier", "Earn more points", "score",
		Category.PROGRESSION, 500, 1.5, 5, 0.10, "points_gain", "+%d%% points")

	_add_upgrade("coin_magnet", "Coin Magnet", "Find more coins", "coins",
		Category.PROGRESSION, 300, 1.4, 5, 0.10, "coin_gain", "+%d%% coins")

	# Special Upgrades
	_add_upgrade("daredevil_protocol", "Daredevil Protocol", "Harder enemies, more points", "skull",
		Category.SPECIAL, 100, 1.2, 50, 0.10, "daredevil", "+%d0%% difficulty, +%d0%% points")

	_add_upgrade("emergency_reboot", "Emergency Reboot", "Revive once per run at 50%% HP", "revive",
		Category.SPECIAL, 5000, 10.0, 1, 1.0, "revive", "Revive once per run")

	_add_upgrade("starting_arsenal", "Starting Arsenal", "Begin runs with a random ability", "starter",
		Category.SPECIAL, 2000, 3.0, 3, 1.0, "starting_abilities", "+%d starting ability")

func _add_upgrade(id: String, uname: String, desc: String, icon: String,
				  category: int, base_cost: int, cost_mult: float,
				  max_rank: int, benefit: float, benefit_type: String, format: String) -> void:
	upgrade_definitions[id] = UpgradeDefinition.new(
		id, uname, desc, icon, category, base_cost, cost_mult, max_rank, benefit, benefit_type, format
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
	return int(upgrade.base_cost * pow(upgrade.cost_multiplier, current_rank))

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
		"max_hp": 0.0,
		"hp_regen": 0.0,
		"move_speed": 0.0,
		"dodge_chance": 0.0,
		"powerup_duration": 0.0,
		"pickup_range": 0.0,
		"luck": 0.0,
		"cooldown_reduction": 0.0,
		"xp_gain": 0.0,
		"points_gain": 0.0,
		"coin_gain": 0.0,
		"daredevil": 0.0,
		"revive": 0,
		"starting_abilities": 0,
	}

	for id in upgrade_ranks:
		var upgrade = get_upgrade(id)
		if upgrade and upgrade_ranks[id] > 0:
			var benefit = upgrade.benefit_per_rank * upgrade_ranks[id]
			if bonuses.has(upgrade.benefit_type):
				if upgrade.benefit_type in ["projectile_count", "revive", "starting_abilities"]:
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
