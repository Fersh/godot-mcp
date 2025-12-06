extends Resource
class_name ItemData

enum Slot {
	WEAPON,
	HELMET,
	CHEST,
	BELT,
	LEGS,
	RING
}

enum Rarity {
	COMMON,    # White - 1-2 base stats
	RARE,      # Blue - 2 base + 1 affix (was MAGIC)
	EPIC,      # Purple - 2-3 base + prefix + suffix, unique names (combines old RARE+UNIQUE)
	LEGENDARY, # Yellow - 2 base + prefix + suffix + ability, unique names
	MYTHIC     # Red - future
}

enum WeaponType {
	NONE,
	MELEE,    # Generic melee (legacy, use specific types below)
	RANGED,   # Bows for rangers
	MAGIC,    # Books (legacy, use STAFF instead)
	DAGGER,   # Daggers for assassins
	SWORD,    # Swords for knights
	AXE,      # Axes for barbarians, minotaur, ratfolk
	SPEAR,    # Spears for monks
	MACE,     # Maces (future)
	STAFF     # Staffs for mages, priest, necromancer
}

# Rarity colors
const RARITY_COLORS: Dictionary = {
	Rarity.COMMON: Color(0.9, 0.9, 0.9, 1.0),      # White
	Rarity.RARE: Color(0.4, 0.6, 1.0, 1.0),        # Blue
	Rarity.EPIC: Color(0.7, 0.3, 0.9, 1.0),        # Purple
	Rarity.LEGENDARY: Color(1.0, 0.85, 0.2, 1.0), # Yellow
	Rarity.MYTHIC: Color(1.0, 0.2, 0.2, 1.0)      # Red
}

const RARITY_NAMES: Dictionary = {
	Rarity.COMMON: "Common",
	Rarity.RARE: "Rare",
	Rarity.EPIC: "Epic",
	Rarity.LEGENDARY: "Legendary",
	Rarity.MYTHIC: "Mythic"
}

const SLOT_NAMES: Dictionary = {
	Slot.WEAPON: "Weapon",
	Slot.HELMET: "Helm",
	Slot.CHEST: "Chest",
	Slot.BELT: "Belt",
	Slot.LEGS: "Legs",
	Slot.RING: "Ring"
}

const WEAPON_TYPE_NAMES: Dictionary = {
	WeaponType.NONE: "Weapon",
	WeaponType.MELEE: "Melee",
	WeaponType.RANGED: "Bow",
	WeaponType.MAGIC: "Book",
	WeaponType.DAGGER: "Dagger",
	WeaponType.SWORD: "Sword",
	WeaponType.AXE: "Axe",
	WeaponType.SPEAR: "Spear",
	WeaponType.MACE: "Mace",
	WeaponType.STAFF: "Staff"
}

# Tier names for difficulty-based item scaling
const TIER_NAMES: Dictionary = {
	0: "Pitiful",
	1: "Easy",
	2: "Normal",
	3: "Nightmare",
	4: "Hell",
	5: "Inferno",
	6: "Thanksgiving"
}

# Tier stat multipliers - Hell (1.5x) is current baseline
const TIER_MULTIPLIERS: Dictionary = {
	0: 0.50,   # Pitiful
	1: 0.70,   # Easy
	2: 0.90,   # Normal
	3: 1.15,   # Nightmare
	4: 1.50,   # Hell (current baseline)
	5: 2.00,   # Inferno
	6: 2.50,   # Thanksgiving
}
# Endless tiers (7+): 2.50 + (tier - 6) * 0.20

# Drop weights by rarity (base %, modified by game time and enemy type)
const BASE_DROP_WEIGHTS: Dictionary = {
	Rarity.COMMON: 70.0,
	Rarity.RARE: 22.0,
	Rarity.EPIC: 6.5,
	Rarity.LEGENDARY: 1.5,
	Rarity.MYTHIC: 0.0  # Disabled for now
}

# Stat roll ranges: {"stat_name": [min, max]}
const BASE_STAT_RANGES: Dictionary = {
	"damage": [0.03, 0.12],
	"max_hp": [0.05, 0.15],
	"attack_speed": [0.03, 0.10],
	"move_speed": [0.02, 0.08],
	"crit_chance": [0.02, 0.08],
	"dodge_chance": [0.02, 0.06],
	"damage_reduction": [0.02, 0.08],
	"xp_gain": [0.05, 0.15],
	"luck": [0.03, 0.10],
	"knockback": [10.0, 40.0],
	"melee_range": [0.05, 0.15],
	"projectile_speed": [0.05, 0.15]
}

