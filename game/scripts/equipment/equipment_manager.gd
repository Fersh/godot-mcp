extends Node

# Equipment Manager - Handles inventory, equipment, and item generation
# Add to autoload as "EquipmentManager"

signal item_acquired(item: ItemData)
signal item_equipped(item: ItemData, character_id: String)
signal item_unequipped(item: ItemData, character_id: String)
signal inventory_changed()
signal item_sold(item: ItemData, coins: int)
signal items_combined(items: Array, result: ItemData)

# Sorting options
enum SortBy {
	CATEGORY,
	RARITY,
	EQUIPPED,
	NAME,
	ITEM_LEVEL
}

# Sell prices by rarity
const SELL_PRICES: Dictionary = {
	ItemData.Rarity.COMMON: 5,
	ItemData.Rarity.MAGIC: 15,
	ItemData.Rarity.RARE: 50,
	ItemData.Rarity.UNIQUE: 150,
	ItemData.Rarity.LEGENDARY: 500
}

const SAVE_PATH = "user://equipment.save"

# All owned items (permanent collection)
var inventory: Array[ItemData] = []

# Items picked up this run (not yet permanent until run ends or banked)
var pending_items: Array[ItemData] = []

# Equipment slots per character
# Format: { "archer": { Slot.WEAPON: item_id, ... }, "knight": { ... } }
var equipped_items: Dictionary = {
	"archer": {},
	"knight": {},
	"mage": {},
	"monk": {},
	"beast": {},
	"barbarian": {},
	"assassin": {}
}

# Track next unique item ID
var next_item_id: int = 1

# Current game time (for rarity scaling)
var current_game_time: float = 0.0

func _ready() -> void:
	load_data()

func reset_run() -> void:
	pending_items.clear()
	current_game_time = 0.0

func update_game_time(time: float) -> void:
	current_game_time = time

# Generate a new item drop
func generate_item(enemy_type: String = "normal", forced_slot: int = -1) -> ItemData:
	var item = ItemData.new()
	item.id = "item_%d" % next_item_id
	next_item_id += 1

	# Get current character for weapon filtering
	var character_id = ""
	if CharacterManager:
		character_id = CharacterManager.selected_character_id

	# Determine slot
	var slot: ItemData.Slot
	if forced_slot >= 0:
		slot = forced_slot as ItemData.Slot
	else:
		slot = _get_random_slot()
	item.slot = slot

	# Determine rarity based on game time and enemy type
	var rarity = _roll_rarity(enemy_type)
	item.rarity = rarity

	# Generate item based on rarity
	match rarity:
		ItemData.Rarity.COMMON:
			_generate_common_item(item, slot, character_id)
		ItemData.Rarity.MAGIC:
			_generate_magic_item(item, slot, character_id)
		ItemData.Rarity.RARE:
			_generate_rare_item(item, slot, character_id)
		ItemData.Rarity.UNIQUE:
			_generate_unique_item(item, slot, character_id)
		ItemData.Rarity.LEGENDARY:
			_generate_legendary_item(item, slot, character_id)

	# Set item level based on game time
	item.item_level = max(1, int(current_game_time / 30.0) + 1)

	# Scale stats with item level
	_scale_item_stats(item)

	return item

func _get_random_slot() -> ItemData.Slot:
	var slots = [
		ItemData.Slot.WEAPON,
		ItemData.Slot.HELMET,
		ItemData.Slot.CHEST,
		ItemData.Slot.BELT,
		ItemData.Slot.LEGS,
		ItemData.Slot.RING
	]
	# Weight weapons slightly higher
	var weighted = [
		ItemData.Slot.WEAPON, ItemData.Slot.WEAPON,
		ItemData.Slot.HELMET,
		ItemData.Slot.CHEST,
		ItemData.Slot.BELT,
		ItemData.Slot.LEGS,
		ItemData.Slot.RING
	]
	return weighted[randi() % weighted.size()]

