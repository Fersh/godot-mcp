extends RefCounted
class_name BranchSelector

## Handles the branching UI flow when player clicks an active ability upgrade.
## Shows available branch options and allows selection or cancellation.

signal branch_selected(branch: ActiveAbilityData)
signal selection_cancelled

# State
var is_active: bool = false
var trigger_ability: ActiveAbilityData = null
var available_branches: Array[ActiveAbilityData] = []
var saved_choices: Array = []

func _init() -> void:
	pass

func start_branch_selection(trigger: ActiveAbilityData, original_choices: Array) -> Array[ActiveAbilityData]:
	"""
	Start branch selection mode.
	Returns the available branch options for the trigger ability.
	"""
	is_active = true
	trigger_ability = trigger
	saved_choices = original_choices.duplicate()

	# Get available upgrades for this ability from the tree
	available_branches = _get_branch_options(trigger)
	return available_branches

func _get_branch_options(ability: ActiveAbilityData) -> Array[ActiveAbilityData]:
	"""Get available branch upgrades for an ability."""
	var branches: Array[ActiveAbilityData] = []

	# Get the base ability ID
	var base_id = ability.base_ability_id if not ability.base_ability_id.is_empty() else ability.id

	# Get the tree for this ability
	var tree = AbilityTreeRegistry.get_tree(base_id)
	if tree == null:
		# Fallback: try to get tree for the trigger ability's prerequisite
		tree = AbilityTreeRegistry.get_tree_for_ability(ability.id)

	if tree:
		branches = tree.get_available_upgrades()

	return branches

func select_branch(branch: ActiveAbilityData) -> void:
	"""Player selected a branch upgrade."""
	is_active = false
	trigger_ability = null
	emit_signal("branch_selected", branch)

func cancel() -> Array:
	"""Cancel branch selection and return to original choices."""
	is_active = false
	trigger_ability = null
	var choices = saved_choices
	saved_choices = []
	emit_signal("selection_cancelled")
	return choices

func get_saved_choices() -> Array:
	"""Get the original choices that were saved when entering branch mode."""
	return saved_choices

func is_selecting() -> bool:
	"""Check if we're in branch selection mode."""
	return is_active
