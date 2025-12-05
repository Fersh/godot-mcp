extends RefCounted
class_name RankTracker

## Tracks ability ranks for both passive and active abilities.
## Passive ranks: 1, 2, 3 based on acquisition count (max 3)
## Active ranks: 1, 2, 3 based on tier (BASE, BRANCH, SIGNATURE)

const MAX_PASSIVE_RANK: int = 3

# Maps ability_id -> rank (1, 2, or 3)
var _passive_ranks: Dictionary = {}
var _active_ranks: Dictionary = {}

# Reference to ability manager for callbacks
var _manager = null

func _init(manager = null) -> void:
	_manager = manager

# ============================================
# PASSIVE ABILITY RANKS
# ============================================

func get_passive_rank(ability_id: String) -> int:
	"""Get current rank of a passive ability (0 if not acquired)."""
	return _passive_ranks.get(ability_id, 0)

func increment_passive_rank(ability_id: String) -> int:
	"""Increment rank when passive is acquired. Returns new rank."""
	var current = get_passive_rank(ability_id)
	var new_rank = mini(current + 1, MAX_PASSIVE_RANK)
	_passive_ranks[ability_id] = new_rank
	return new_rank

func is_passive_at_max_rank(ability_id: String) -> bool:
	"""Check if passive has reached max rank (3)."""
	return get_passive_rank(ability_id) >= MAX_PASSIVE_RANK

func get_next_passive_rank(ability_id: String) -> int:
	"""Get what rank this ability would be if acquired next."""
	return mini(get_passive_rank(ability_id) + 1, MAX_PASSIVE_RANK)

# ============================================
# ACTIVE ABILITY RANKS
# ============================================

func get_active_rank(ability_id: String) -> int:
	"""Get current rank/tier of an active ability (0 if not acquired)."""
	return _active_ranks.get(ability_id, 0)

func set_active_rank(ability_id: String, tier: int) -> void:
	"""Set rank for active ability based on its tier."""
	_active_ranks[ability_id] = tier

func get_active_rank_for_base(base_ability_id: String) -> int:
	"""Get current rank for an ability tree by its base ID."""
	# Check if we have a rank for this base ability or any of its upgrades
	if _active_ranks.has(base_ability_id):
		return _active_ranks[base_ability_id]
	return 0

# ============================================
# GENERIC RANK ACCESS
# ============================================

func get_rank(ability_id: String, is_active: bool = false) -> int:
	"""Get rank for any ability type."""
	if is_active:
		return get_active_rank(ability_id)
	return get_passive_rank(ability_id)

func is_upgrade(ability_id: String, is_active: bool = false) -> bool:
	"""Check if acquiring this ability would be an upgrade (rank > 1)."""
	return get_rank(ability_id, is_active) > 0

# ============================================
# RESET
# ============================================

func reset() -> void:
	"""Reset all rank tracking for new run."""
	_passive_ranks.clear()
	_active_ranks.clear()

# ============================================
# DEBUG / UTILITY
# ============================================

func get_all_passive_ranks() -> Dictionary:
	"""Get all passive ranks (for saving/debugging)."""
	return _passive_ranks.duplicate()

func get_all_active_ranks() -> Dictionary:
	"""Get all active ranks (for saving/debugging)."""
	return _active_ranks.duplicate()

func set_passive_ranks(ranks: Dictionary) -> void:
	"""Restore passive ranks (for loading)."""
	_passive_ranks = ranks.duplicate()

func set_active_ranks(ranks: Dictionary) -> void:
	"""Restore active ranks (for loading)."""
	_active_ranks = ranks.duplicate()