func _roll_rarity(enemy_type: String) -> ItemData.Rarity:
	# Base weights
	var weights = ItemData.BASE_DROP_WEIGHTS.duplicate()

	# Time bonus: every 60 seconds, shift weights toward rarer items
	var time_bonus = current_game_time / 60.0
	weights[ItemData.Rarity.COMMON] = max(20.0, weights[ItemData.Rarity.COMMON] - time_bonus * 5)
	weights[ItemData.Rarity.MAGIC] += time_bonus * 2
	weights[ItemData.Rarity.RARE] += time_bonus * 1.5
	weights[ItemData.Rarity.UNIQUE] += time_bonus * 0.8
	weights[ItemData.Rarity.LEGENDARY] += time_bonus * 0.3

	# Enemy type bonus
	match enemy_type:
		"elite":
			weights[ItemData.Rarity.RARE] *= 2.0
			weights[ItemData.Rarity.UNIQUE] *= 2.0
			weights[ItemData.Rarity.LEGENDARY] *= 1.5
		"boss":
			weights[ItemData.Rarity.COMMON] *= 0.2
			weights[ItemData.Rarity.MAGIC] *= 0.5
			weights[ItemData.Rarity.RARE] *= 2.0
			weights[ItemData.Rarity.UNIQUE] *= 3.0
			weights[ItemData.Rarity.LEGENDARY] *= 4.0

	# Calculate total and roll
	var total = 0.0
	for rarity in weights:
		total += weights[rarity]

	var roll = randf() * total
	var cumulative = 0.0

	for rarity in [ItemData.Rarity.LEGENDARY, ItemData.Rarity.UNIQUE,
				   ItemData.Rarity.RARE, ItemData.Rarity.MAGIC, ItemData.Rarity.COMMON]:
		cumulative += weights[rarity]
		if roll <= cumulative:
			return rarity

	return ItemData.Rarity.COMMON

func _generate_common_item(item: ItemData, slot: ItemData.Slot, character_id: String = "") -> void:
	# Use character-filtered items for weapons
	var base_ids: Array
	if slot == ItemData.Slot.WEAPON and character_id != "":
		base_ids = ItemDatabase.get_base_item_ids_for_character(slot, character_id)
	else:
		base_ids = ItemDatabase.get_base_item_ids_for_slot(slot)

	if base_ids.size() == 0:
		return

	var base_id = base_ids[randi() % base_ids.size()]
	var base = ItemDatabase.BASE_ITEMS[base_id]

	item.base_id = base_id
	item.display_name = base.get("display_name", "Item")
	item.icon_path = base.get("icon_path", "")
	item.weapon_type = base.get("weapon_type", ItemData.WeaponType.NONE)
	item.base_stats = base.get("base_stats", {}).duplicate()

func _generate_magic_item(item: ItemData, slot: ItemData.Slot, character_id: String = "") -> void:
	# Start with common base
	_generate_common_item(item, slot, character_id)

	# Add one magic property (prefix OR suffix)
	if randf() > 0.5:
		var prefix_data = ItemDatabase.get_random_prefix()
		item.prefix = prefix_data.name
		item.magic_stats = prefix_data.stats.duplicate()
	else:
		var suffix_data = ItemDatabase.get_random_suffix()
		item.suffix = suffix_data.name
		item.magic_stats = suffix_data.stats.duplicate()

	# Upgrade icons for magic rarity (icons 9-18)
	var icon_num = randi_range(9, 18)
	match slot:
		ItemData.Slot.HELMET:
			item.icon_path = "res://assets/sprites/items/helmet/PNG/Transperent/Icon%d.png" % icon_num
		ItemData.Slot.CHEST:
			item.icon_path = "res://assets/sprites/items/chest/PNG/Transperent/Icon%d.png" % icon_num
		ItemData.Slot.BELT:
			item.icon_path = "res://assets/sprites/items/Belt/PNG/Transperent/Icon%d.png" % icon_num
		ItemData.Slot.LEGS:
			item.icon_path = "res://assets/sprites/items/Legs/PNG/Transperent/Icon%d.png" % icon_num
		ItemData.Slot.WEAPON:
			if item.weapon_type == ItemData.WeaponType.RANGED:
				item.icon_path = "res://assets/sprites/items/Bow/PNG/Transperent/Icon%d.png" % icon_num
			elif item.weapon_type == ItemData.WeaponType.DAGGER:
				item.icon_path = "res://assets/sprites/items/daggers/PNG/Transperent/Icon%d.png" % icon_num