const AFFIX_STAT_RANGES: Dictionary = {
	"damage": [0.05, 0.15],
	"max_hp": [0.08, 0.20],
	"attack_speed": [0.05, 0.15],
	"move_speed": [0.05, 0.12],
	"crit_chance": [0.03, 0.12],
	"crit_damage": [0.15, 0.35],
	"cooldown_reduction": [0.05, 0.12],
	"hp_on_kill": [1.0, 5.0],
	"aoe_size": [0.10, 0.25],
	"thorns": [3.0, 10.0],
	"execute_damage": [0.15, 0.30],
	"summon_damage": [0.10, 0.25],
	"dodge_chance": [0.03, 0.10],
	"damage_reduction": [0.05, 0.12]
}

# Unique identifier for this specific item instance
@export var id: String = ""

# Base item template ID (for looking up base stats)
@export var base_id: String = ""

# Display
@export var display_name: String = ""
@export var description: String = ""
@export var icon_path: String = ""

# Classification
@export var slot: Slot = Slot.WEAPON
@export var rarity: Rarity = Rarity.COMMON
@export var weapon_type: WeaponType = WeaponType.NONE  # Only for weapons

# Stats - base stats that scale with item level
@export var base_stats: Dictionary = {}

# Magic properties (prefix/suffix bonuses)
@export var magic_stats: Dictionary = {}

# Prefix and suffix for generated names
@export var prefix: String = ""
@export var suffix: String = ""

# For Unique/Legendary - special ability granted
@export var grants_ability: String = ""  # Ability ID from AbilityDatabase
@export var grants_equipment_ability: String = ""  # Equipment-exclusive ability ID

# Affix-triggered mini abilities (from prefix/suffix)
@export var affix_abilities: Array = []  # Array of ability IDs from AFFIX_ABILITIES

# Item level (legacy - now using tier instead)
@export var item_level: int = 1

# Difficulty tier (0-6 for difficulties, 7+ for endless)
@export var tier: int = 0

# Who has this equipped (character ID or empty)
@export var equipped_by: String = ""

func get_full_name() -> String:
	var base_name: String

	# Epic, Legendary, Mythic always use unique display_name (no prefix/suffix in name)
	if rarity == Rarity.EPIC or rarity == Rarity.LEGENDARY or rarity == Rarity.MYTHIC:
		base_name = display_name
	else:
		# Common and Rare use procedural naming
		var name_parts = []
		if prefix != "":
			name_parts.append(prefix)
		name_parts.append(display_name)
		if suffix != "":
			name_parts.append(suffix)
		base_name = " ".join(name_parts)

	# Append tier name
	var tier_name = get_tier_name()
	return "%s (%s)" % [base_name, tier_name]

func get_tier_name() -> String:
	if tier >= 7:
		return "Endless"
	return TIER_NAMES.get(tier, "Pitiful")

func get_tier_multiplier() -> float:
	if tier >= 7:
		# Endless scaling: 2.50 + 0.20 per tier above 6
		return 2.50 + (tier - 6) * 0.20
	return TIER_MULTIPLIERS.get(tier, 0.50)

func get_rarity_color() -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

func get_rarity_name() -> String:
	return RARITY_NAMES.get(rarity, "Common")

func get_slot_name() -> String:
	return SLOT_NAMES.get(slot, "Unknown")

func get_weapon_type_name() -> String:
	return WEAPON_TYPE_NAMES.get(weapon_type, "Weapon")

func get_all_stats() -> Dictionary:
	var combined = base_stats.duplicate()
	for stat in magic_stats:
		if combined.has(stat):
			combined[stat] += magic_stats[stat]
		else:
			combined[stat] = magic_stats[stat]
	return combined

func get_stat_description() -> String:
	var lines = []
	var all_stats = get_all_stats()

	for stat in all_stats:
		var value = all_stats[stat]

		# Skip effectively zero values
		if abs(value) < 0.001:
			continue

		var stat_name = stat.replace("_", " ").capitalize()
		var sign = "+" if value >= 0 else ""

		# Format percentage stats
		if stat in ["crit_chance", "dodge_chance", "block_chance", "attack_speed",
					"move_speed", "damage", "max_hp", "xp_gain", "luck", "damage_reduction"]:
			lines.append("%s%d%% %s" % [sign, int(value * 100), stat_name])
		else:
			lines.append("%s%d %s" % [sign, int(value), stat_name])

	if grants_ability != "":
		var ability_name = grants_ability.replace("_", " ").capitalize()
		lines.append("Grants: %s" % ability_name)

	if grants_equipment_ability != "":
		# Look up the ability details from ItemDatabase
		if ItemDatabase and ItemDatabase.EQUIPMENT_ABILITIES.has(grants_equipment_ability):
			var ability_info = ItemDatabase.EQUIPMENT_ABILITIES[grants_equipment_ability]
			lines.append("Special: %s" % ability_info.name)
			lines.append("  %s" % ability_info.description)
		else:
			var special_name = grants_equipment_ability.replace("_", " ").capitalize()
			lines.append("Special: %s" % special_name)

	# Show affix-triggered abilities
	for affix_id in affix_abilities:
		if ItemDatabase and ItemDatabase.AFFIX_ABILITIES.has(affix_id):
			var affix_info = ItemDatabase.AFFIX_ABILITIES[affix_id]
			lines.append("+%s" % affix_info.description)

	return "\n".join(lines)

