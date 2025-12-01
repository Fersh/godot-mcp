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
	COMMON,    # White - 1 base stat
	MAGIC,     # Blue - base + 1 magic property
	RARE,      # Yellow - base + 2 magic properties
	UNIQUE,    # Purple - fixed name, special ability
	LEGENDARY  # Gold - fixed name, powerful special ability
}

enum WeaponType {
	NONE,
	MELEE,
	RANGED,
	MAGIC,  # Books for mages
	DAGGER  # Daggers for assassins
}

# Rarity colors (WoW-style)
const RARITY_COLORS: Dictionary = {
	Rarity.COMMON: Color(0.9, 0.9, 0.9, 1.0),      # White
	Rarity.MAGIC: Color(0.4, 0.6, 1.0, 1.0),       # Blue
	Rarity.RARE: Color(1.0, 0.85, 0.2, 1.0),       # Yellow
	Rarity.UNIQUE: Color(0.7, 0.3, 0.9, 1.0),      # Purple
	Rarity.LEGENDARY: Color(1.0, 0.6, 0.1, 1.0)   # Gold/Orange
}

const RARITY_NAMES: Dictionary = {
	Rarity.COMMON: "Common",
	Rarity.MAGIC: "Magic",
	Rarity.RARE: "Rare",
	Rarity.UNIQUE: "Unique",
	Rarity.LEGENDARY: "Legendary"
}

const SLOT_NAMES: Dictionary = {
	Slot.WEAPON: "Weapon",
	Slot.HELMET: "Helmet",
	Slot.CHEST: "Chest",
	Slot.BELT: "Belt",
	Slot.LEGS: "Legs",
	Slot.RING: "Ring"
}

# Drop weights by rarity (base %, modified by game time and enemy type)
const BASE_DROP_WEIGHTS: Dictionary = {
	Rarity.COMMON: 82.0,
	Rarity.MAGIC: 15.0,
	Rarity.RARE: 2.5,
	Rarity.UNIQUE: 0.4,
	Rarity.LEGENDARY: 0.1
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

# Item level (affects stat rolls)
@export var item_level: int = 1

# Who has this equipped (character ID or empty)
@export var equipped_by: String = ""

func get_full_name() -> String:
	if rarity == Rarity.UNIQUE or rarity == Rarity.LEGENDARY:
		return display_name

	var name_parts = []
	if prefix != "":
		name_parts.append(prefix)
	name_parts.append(display_name)
	if suffix != "":
		name_parts.append(suffix)

	return " ".join(name_parts)

func get_rarity_color() -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

func get_rarity_name() -> String:
	return RARITY_NAMES.get(rarity, "Common")

func get_slot_name() -> String:
	return SLOT_NAMES.get(slot, "Unknown")

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
		var stat_name = stat.replace("_", " ").capitalize()
		var sign = "+" if value >= 0 else ""

		# Format percentage stats
		if stat in ["crit_chance", "dodge_chance", "block_chance", "attack_speed",
					"move_speed", "damage", "max_hp", "xp_gain", "luck"]:
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

	return "\n".join(lines)

func can_be_equipped_by(character_id: String) -> bool:
	# Check weapon type restrictions
	if slot == Slot.WEAPON:
		if weapon_type == WeaponType.MELEE:
			# Swords for knight & barbarian, spears for monk & beast
			return character_id in ["knight", "beast", "monk", "barbarian"]
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
	new_item.item_level = item_level
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
		"item_level": item_level,
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
	item.rarity = data.get("rarity", Rarity.COMMON)
	item.weapon_type = data.get("weapon_type", WeaponType.NONE)
	item.base_stats = data.get("base_stats", {})
	item.magic_stats = data.get("magic_stats", {})
	item.prefix = data.get("prefix", "")
	item.suffix = data.get("suffix", "")
	item.grants_ability = data.get("grants_ability", "")
	item.grants_equipment_ability = data.get("grants_equipment_ability", "")
	item.item_level = data.get("item_level", 1)
	item.equipped_by = data.get("equipped_by", "")
	return item
