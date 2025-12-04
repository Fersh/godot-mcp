extends RefCounted
class_name AbilityTreeNode

# Represents a single ability's upgrade tree
# Contains base ability and all possible branch upgrades

# The base (Tier 1) ability
var base_ability: ActiveAbilityData

# Branch paths: Array of branch paths, each path is an array of tier upgrades
# Structure: [[tier2_branch_a, tier3_branch_a], [tier2_branch_b, tier3_branch_b], ...]
var branches: Array = []

# Player progress tracking
var acquired_branch: int = -1    # Which branch player chose (-1 = none, base only)
var current_tier: int = 0        # 0 = base only, 1 = tier 2, 2 = tier 3

# ============================================
# INITIALIZATION
# ============================================

func _init(p_base: ActiveAbilityData = null) -> void:
	if p_base:
		base_ability = p_base

func add_branch(tier2: ActiveAbilityData, tier3: ActiveAbilityData = null) -> AbilityTreeNode:
	"""Add a branch path with tier 2 and optional tier 3 abilities"""
	var branch_path: Array = [tier2]
	if tier3:
		branch_path.append(tier3)
	branches.append(branch_path)
	return self

# ============================================
# AVAILABILITY CHECKS
# ============================================

func get_available_upgrades() -> Array[ActiveAbilityData]:
	"""Get all upgrade options available to the player right now"""
	var upgrades: Array[ActiveAbilityData] = []

	# If player hasn't chosen a branch yet (has base only)
	if acquired_branch == -1:
		# Offer all tier 2 options
		for branch in branches:
			if branch.size() > 0 and branch[0] != null:
				upgrades.append(branch[0])

	# If player has tier 2, offer tier 3 of same branch
	elif current_tier == 1 and acquired_branch >= 0 and acquired_branch < branches.size():
		var branch = branches[acquired_branch]
		if branch.size() > 1 and branch[1] != null:
			upgrades.append(branch[1])

	return upgrades

func can_upgrade() -> bool:
	"""Check if any upgrades are available"""
	return get_available_upgrades().size() > 0

func can_upgrade_to(ability_id: String) -> bool:
	"""Check if a specific ability is available as an upgrade"""
	for upgrade in get_available_upgrades():
		if upgrade.id == ability_id:
			return true
	return false

# ============================================
# UPGRADE APPLICATION
# ============================================

func apply_upgrade(ability: ActiveAbilityData) -> bool:
	"""Apply an upgrade and update tracking. Returns true if successful."""
	# Find which branch this ability belongs to
	for i in branches.size():
		var branch = branches[i]
		for j in branch.size():
			if branch[j] != null and branch[j].id == ability.id:
				# Found the ability
				if j == 0:  # Tier 2
					if acquired_branch == -1:  # Must not have chosen branch yet
						acquired_branch = i
						current_tier = 1
						return true
				elif j == 1:  # Tier 3
					if acquired_branch == i and current_tier == 1:  # Must be on this branch at tier 2
						current_tier = 2
						return true
	return false

func get_current_ability() -> ActiveAbilityData:
	"""Get the current highest-tier ability the player has in this tree"""
	if current_tier == 0:
		return base_ability
	elif current_tier == 1 and acquired_branch >= 0:
		return branches[acquired_branch][0]
	elif current_tier == 2 and acquired_branch >= 0:
		return branches[acquired_branch][1]
	return base_ability

# ============================================
# TREE INFO
# ============================================

func get_base_id() -> String:
	"""Get the base ability ID"""
	return base_ability.id if base_ability else ""

func get_branch_count() -> int:
	"""Get number of branch paths"""
	return branches.size()

func get_max_tier() -> int:
	"""Get the maximum tier available in any branch"""
	var max_tier = 1  # Base is tier 1
	for branch in branches:
		max_tier = maxi(max_tier, branch.size() + 1)
	return max_tier

func get_all_abilities() -> Array[ActiveAbilityData]:
	"""Get all abilities in this tree (base + all branches)"""
	var all: Array[ActiveAbilityData] = []
	if base_ability:
		all.append(base_ability)
	for branch in branches:
		for ability in branch:
			if ability != null:
				all.append(ability)
	return all

func get_tier_abilities(p_tier: int) -> Array[ActiveAbilityData]:
	"""Get all abilities at a specific tier (1 = base, 2 = branches, 3 = signatures)"""
	var abilities: Array[ActiveAbilityData] = []
	if p_tier == 1 and base_ability:
		abilities.append(base_ability)
	elif p_tier >= 2:
		var branch_tier_index = p_tier - 2  # 0 for tier 2, 1 for tier 3
		for branch in branches:
			if branch.size() > branch_tier_index and branch[branch_tier_index] != null:
				abilities.append(branch[branch_tier_index])
	return abilities

# ============================================
# RESET
# ============================================

func reset() -> void:
	"""Reset player progress (for new run)"""
	acquired_branch = -1
	current_tier = 0

# ============================================
# DEBUG
# ============================================

func to_string() -> String:
	var s = "AbilityTree: " + get_base_id() + "\n"
	s += "  Current: Tier " + str(current_tier + 1)
	if acquired_branch >= 0:
		s += " (Branch " + str(acquired_branch) + ")"
	s += "\n  Branches:\n"
	for i in branches.size():
		var branch = branches[i]
		s += "    [" + str(i) + "] "
		for j in branch.size():
			if branch[j]:
				s += branch[j].name
				if j < branch.size() - 1:
					s += " -> "
		s += "\n"
	return s