func _generate_rare_item(item: ItemData, slot: ItemData.Slot, character_id: String = "") -> void:
	# Start with common base
	_generate_common_item(item, slot, character_id)

	# Add two magic properties (prefix AND suffix)
	var prefix_data = ItemDatabase.get_random_prefix()
	var suffix_data = ItemDatabase.get_random_suffix()

	item.prefix = prefix_data.name
	item.suffix = suffix_data.name

	# Combine stats
	item.magic_stats = prefix_data.stats.duplicate()
	for stat in suffix_data.stats:
		if item.magic_stats.has(stat):
			item.magic_stats[stat] += suffix_data.stats[stat]
		else:
			item.magic_stats[stat] = suffix_data.stats[stat]

	# Upgrade icons for rare rarity (icons 19-30)
	var icon_num = randi_range(19, 30)
	match slot:
		ItemData.Slot.HELMET:
			item.icon_path = "res://assets/sprites/items/helmet/PNG/Transperent/Icon%d.png" % icon_num
		ItemData.Slot.CHEST:
			item.icon_path = "res://assets/sprites/items/chest/PNG/Transperent/Icon%d.png" % icon_num
		ItemData.Slot.BELT:
			item.icon_path = "res://assets/sprites/items/Belt/PNG/Transperent/Icon%d.png" % icon_num
		ItemData.Slot.LEGS:
			item.icon_path = "res://assets/sprites/items/Legs/PNG/Transperent/Icon%d.png" % icon_num
		ItemData.Slot.WEAPON:
			if item.weapon_type == ItemData.WeaponType.RANGED:
				item.icon_path = "res://assets/sprites/items/Bow/PNG/Transperent/Icon%d.png" % icon_num
			elif item.weapon_type == ItemData.WeaponType.DAGGER:
				item.icon_path = "res://assets/sprites/items/daggers/PNG/Transperent/Icon%d.png" % icon_num

func _generate_unique_item(item: ItemData, slot: ItemData.Slot, character_id: String = "") -> void:
	var unique_ids = ItemDatabase.get_unique_items_for_slot(slot, character_id)
	if unique_ids.size() == 0:
		# Fallback to rare
		_generate_rare_item(item, slot, character_id)
		return

	var unique_id = unique_ids[randi() % unique_ids.size()]
	var unique = ItemDatabase.UNIQUE_ITEMS[unique_id]

	item.base_id = unique_id
	item.display_name = unique.get("display_name", "Unique Item")
	item.description = unique.get("description", "")
	item.icon_path = unique.get("icon_path", "")
	item.weapon_type = unique.get("weapon_type", ItemData.WeaponType.NONE)
	item.base_stats = unique.get("base_stats", {}).duplicate()
	item.grants_ability = unique.get("grants_ability", "")
	item.grants_equipment_ability = unique.get("grants_equipment_ability", "")

func _generate_legendary_item(item: ItemData, slot: ItemData.Slot, character_id: String = "") -> void:
	var legendary_ids = ItemDatabase.get_legendary_items_for_slot(slot, character_id)
	if legendary_ids.size() == 0:
		# Fallback to unique
		_generate_unique_item(item, slot, character_id)
		return

	var legendary_id = legendary_ids[randi() % legendary_ids.size()]
	var legendary = ItemDatabase.LEGENDARY_ITEMS[legendary_id]

	item.base_id = legendary_id
	item.display_name = legendary.get("display_name", "Legendary Item")
	item.description = legendary.get("description", "")
	item.icon_path = legendary.get("icon_path", "")
	item.weapon_type = legendary.get("weapon_type", ItemData.WeaponType.NONE)
	item.base_stats = legendary.get("base_stats", {}).duplicate()
	item.grants_ability = legendary.get("grants_ability", "")
	item.grants_equipment_ability = legendary.get("grants_equipment_ability", "")