func can_be_equipped_by(character_id: String) -> bool:
	# Check weapon type restrictions
	if slot == Slot.WEAPON:
		# Beast cannot use any weapons - fights with claws
		if character_id == "beast":
			return false
		if weapon_type == WeaponType.MELEE:
			# Legacy generic melee - allow knight, monk, barbarian
			return character_id in ["knight", "monk", "barbarian"]
		elif weapon_type == WeaponType.SWORD:
			# Swords for knight
			return character_id == "knight"
		elif weapon_type == WeaponType.AXE:
			# Axes for barbarian
			return character_id == "barbarian"
		elif weapon_type == WeaponType.SPEAR:
			# Spears for monk
			return character_id == "monk"
		elif weapon_type == WeaponType.MACE:
			# Maces - future, allow knight and barbarian
			return character_id in ["knight", "barbarian"]
		elif weapon_type == WeaponType.RANGED:
			return character_id == "archer"
		elif weapon_type == WeaponType.MAGIC:
			# Mages use books
			return character_id == "mage"
		elif weapon_type == WeaponType.DAGGER:
			# Assassins use daggers
			return character_id == "assassin"
	return true

func duplicate_item() -> ItemData:
	var new_item = ItemData.new()
	new_item.id = id
	new_item.base_id = base_id
	new_item.display_name = display_name
	new_item.description = description
	new_item.icon_path = icon_path
	new_item.slot = slot
	new_item.rarity = rarity
	new_item.weapon_type = weapon_type
	new_item.base_stats = base_stats.duplicate()
	new_item.magic_stats = magic_stats.duplicate()
	new_item.prefix = prefix
	new_item.suffix = suffix
	new_item.grants_ability = grants_ability
	new_item.grants_equipment_ability = grants_equipment_ability
	new_item.affix_abilities = affix_abilities.duplicate()
	new_item.item_level = item_level
	new_item.tier = tier
	new_item.equipped_by = equipped_by
	return new_item

func to_save_dict() -> Dictionary:
	return {
		"id": id,
		"base_id": base_id,
		"display_name": display_name,
		"description": description,
		"icon_path": icon_path,
		"slot": slot,
		"rarity": rarity,
		"weapon_type": weapon_type,
		"base_stats": base_stats,
		"magic_stats": magic_stats,
		"prefix": prefix,
		"suffix": suffix,
		"grants_ability": grants_ability,
		"grants_equipment_ability": grants_equipment_ability,
		"affix_abilities": affix_abilities,
		"item_level": item_level,
		"tier": tier,
		"equipped_by": equipped_by
	}

static func from_save_dict(data: Dictionary) -> ItemData:
	var item = ItemData.new()
	item.id = data.get("id", "")
	item.base_id = data.get("base_id", "")
	item.display_name = data.get("display_name", "")
	item.description = data.get("description", "")
	item.icon_path = data.get("icon_path", "")
	item.slot = data.get("slot", Slot.WEAPON)
	item.weapon_type = data.get("weapon_type", WeaponType.NONE)
	item.base_stats = data.get("base_stats", {})
	item.magic_stats = data.get("magic_stats", {})
	item.prefix = data.get("prefix", "")
	item.suffix = data.get("suffix", "")
	item.grants_ability = data.get("grants_ability", "")
	item.grants_equipment_ability = data.get("grants_equipment_ability", "")
	item.affix_abilities = data.get("affix_abilities", [])
	item.item_level = data.get("item_level", 1)
	item.equipped_by = data.get("equipped_by", "")

	# Load tier, default to 0 for legacy items
	# Migration: old items without tier get tier based on item_level
	if data.has("tier"):
		item.tier = data.get("tier", 0)
	else:
		# Legacy migration: estimate tier from item_level
		item.tier = min(6, max(0, int(data.get("item_level", 1) / 5)))

	# Migration: Convert old rarity values to new system
	# Old: 0=COMMON, 1=MAGIC, 2=RARE, 3=UNIQUE, 4=LEGENDARY
	# New: 0=COMMON, 1=RARE, 2=EPIC, 3=LEGENDARY, 4=MYTHIC
	var old_rarity = data.get("rarity", 0)
	match old_rarity:
		0: item.rarity = Rarity.COMMON     # COMMON → COMMON
		1: item.rarity = Rarity.RARE       # MAGIC → RARE (Blue)
		2: item.rarity = Rarity.EPIC       # RARE → EPIC (Purple)
		3: item.rarity = Rarity.EPIC       # UNIQUE → EPIC (Purple)
		4: item.rarity = Rarity.LEGENDARY  # LEGENDARY → LEGENDARY
		_: item.rarity = Rarity.COMMON

	return item
