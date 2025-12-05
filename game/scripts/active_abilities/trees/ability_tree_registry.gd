extends RefCounted
class_name AbilityTreeRegistry

# Central registry for all ability trees
# Loads trees from melee/, ranged/, and global/ subdirectories

# Singleton-like access (but not an autoload - use static methods)
static var _trees: Dictionary = {}  # base_ability_id -> AbilityTreeNode
static var _ability_lookup: Dictionary = {}  # any_ability_id -> base_ability_id
static var _initialized: bool = false

# ============================================
# INITIALIZATION
# ============================================

static func ensure_initialized() -> void:
	if _initialized:
		return
	_register_all_trees()
	_initialized = true

static func _register_all_trees() -> void:
	"""Register all ability trees from the tree definition classes"""
	_trees.clear()
	_ability_lookup.clear()

	# Register melee trees
	_register_tree(CleaveTree.create())
	_register_tree(BashTree.create())
	_register_tree(ChargeTree.create())
	_register_tree(SpinTree.create())  # Now "Whirlwind" tree (base renamed from Spinning Attack)
	_register_tree(SlamTree.create())
	_register_tree(DashTree.create())
	# _register_tree(WhirlwindTree.create())  # Merged into SpinTree (now Whirlwind Tree)
	_register_tree(LeapTree.create())
	_register_tree(ShoutTree.create())
	_register_tree(ThrowTree.create())
	_register_tree(TauntTree.create())
	_register_tree(ExecuteTree.create())
	_register_tree(BlockTree.create())
	_register_tree(ImpaleTree.create())
	_register_tree(UppercutTree.create())
	_register_tree(ComboTree.create())
	_register_tree(RoarTree.create())
	_register_tree(StompTree.create())
	_register_tree(ParryTree.create())
	_register_tree(RampageTree.create())

	# Register ranged trees
	_register_tree(PowerShotTree.create())
	_register_tree(MultiShotTree.create())
	_register_tree(TrapTree.create())
	_register_tree(RainTree.create())
	_register_tree(TurretTree.create())
	_register_tree(VolleyTree.create())
	_register_tree(EvasionTree.create())
	_register_tree(ExplosiveTree.create())
	_register_tree(PoisonTree.create())
	_register_tree(FrostArrowTree.create())
	_register_tree(MarkTree.create())
	_register_tree(SnipeTree.create())
	_register_tree(DecoyTree.create())
	_register_tree(GrappleTree.create())
	_register_tree(BoomerangTree.create())
	_register_tree(SmokeTree.create())
	_register_tree(NetTree.create())
	_register_tree(RicochetTree.create())
	_register_tree(BarrageTree.create())
	_register_tree(QuickdrawTree.create())

	# Register global trees
	# _register_tree(FireballTree.create())  # Commented out - temporarily disabled
	_register_tree(FrostNovaTree.create())
	_register_tree(LightningTree.create())
	_register_tree(HealTree.create())
	_register_tree(TeleportTree.create())
	_register_tree(TimeTree.create())
	_register_tree(SummonTree.create())
	_register_tree(AuraTree.create())
	_register_tree(ShieldTree.create())
	_register_tree(GravityTree.create())
	_register_tree(BombTree.create())
	_register_tree(DrainTree.create())
	_register_tree(CurseTree.create())
	_register_tree(BlinkTree.create())
	_register_tree(ThornsTree.create())

static func _register_tree(tree: AbilityTreeNode) -> void:
	"""Register a tree and build lookup indices"""
	if not tree or not tree.base_ability:
		push_warning("Attempted to register invalid ability tree")
		return

	var base_id = tree.base_ability.id
	_trees[base_id] = tree

	# Build lookup from any ability ID to base ID
	for ability in tree.get_all_abilities():
		_ability_lookup[ability.id] = base_id

# ============================================
# TREE ACCESS
# ============================================

static func get_tree(base_id: String) -> AbilityTreeNode:
	"""Get tree by base ability ID"""
	ensure_initialized()
	return _trees.get(base_id, null)

static func get_tree_for_ability(ability_id: String) -> AbilityTreeNode:
	"""Get tree that contains a specific ability (any tier)"""
	ensure_initialized()
	var base_id = _ability_lookup.get(ability_id, "")
	if base_id.is_empty():
		return null
	return _trees.get(base_id, null)