func _scale_item_stats(item: ItemData) -> void:
	# Scale base stats with item level (5% per level)
	var level_multiplier = 1.0 + (item.item_level - 1) * 0.05

	for stat in item.base_stats:
		item.base_stats[stat] *= level_multiplier

	for stat in item.magic_stats:
		item.magic_stats[stat] *= level_multiplier

# Check if an item should drop from this enemy
func should_drop_item(enemy_type: String = "normal") -> bool:
	var base_chance = 0.005  # 0.5% base drop rate (halved)

	# Time bonus
	base_chance += current_game_time / 600.0 * 0.005  # +0.5% over 10 minutes

	# Enemy type bonus
	match enemy_type:
		"elite":
			base_chance *= 3.0
		"boss":
			base_chance = 1.0  # Guaranteed drop

	# Luck bonus from abilities
	if AbilityManager:
		base_chance *= AbilityManager.get_luck_multiplier()

	return randf() < base_chance

# Add item to pending (picked up this run)
func add_pending_item(item: ItemData) -> void:
	pending_items.append(item)
	emit_signal("item_acquired", item)

# Commit pending items to permanent inventory (called on run end if survived or at checkpoints)
func commit_pending_items() -> void:
	for item in pending_items:
		inventory.append(item)
	pending_items.clear()
	emit_signal("inventory_changed")
	save_data()

# Get item by ID from either inventory or pending
func get_item(item_id: String) -> ItemData:
	for item in inventory:
		if item.id == item_id:
			return item
	for item in pending_items:
		if item.id == item_id:
			return item
	return null

# Equip item to character
func equip_item(item_id: String, character_id: String, slot: ItemData.Slot) -> bool:
	var item = get_item(item_id)
	if item == null:
		return false

	# Check if item can be equipped by this character
	if not item.can_be_equipped_by(character_id):
		return false

	# Unequip from current owner if any
	if item.equipped_by != "":
		unequip_item_from_character(item.equipped_by, item.slot)

	# Unequip current item in slot if any
	var current_item_id = equipped_items[character_id].get(slot, "")
	if current_item_id != "":
		var current_item = get_item(current_item_id)
		if current_item:
			current_item.equipped_by = ""
			emit_signal("item_unequipped", current_item, character_id)

	# Equip new item
	equipped_items[character_id][slot] = item_id
	item.equipped_by = character_id
	item.slot = slot  # Update slot in case it's a ring going to different slot

	emit_signal("item_equipped", item, character_id)
	emit_signal("inventory_changed")
	save_data()
	return true

# Unequip item from character's slot
func unequip_item_from_character(character_id: String, slot: ItemData.Slot) -> void:
	var item_id = equipped_items[character_id].get(slot, "")
	if item_id == "":
		return

	var item = get_item(item_id)
	if item:
		item.equipped_by = ""
		emit_signal("item_unequipped", item, character_id)

	equipped_items[character_id].erase(slot)
	emit_signal("inventory_changed")
	save_data()

# Get equipped item for character in slot
func get_equipped_item(character_id: String, slot: ItemData.Slot) -> ItemData:
	var item_id = equipped_items[character_id].get(slot, "")
	if item_id == "":
		return null
	return get_item(item_id)

# Get all equipped items for character
func get_all_equipped_items(character_id: String) -> Array[ItemData]:
	var items: Array[ItemData] = []
	for slot in equipped_items[character_id]:
		var item = get_equipped_item(character_id, slot)
		if item:
			items.append(item)
	return items

# Get total stats from all equipped items for character
func get_equipment_stats(character_id: String) -> Dictionary:
	var total_stats = {}
	var items = get_all_equipped_items(character_id)

	for item in items:
		var item_stats = item.get_all_stats()
		for stat in item_stats:
			if total_stats.has(stat):
				total_stats[stat] += item_stats[stat]
			else:
				total_stats[stat] = item_stats[stat]

	return total_stats

# Get granted abilities from equipment
func get_equipment_abilities(character_id: String) -> Array[String]:
	var abilities: Array[String] = []
	var items = get_all_equipped_items(character_id)

	for item in items:
		if item.grants_ability != "":
			abilities.append(item.grants_ability)

	return abilities

