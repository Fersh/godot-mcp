extends RefCounted
class_name AbilityPool

# Handles ability pool generation and weighted selection
# Extracted from ability_manager.gd for modularity

# Reference to ability manager for state access
var _manager: Node = null

# Upgrade boost chance for mixed pool (40%)
const UPGRADE_BOOST_CHANCE: float = 0.40

# Passive level tracking for guaranteed upgrades
var passive_selections_since_upgrade: int = 0
const GUARANTEED_UPGRADE_INTERVAL: int = 4  # Guarantee upgrade every 4 passive selections

# Synergy weight boost (slight - 50% increase for synergistic abilities)
const SYNERGY_WEIGHT_BOOST: float = 1.5

func _init(manager: Node) -> void:
	_manager = manager

# ============================================
# PASSIVE ABILITY SELECTION
# ============================================

func get_random_abilities(count: int = 3) -> Array[AbilityData]:
	"""Get random passive abilities for level-up selection"""
	var available = get_available_abilities()
	var choices: Array[AbilityData] = []

	# Check if we need to guarantee an upgrade ability
	var need_guaranteed_upgrade = passive_selections_since_upgrade >= GUARANTEED_UPGRADE_INTERVAL
	var upgrade_included = false

	# If we need a guaranteed upgrade, try to include one
	if need_guaranteed_upgrade:
		var available_upgrades = _get_available_upgrade_abilities(available)
		if available_upgrades.size() > 0:
			var upgrade = pick_weighted_random(available_upgrades, true)
			if upgrade:
				choices.append(upgrade)
				available.erase(upgrade)
				upgrade_included = true

	# Fill remaining slots
	for i in range(count - choices.size()):
		if available.size() == 0:
			break

		var ability = pick_weighted_random(available, true)
		if ability:
			choices.append(ability)
			available.erase(ability)
			if ability.is_upgrade:
				upgrade_included = true

	# Shuffle to randomize positions
	choices.shuffle()

	# Update tracking - reset if upgrade was included
	if upgrade_included:
		passive_selections_since_upgrade = 0

	return choices

func on_passive_selection_made() -> void:
	"""Called when player makes a passive selection - increment counter"""
	passive_selections_since_upgrade += 1

func get_available_abilities() -> Array[AbilityData]:
	"""Get all passive abilities available for selection"""
	var available: Array[AbilityData] = []

	for ability in _manager.all_abilities:
		# Skip locked abilities (must be unlocked via game completions)
		if UnlocksManager and not UnlocksManager.is_passive_unlocked(ability.id):
			continue

		# Skip melee abilities for ranged characters
		if ability.type == AbilityData.Type.MELEE_ONLY and _manager.is_ranged_character:
			continue

		# Skip ranged abilities for melee characters
		if ability.type == AbilityData.Type.RANGED_ONLY and not _manager.is_ranged_character:
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

func _get_available_upgrade_abilities(from_pool: Array[AbilityData]) -> Array[AbilityData]:
	"""Get only upgrade abilities from the available pool"""
	var upgrades: Array[AbilityData] = []
	for ability in from_pool:
		if ability.is_upgrade:
			upgrades.append(ability)
	return upgrades

func is_ability_stackable(ability: AbilityData) -> bool:
	"""Check if an ability can be acquired multiple times"""
	# Most stat boost abilities can stack
	if ability.type == AbilityData.Type.STAT_BOOST:
		return true

	# Some specific abilities can stack
	match ability.id:
		"split_shot", "laser_drill", "scattergun":
			return true

	return false

func has_ability(id: String) -> bool:
	"""Check if player already has this ability"""
	for ability in _manager.acquired_abilities:
		if ability.id == id:
			return true
	return false

func get_ability_acquisition_count(ability_id: String) -> int:
	"""Count how many times an ability has been acquired"""
	var count = 0
	for ability in _manager.acquired_abilities:
		if ability.id == ability_id:
			count += 1
	return count

func pick_weighted_random(abilities: Array[AbilityData], apply_synergy_boost: bool = false) -> AbilityData:
	"""Pick a random ability weighted by rarity, diversity, and synergies"""
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
	# Check explicit synergy IDs
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

# ============================================
# MIXED POOL SELECTION (Passives + Active Upgrades)
# ============================================

func get_mixed_ability_choices(count: int = 3) -> Array:
	"""
	Returns mixed array of AbilityData (passives) and ActiveAbilityData (upgrades)
	Used for the new tiered ability system
	"""
	var choices: Array = []
	var available_passives = get_available_abilities()
	var available_upgrades = _get_available_active_upgrades()

	# Determine how many upgrades to include
	var upgrade_slots = 0
	if available_upgrades.size() > 0:
		# Roll for each slot to potentially be an upgrade
		for i in range(count):
			if randf() < UPGRADE_BOOST_CHANCE and available_upgrades.size() > upgrade_slots:
				upgrade_slots += 1

	# Fill upgrade slots
	for i in range(upgrade_slots):
		if available_upgrades.size() > 0:
			var upgrade = _pick_weighted_upgrade(available_upgrades)
			if upgrade:
				choices.append(upgrade)
				available_upgrades.erase(upgrade)

	# Fill remaining with passives
	var passive_count = count - choices.size()
	for i in range(passive_count):
		if available_passives.size() > 0:
			var passive = pick_weighted_random(available_passives)
			if passive:
				choices.append(passive)
				available_passives.erase(passive)

	# Shuffle to mix positions
	choices.shuffle()
	return choices

func _get_available_active_upgrades() -> Array:
	"""Get all active ability upgrades available based on acquired abilities"""
	var upgrades: Array = []

	# Check if ActiveAbilityManager exists and has the method
	if not ActiveAbilityManager:
		return upgrades

	# Get upgrades for each acquired active ability
	for ability_id in ActiveAbilityManager.acquired_ability_ids:
		var tree = ActiveAbilityDatabase.get_ability_tree(ability_id) if ActiveAbilityDatabase.has_method("get_ability_tree") else null
		if tree and tree.has_method("get_available_upgrades"):
			upgrades.append_array(tree.get_available_upgrades())

	return upgrades

func _pick_weighted_upgrade(upgrades: Array) -> Variant:
	"""Pick a weighted random upgrade from available upgrades"""
	if upgrades.size() == 0:
		return null

	# For now, just pick random - can add rarity weighting later
	return upgrades[randi() % upgrades.size()]
