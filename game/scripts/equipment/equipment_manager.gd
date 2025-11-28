extends Node

# Equipment Manager - Handles inventory, equipment, and item generation
# Add to autoload as "EquipmentManager"

signal item_acquired(item: ItemData)
signal item_equipped(item: ItemData, character_id: String)
signal item_unequipped(item: ItemData, character_id: String)
signal inventory_changed()

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
	"beast": {}
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
			_generate_common_item(item, slot)
		ItemData.Rarity.MAGIC:
			_generate_magic_item(item, slot)
		ItemData.Rarity.RARE:
			_generate_rare_item(item, slot)
		ItemData.Rarity.UNIQUE:
			_generate_unique_item(item, slot)
		ItemData.Rarity.LEGENDARY:
			_generate_legendary_item(item, slot)

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
		ItemData.Slot.BOOTS,
		ItemData.Slot.RING_1,
		ItemData.Slot.RING_2
	]
	# Weight weapons slightly higher
	var weighted = [
		ItemData.Slot.WEAPON, ItemData.Slot.WEAPON,
		ItemData.Slot.HELMET,
		ItemData.Slot.CHEST,
		ItemData.Slot.BOOTS,
		ItemData.Slot.RING_1, ItemData.Slot.RING_2
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

func _generate_common_item(item: ItemData, slot: ItemData.Slot) -> void:
	var base_ids = ItemDatabase.get_base_item_ids_for_slot(slot)
	if base_ids.size() == 0:
		return

	var base_id = base_ids[randi() % base_ids.size()]
	var base = ItemDatabase.BASE_ITEMS[base_id]

	item.base_id = base_id
	item.display_name = base.get("display_name", "Item")
	item.icon_path = base.get("icon_path", "")
	item.weapon_type = base.get("weapon_type", ItemData.WeaponType.NONE)
	item.base_stats = base.get("base_stats", {}).duplicate()

func _generate_magic_item(item: ItemData, slot: ItemData.Slot) -> void:
	# Start with common base
	_generate_common_item(item, slot)

	# Add one magic property (prefix OR suffix)
	if randf() > 0.5:
		var prefix_data = ItemDatabase.get_random_prefix()
		item.prefix = prefix_data.name
		item.magic_stats = prefix_data.stats.duplicate()
	else:
		var suffix_data = ItemDatabase.get_random_suffix()
		item.suffix = suffix_data.name
		item.magic_stats = suffix_data.stats.duplicate()

	# Upgrade helmet icon for magic rarity (icons 9-18)
	if slot == ItemData.Slot.HELMET:
		var icon_num = randi_range(9, 18)
		item.icon_path = "res://assets/sprites/items/helmet/PNG/Transperent/Icon%d.png" % icon_num

func _generate_rare_item(item: ItemData, slot: ItemData.Slot) -> void:
	# Start with common base
	_generate_common_item(item, slot)

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

	# Upgrade helmet icon for rare rarity (icons 19-30)
	if slot == ItemData.Slot.HELMET:
		var icon_num = randi_range(19, 30)
		item.icon_path = "res://assets/sprites/items/helmet/PNG/Transperent/Icon%d.png" % icon_num

func _generate_unique_item(item: ItemData, slot: ItemData.Slot) -> void:
	var unique_ids = ItemDatabase.get_unique_items_for_slot(slot)
	if unique_ids.size() == 0:
		# Fallback to rare
		_generate_rare_item(item, slot)
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

func _generate_legendary_item(item: ItemData, slot: ItemData.Slot) -> void:
	var legendary_ids = ItemDatabase.get_legendary_items_for_slot(slot)
	if legendary_ids.size() == 0:
		# Fallback to unique
		_generate_unique_item(item, slot)
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
	var base_chance = 0.01  # 1% base drop rate

	# Time bonus
	base_chance += current_game_time / 600.0 * 0.01  # +1% over 10 minutes

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
		# Rings can go in either ring slot
		if slot in [ItemData.Slot.RING_1, ItemData.Slot.RING_2]:
			if item.slot in [ItemData.Slot.RING_1, ItemData.Slot.RING_2]:
				items.append(item)
		elif item.slot == slot:
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
			for char_id in ["archer", "knight", "mage", "monk", "beast"]:
				if not equipped_items.has(char_id):
					equipped_items[char_id] = {}

			inventory.clear()
			var inv_data = data.get("inventory", [])
			for item_data in inv_data:
				var item = ItemData.from_save_dict(item_data)
				inventory.append(item)