# Get equipment-exclusive abilities from equipment
func get_equipment_exclusive_abilities(character_id: String) -> Array[String]:
	var abilities: Array[String] = []
	var items = get_all_equipped_items(character_id)

	for item in items:
		if item.grants_equipment_ability != "":
			abilities.append(item.grants_equipment_ability)

	return abilities

# Get all items not currently equipped
func get_unequipped_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for item in inventory:
		if item.equipped_by == "":
			items.append(item)
	return items

# Get items filtered by slot
func get_items_for_slot(slot: ItemData.Slot) -> Array[ItemData]:
	var items: Array[ItemData] = []
	for item in inventory:
		if item.slot == slot:
			items.append(item)
	return items

# Compare two items and return stat differences
func compare_items(new_item: ItemData, old_item: ItemData) -> Dictionary:
	var comparison = {}
	var new_stats = new_item.get_all_stats() if new_item else {}
	var old_stats = old_item.get_all_stats() if old_item else {}

	# Get all stat keys
	var all_keys = {}
	for key in new_stats:
		all_keys[key] = true
	for key in old_stats:
		all_keys[key] = true

	# Calculate differences
	for stat in all_keys:
		var new_val = new_stats.get(stat, 0.0)
		var old_val = old_stats.get(stat, 0.0)
		var diff = new_val - old_val

		comparison[stat] = {
			"new": new_val,
			"old": old_val,
			"diff": diff,
			"improved": diff > 0
		}

	return comparison

# Save equipment data
func save_data() -> void:
	var save_data = {
		"next_item_id": next_item_id,
		"inventory": [],
		"equipped_items": equipped_items
	}

	for item in inventory:
		save_data.inventory.append(item.to_save_dict())

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

# Load equipment data
func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()

		if data is Dictionary:
			next_item_id = data.get("next_item_id", 1)
			equipped_items = data.get("equipped_items", {"archer": {}, "knight": {}, "mage": {}, "monk": {}, "beast": {}})

			# Ensure all characters exist
			for char_id in ["archer", "knight", "mage", "monk", "beast", "barbarian", "assassin"]:
				if not equipped_items.has(char_id):
					equipped_items[char_id] = {}

			inventory.clear()
			var inv_data = data.get("inventory", [])
			for item_data in inv_data:
				var item = ItemData.from_save_dict(item_data)
				inventory.append(item)

# Get sorted inventory
func get_sorted_inventory(sort_by: SortBy, ascending: bool = true) -> Array[ItemData]:
	var sorted_items: Array[ItemData] = inventory.duplicate()

	match sort_by:
		SortBy.CATEGORY:
			sorted_items.sort_custom(func(a, b):
				if ascending:
					return a.slot < b.slot
				return a.slot > b.slot
			)
		SortBy.RARITY:
			sorted_items.sort_custom(func(a, b):
				if ascending:
					return a.rarity > b.rarity  # Higher rarity first by default
				return a.rarity < b.rarity
			)
		SortBy.EQUIPPED:
			sorted_items.sort_custom(func(a, b):
				var a_equipped = a.equipped_by != ""
				var b_equipped = b.equipped_by != ""
				if ascending:
					return a_equipped and not b_equipped  # Equipped first
				return not a_equipped and b_equipped
			)
		SortBy.NAME:
			sorted_items.sort_custom(func(a, b):
				if ascending:
					return a.get_full_name().to_lower() < b.get_full_name().to_lower()
				return a.get_full_name().to_lower() > b.get_full_name().to_lower()
			)
		SortBy.ITEM_LEVEL:
			sorted_items.sort_custom(func(a, b):
				if ascending:
					return a.item_level > b.item_level  # Higher level first by default
				return a.item_level < b.item_level
			)

	return sorted_items

# Get sell price for an item
func get_sell_price(item: ItemData) -> int:
	var base_price = SELL_PRICES.get(item.rarity, 5)
	# Scale by item level (10% per level)
	var level_bonus = 1.0 + (item.item_level - 1) * 0.1
	return int(base_price * level_bonus)