static func get_base_ability_id(ability_id: String) -> String:
	"""Get base ability ID for any ability in a tree"""
	ensure_initialized()
	return _ability_lookup.get(ability_id, ability_id)

static func has_tree(base_id: String) -> bool:
	"""Check if a tree exists for this base ability"""
	ensure_initialized()
	return _trees.has(base_id)

static func is_ability_in_tree(ability_id: String) -> bool:
	"""Check if an ability is part of any tree"""
	ensure_initialized()
	return _ability_lookup.has(ability_id)

# ============================================
# TREE QUERIES
# ============================================

static func get_all_base_abilities() -> Array[ActiveAbilityData]:
	"""Get all base (Tier 1) abilities from all trees"""
	ensure_initialized()
	var bases: Array[ActiveAbilityData] = []
	for tree in _trees.values():
		if tree.base_ability:
			bases.append(tree.base_ability)
	return bases

static func get_base_abilities_for_class(class_type: ActiveAbilityData.ClassType) -> Array[ActiveAbilityData]:
	"""Get base abilities filtered by class type"""
	ensure_initialized()
	var bases: Array[ActiveAbilityData] = []
	for tree in _trees.values():
		if tree.base_ability and tree.base_ability.class_type == class_type:
			bases.append(tree.base_ability)
	return bases

static func get_melee_base_abilities() -> Array[ActiveAbilityData]:
	"""Get all melee base abilities"""
	return get_base_abilities_for_class(ActiveAbilityData.ClassType.MELEE)

static func get_ranged_base_abilities() -> Array[ActiveAbilityData]:
	"""Get all ranged base abilities"""
	return get_base_abilities_for_class(ActiveAbilityData.ClassType.RANGED)

static func get_global_base_abilities() -> Array[ActiveAbilityData]:
	"""Get all global (class-agnostic) base abilities"""
	return get_base_abilities_for_class(ActiveAbilityData.ClassType.GLOBAL)

static func get_all_trees() -> Array[AbilityTreeNode]:
	"""Get all registered ability trees"""
	ensure_initialized()
	var trees: Array[AbilityTreeNode] = []
	for tree in _trees.values():
		trees.append(tree)
	return trees

# ============================================
# UPGRADE AVAILABILITY
# ============================================

static func get_available_upgrades_for_ability(ability_id: String) -> Array[ActiveAbilityData]:
	"""Get available upgrades for an acquired ability"""
	ensure_initialized()
	var tree = get_tree_for_ability(ability_id)
	if not tree:
		return []

	# Check if this is the current ability in the tree
	var current = tree.get_current_ability()
	if current and current.id == ability_id:
		return tree.get_available_upgrades()

	return []

static func get_all_available_upgrades(acquired_ability_ids: Array) -> Array[ActiveAbilityData]:
	"""Get all available upgrades based on player's acquired abilities"""
	ensure_initialized()
	var upgrades: Array[ActiveAbilityData] = []

	for ability_id in acquired_ability_ids:
		var tree = get_tree_for_ability(ability_id)
		if tree:
			var current = tree.get_current_ability()
			if current and current.id == ability_id:
				upgrades.append_array(tree.get_available_upgrades())

	return upgrades

# ============================================
# ABILITY LOOKUP
# ============================================

static func get_ability(ability_id: String) -> ActiveAbilityData:
	"""Get an ability by ID from any tree"""
	ensure_initialized()
	var tree = get_tree_for_ability(ability_id)
	if tree:
		for ability in tree.get_all_abilities():
			if ability.id == ability_id:
				return ability
	return null

# ============================================
# RESET (for new runs)
# ============================================

static func reset_all_trees() -> void:
	"""Reset progress on all trees for a new run"""
	for tree in _trees.values():
		tree.reset()

# ============================================
# DEBUG
# ============================================

static func get_tree_count() -> int:
	ensure_initialized()
	return _trees.size()

static func print_all_trees() -> void:
	"""Debug: Print all registered trees"""
	ensure_initialized()
	print("=== Ability Tree Registry ===")
	print("Total trees: ", _trees.size())
	for base_id in _trees:
		print(_trees[base_id].to_debug_string())