# Sell an item for coins
func sell_item(item_id: String) -> int:
	var item = get_item(item_id)
	if item == null:
		return 0

	# Cannot sell equipped items
	if item.equipped_by != "":
		return 0

	var sell_price = get_sell_price(item)

	# Remove from inventory
	inventory.erase(item)

	# Add coins to spendable currency
	if StatsManager:
		StatsManager.spendable_coins += sell_price
		StatsManager.save_stats()

	emit_signal("item_sold", item, sell_price)
	emit_signal("inventory_changed")
	save_data()

	return sell_price

# Find items that can be combined (same slot + same rarity)
func get_combinable_groups() -> Dictionary:
	# Returns: { "slot_rarity_key": [item1, item2, item3, ...], ... }
	var groups: Dictionary = {}

	for item in inventory:
		# Skip equipped items
		if item.equipped_by != "":
			continue
		# Skip legendary items (can't upgrade further)
		if item.rarity == ItemData.Rarity.LEGENDARY:
			continue

		var key = "%d_%d" % [item.slot, item.rarity]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(item)

	# Filter to only groups with 3+ items
	var combinable: Dictionary = {}
	for key in groups:
		if groups[key].size() >= 3:
			combinable[key] = groups[key]

	return combinable

# Check if an item can be part of a combine
func can_combine_item(item: ItemData) -> bool:
	if item.equipped_by != "":
		return false
	if item.rarity == ItemData.Rarity.LEGENDARY:
		return false

	var key = "%d_%d" % [item.slot, item.rarity]
	var groups = get_combinable_groups()
	return groups.has(key)

# Get count of combinable items matching this item's slot/rarity
func get_combinable_count(item: ItemData) -> int:
	if item.equipped_by != "":
		return 0
	if item.rarity == ItemData.Rarity.LEGENDARY:
		return 0

	var count = 0
	for inv_item in inventory:
		if inv_item.equipped_by != "":
			continue
		if inv_item.slot == item.slot and inv_item.rarity == item.rarity:
			count += 1
	return count

# Combine 3 items into 1 higher rarity
func combine_items(item_ids: Array) -> ItemData:
	if item_ids.size() != 3:
		return null

	var items: Array[ItemData] = []
	var slot = -1
	var rarity = -1

	# Validate all items
	for item_id in item_ids:
		var item = get_item(item_id)
		if item == null:
			return null
		if item.equipped_by != "":
			return null
		if item.rarity == ItemData.Rarity.LEGENDARY:
			return null

		# Check all items have same slot and rarity
		if slot == -1:
			slot = item.slot
			rarity = item.rarity
		elif item.slot != slot or item.rarity != rarity:
			return null

		items.append(item)

	# Remove the 3 items from inventory
	for item in items:
		inventory.erase(item)

	# Calculate average item level for the new item
	var avg_level = 0
	for item in items:
		avg_level += item.item_level
	avg_level = max(1, avg_level / 3)

	# Generate new item with higher rarity
	var new_rarity = rarity + 1  # Next rarity tier
	var new_item = ItemData.new()
	new_item.id = "item_%d" % next_item_id
	next_item_id += 1
	new_item.slot = slot as ItemData.Slot
	new_item.rarity = new_rarity as ItemData.Rarity
	new_item.item_level = avg_level

	# Get character for weapon filtering
	var character_id = ""
	if CharacterManager:
		character_id = CharacterManager.selected_character_id

	# Generate item based on new rarity
	match new_rarity:
		ItemData.Rarity.MAGIC:
			_generate_magic_item(new_item, new_item.slot, character_id)
		ItemData.Rarity.RARE:
			_generate_rare_item(new_item, new_item.slot, character_id)
		ItemData.Rarity.UNIQUE:
			_generate_unique_item(new_item, new_item.slot, character_id)
		ItemData.Rarity.LEGENDARY:
			_generate_legendary_item(new_item, new_item.slot, character_id)

	# Scale stats with item level
	_scale_item_stats(new_item)

	# Add to inventory
	inventory.append(new_item)

	emit_signal("items_combined", items, new_item)
	emit_signal("inventory_changed")
	save_data()

	return new_item
