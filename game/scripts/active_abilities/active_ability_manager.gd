extends Node

# Singleton for managing active abilities, cooldowns, and execution

signal ability_acquired(slot: int, ability: ActiveAbilityData)
signal ability_used(slot: int, ability: ActiveAbilityData)
signal cooldown_updated(slot: int, remaining: float, total: float)
signal dodge_cooldown_updated(remaining: float, total: float)

# Active ability slots (max 3, plus dodge)
const MAX_ABILITY_SLOTS: int = 3
const DODGE_COOLDOWN: float = 5.0  # Single charge cooldown
const DODGE_COOLDOWN_DOUBLE: float = 10.0  # 10s to recharge both charges
const DODGE_DISTANCE: float = 120.0
const DODGE_DURATION: float = 0.15  # How long the dodge movement takes

# Levels at which player chooses an active ability
const ACTIVE_ABILITY_LEVELS: Array[int] = [1, 5, 10]

# Equipped abilities in slots
var ability_slots: Array[ActiveAbilityData] = []
var cooldown_timers: Array[float] = []  # Time remaining on each slot

# Dodge state
var dodge_cooldown_timer: float = 0.0
var is_dodging: bool = false
var dodge_charges: int = 1  # Default 1 charge, can be 2 with Double Charge
var max_dodge_charges: int = 1

# Keyboard input state (to prevent holding key = spam)
var _dodge_key_held: bool = false
var _ability1_key_held: bool = false
var _ability2_key_held: bool = false
var _ability3_key_held: bool = false

# Reference to player (set by player on ready)
var player: Node2D = null

# Cached abilities the player has already acquired (to prevent duplicates)
var acquired_ability_ids: Array[String] = []

# Tree upgrade tracking - maps base_ability_id -> current_ability_id
var acquired_tree_abilities: Dictionary = {}

# Rank tracking - maps base_ability_id -> current rank/tier (1, 2, or 3)
var ability_ranks: Dictionary = {}

# Skillshot aiming - stores the current aim direction for the executor
var current_aim_direction: Vector2 = Vector2.ZERO
var is_aimed_shot: bool = false

# Chance for upgrades to appear in selection (50%)
const UPGRADE_CHANCE: float = 0.50

func _ready() -> void:
	# Add to group so AbilityManager can find us for cooldown reduction
	add_to_group("active_ability_manager")

	# Initialize slots
	ability_slots.resize(MAX_ABILITY_SLOTS)
	cooldown_timers.resize(MAX_ABILITY_SLOTS)
	for i in MAX_ABILITY_SLOTS:
		ability_slots[i] = null
		cooldown_timers[i] = 0.0

func _process(delta: float) -> void:
	# Update cooldown timers
	for i in MAX_ABILITY_SLOTS:
		if cooldown_timers[i] > 0:
			cooldown_timers[i] = max(0.0, cooldown_timers[i] - delta)
			if ability_slots[i]:
				emit_signal("cooldown_updated", i, cooldown_timers[i], ability_slots[i].cooldown)

	# Update dodge cooldown / charge regeneration
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer = max(0.0, dodge_cooldown_timer - delta)
		var total_cooldown = DODGE_COOLDOWN_DOUBLE if max_dodge_charges > 1 else DODGE_COOLDOWN
		emit_signal("dodge_cooldown_updated", dodge_cooldown_timer, total_cooldown)

		# Handle charge regeneration (Double Charge passive)
		# Both charges recharge together over 10s
		if dodge_cooldown_timer <= 0 and max_dodge_charges > 1 and dodge_charges < max_dodge_charges:
			dodge_charges = max_dodge_charges  # Restore all charges at once

	# Keyboard shortcuts for abilities
	if not get_tree().paused:
		# Dodge: J/1
		if Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_1):
			if not _dodge_key_held:
				_dodge_key_held = true
				perform_dodge()
		else:
			_dodge_key_held = false

		# Ability 1: K/2
		if Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_2):
			if not _ability1_key_held:
				_ability1_key_held = true
				use_ability(0)
		else:
			_ability1_key_held = false

		# Ability 2: L/3
		if Input.is_key_pressed(KEY_L) or Input.is_key_pressed(KEY_3):
			if not _ability2_key_held:
				_ability2_key_held = true
				use_ability(1)
		else:
			_ability2_key_held = false

		# Ability 3: ;/4
		if Input.is_key_pressed(KEY_SEMICOLON) or Input.is_key_pressed(KEY_4):
			if not _ability3_key_held:
				_ability3_key_held = true
				use_ability(2)
		else:
			_ability3_key_held = false

func reset_for_new_run() -> void:
	"""Reset all abilities for a new game run."""
	for i in MAX_ABILITY_SLOTS:
		ability_slots[i] = null
		cooldown_timers[i] = 0.0
	dodge_cooldown_timer = 0.0
	is_dodging = false
	dodge_charges = 1
	max_dodge_charges = 1
	acquired_ability_ids.clear()
	acquired_tree_abilities.clear()
	ability_ranks.clear()

	# Reset all ability trees for new run
	AbilityTreeRegistry.reset_all_trees()

func _mark_all_keys_held() -> void:
	"""Mark all ability keys as held to prevent immediate triggering after UI selection."""
	_dodge_key_held = true
	_ability1_key_held = true
	_ability2_key_held = true
	_ability3_key_held = true

func register_player(p: Node2D) -> void:
	"""Register the player reference for ability execution."""
	player = p

# ============================================
# ABILITY SLOT MANAGEMENT
# ============================================

func get_next_empty_slot() -> int:
	"""Returns the index of the next empty slot, or -1 if all full."""
	for i in MAX_ABILITY_SLOTS:
		if ability_slots[i] == null:
			return i
	return -1

func acquire_ability(ability: ActiveAbilityData) -> bool:
	"""Add an ability to the next available slot, or upgrade an existing slot. Returns true if successful."""

	# Mark all ability keys as "held" to prevent immediate triggering after selection
	# This prevents the key used to select the ability from also triggering it
	_mark_all_keys_held()

	# Check if this is an upgrade to an existing ability
	if ability.tier != ActiveAbilityData.AbilityTier.BASE:
		var upgraded_slot = _try_upgrade_existing_ability(ability)
		if upgraded_slot >= 0:
			return true

	# Otherwise, add to next empty slot (for base abilities)
	var slot = get_next_empty_slot()
	if slot == -1:
		return false

	ability_slots[slot] = ability
	cooldown_timers[slot] = 0.0
	acquired_ability_ids.append(ability.id)

	# Track tree progression and rank
	_track_tree_ability(ability)
	_update_ability_rank(ability)

	emit_signal("ability_acquired", slot, ability)
	return true

func _try_upgrade_existing_ability(upgrade: ActiveAbilityData) -> int:
	"""Try to replace an existing ability with its upgrade. Returns slot index or -1."""
	# Find the slot containing the prerequisite ability
	for i in MAX_ABILITY_SLOTS:
		if ability_slots[i] != null and ability_slots[i].id == upgrade.prerequisite_id:
			# Replace with upgrade
			ability_slots[i] = upgrade
			cooldown_timers[i] = 0.0  # Reset cooldown on upgrade
			acquired_ability_ids.append(upgrade.id)

			# Update tree progression and rank
			_track_tree_ability(upgrade)
			_update_ability_rank(upgrade)

			emit_signal("ability_acquired", i, upgrade)
			return i

	return -1

func _track_tree_ability(ability: ActiveAbilityData) -> void:
	"""Track ability in tree progression system."""
	var base_id = AbilityTreeRegistry.get_base_ability_id(ability.id)
	if base_id.is_empty():
		return

	# Update our tracking
	acquired_tree_abilities[base_id] = ability.id

	# Update the tree's internal state
	var tree = AbilityTreeRegistry.get_tree(base_id)
	if tree:
		tree.upgrade_to(ability)

func get_ability_in_slot(slot: int) -> ActiveAbilityData:
	"""Get the ability in a specific slot."""
	if slot >= 0 and slot < MAX_ABILITY_SLOTS:
		return ability_slots[slot]
	return null

func get_equipped_count() -> int:
	"""Returns how many abilities are currently equipped."""
	var count = 0
	for ability in ability_slots:
		if ability != null:
			count += 1
	return count

func is_level_active_ability_level(level: int) -> bool:
	"""Check if this level grants an active ability choice."""
	return level in ACTIVE_ABILITY_LEVELS

# ============================================
# ABILITY EXECUTION
# ============================================

func can_use_ability(slot: int) -> bool:
	"""Check if an ability slot is ready to use."""
	if slot < 0 or slot >= MAX_ABILITY_SLOTS:
		return false
	if ability_slots[slot] == null:
		return false
	if cooldown_timers[slot] > 0:
		return false
	if is_dodging:
		return false
	# Can't use abilities when dead
	if player and player.is_dead:
		return false
	return true

func use_ability(slot: int) -> bool:
	"""Attempt to use the ability in the given slot. Returns true if successful."""
	if not can_use_ability(slot):
		return false

	var ability = ability_slots[slot]
	if ability == null:
		return false

	# Clear any previous aim direction (auto-targeting)
	is_aimed_shot = false
	current_aim_direction = Vector2.ZERO

	# Start cooldown (apply cooldown reduction from permanent upgrades)
	var cooldown = ability.cooldown * get_cooldown_multiplier()
	cooldown_timers[slot] = cooldown

	# Execute the ability
	_execute_ability(ability)

	# Trigger Combo Master (grants damage buff)
	if AbilityManager:
		AbilityManager.on_active_ability_used()

	# Check for Ability Echo (10% chance to trigger twice)
	if AbilityManager and AbilityManager.should_echo_ability():
		# Execute ability again with slight delay
		get_tree().create_timer(0.1).timeout.connect(func(): _execute_ability(ability))

	# Check for Ability Cascade (chance to reset another ability cooldown)
	if AbilityManager:
		AbilityManager.try_ability_cascade()

	emit_signal("ability_used", slot, ability)
	return true

func use_ability_aimed(slot: int, aim_direction: Vector2) -> bool:
	"""Attempt to use the ability with a specific aim direction (skillshot). Returns true if successful."""
	if not can_use_ability(slot):
		return false

	var ability = ability_slots[slot]
	if ability == null:
		return false

	# Store aim direction for executor
	is_aimed_shot = true
	current_aim_direction = aim_direction.normalized() if aim_direction.length() > 0 else Vector2.ZERO

	# Start cooldown (apply cooldown reduction from permanent upgrades)
	var cooldown = ability.cooldown * get_cooldown_multiplier()
	cooldown_timers[slot] = cooldown

	# Execute the ability
	_execute_ability(ability)

	# Clear aim state after execution
	is_aimed_shot = false
	current_aim_direction = Vector2.ZERO

	# Trigger Combo Master (grants damage buff)
	if AbilityManager:
		AbilityManager.on_active_ability_used()

	# Check for Ability Echo (10% chance to trigger twice)
	if AbilityManager and AbilityManager.should_echo_ability():
		# Execute ability again with slight delay (uses same aim direction)
		var saved_direction = aim_direction
		get_tree().create_timer(0.1).timeout.connect(func():
			is_aimed_shot = true
			current_aim_direction = saved_direction
			_execute_ability(ability)
			is_aimed_shot = false
			current_aim_direction = Vector2.ZERO
		)

	# Check for Ability Cascade (chance to reset another ability cooldown)
	if AbilityManager:
		AbilityManager.try_ability_cascade()

	emit_signal("ability_used", slot, ability)
	return true

func get_current_aim_direction() -> Vector2:
	"""Get the current aim direction for skillshot abilities."""
	return current_aim_direction

func is_using_aimed_shot() -> bool:
	"""Check if the current ability use is an aimed skillshot."""
	return is_aimed_shot

func get_cooldown_multiplier() -> float:
	"""Get the cooldown multiplier from permanent upgrades and abilities."""
	var multiplier = 1.0

	# Apply permanent upgrade cooldown reduction
	if PermanentUpgrades:
		var reduction = PermanentUpgrades.get_all_bonuses().get("cooldown_reduction", 0.0)
		multiplier -= reduction

	# Apply Quick Reflexes passive cooldown reduction
	if AbilityManager:
		multiplier *= AbilityManager.get_active_cooldown_multiplier()

	# Apply All-For-One mythic penalty if active
	if AbilityManager and AbilityManager.has_all_for_one_ability():
		multiplier *= AbilityManager.get_all_for_one_cooldown_multiplier()

	return maxf(multiplier, 0.1)  # Minimum 10% of original cooldown

func reset_random_cooldown() -> void:
	"""Reset a random ability cooldown (used by Ability Cascade)."""
	var on_cooldown_slots: Array[int] = []
	for i in range(MAX_ABILITY_SLOTS):
		if cooldown_timers[i] > 0 and ability_slots[i] != null:
			on_cooldown_slots.append(i)

	if on_cooldown_slots.size() > 0:
		var random_slot = on_cooldown_slots[randi() % on_cooldown_slots.size()]
		cooldown_timers[random_slot] = 0.0
		emit_signal("cooldown_changed", random_slot, 0.0, 0.0)

func _execute_ability(ability: ActiveAbilityData) -> void:
	"""Execute an ability's effect. Delegates to AbilityExecutor."""
	if not player:
		return

	# Get the executor and run the ability
	var executor = _get_ability_executor()
	if executor:
		executor.execute(ability, player)

func _get_ability_executor() -> Node:
	"""Get or create the ability executor node."""
	var executor = get_node_or_null("AbilityExecutor")
	if not executor:
		# Lazy load the executor
		var executor_script = load("res://scripts/active_abilities/ability_executor.gd")
		if executor_script:
			executor = Node.new()
			executor.set_script(executor_script)
			executor.name = "AbilityExecutor"
			add_child(executor)
	return executor

# ============================================
# DODGE ABILITY
# ============================================

func can_dodge() -> bool:
	"""Check if dodge is available."""
	if player and player.is_dead:
		return false
	# With charge system: can dodge if we have charges OR cooldown is ready
	if max_dodge_charges > 1:
		return dodge_charges > 0 and not is_dodging
	return dodge_cooldown_timer <= 0 and not is_dodging

func perform_dodge() -> bool:
	"""Execute the dodge ability. Returns true if successful."""
	if not can_dodge():
		return false

	if not player:
		return false

	# Handle charge-based system (Double Charge)
	if max_dodge_charges > 1:
		dodge_charges -= 1
		# Start recharge timer only when ALL charges are depleted (10s for both)
		if dodge_charges <= 0 and dodge_cooldown_timer <= 0:
			var cooldown_mult = 1.0
			if AbilityManager:
				cooldown_mult = AbilityManager.get_wind_dancer_cooldown_multiplier()
			dodge_cooldown_timer = DODGE_COOLDOWN_DOUBLE * cooldown_mult
	else:
		# Standard single-charge cooldown
		var cooldown_mult = 1.0
		if AbilityManager:
			cooldown_mult = AbilityManager.get_wind_dancer_cooldown_multiplier()
		dodge_cooldown_timer = DODGE_COOLDOWN * cooldown_mult

	is_dodging = true

	# Calculate dodge direction (away from nearest enemy)
	var dodge_direction = _calculate_dodge_direction()

	# Trigger Swift Dodge speed boost
	if AbilityManager:
		AbilityManager.on_dodge_used()

	# Execute the dodge (with Phantom Strike check)
	_execute_dodge(dodge_direction)

	return true

func add_dodge_charge() -> void:
	"""Add an additional dodge charge (Double Charge passive)."""
	max_dodge_charges = 2
	dodge_charges = 2

func _calculate_dodge_direction() -> Vector2:
	"""Calculate the direction to dodge. Prioritizes player input direction, falls back to away from enemies."""
	if not player:
		return Vector2.DOWN

	# First priority: Use player's current movement direction if they're moving
	var input_direction = Vector2.ZERO

	# Check joystick direction
	if "joystick_direction" in player and player.joystick_direction.length() > 0.1:
		input_direction = player.joystick_direction.normalized()

	# Check velocity as fallback (if player is actively moving)
	if input_direction.length() < 0.1 and "velocity" in player and player.velocity.length() > 10:
		input_direction = player.velocity.normalized()

	# If player is actively holding a direction, dodge in that direction
	if input_direction.length() > 0.1:
		return input_direction

	# Fallback: Dodge away from nearest enemy when no input is being held
	var enemies = player.get_tree().get_nodes_in_group("enemies")
	var closest_enemy: Node2D = null
	var closest_dist: float = INF

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = enemy

	if closest_enemy:
		# Dodge away from the closest enemy
		return (player.global_position - closest_enemy.global_position).normalized()
	else:
		# No enemies and no input, dodge backward (opposite of facing direction)
		if player.has_method("get_facing_direction"):
			return -player.get_facing_direction()
		return Vector2.DOWN

func _execute_dodge(direction: Vector2) -> void:
	"""Execute the dodge movement with invulnerability."""
	if not player:
		is_dodging = false
		return

	# Store start position for Phantom Strike
	var start_pos = player.global_position

	# Grant brief invulnerability
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(true)

	# Calculate target position
	var target_pos = player.global_position + direction * DODGE_DISTANCE

	# Clamp to arena bounds (expanded horizontally)
	const ARENA_HEIGHT = 1382
	const MARGIN_Y = 40
	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, MARGIN_Y, ARENA_HEIGHT - MARGIN_Y)

	# Check for Phantom Strike - find enemies in dodge path
	var enemies_in_path: Array = []
	if AbilityManager and AbilityManager.has_phantom_strike:
		enemies_in_path = _get_enemies_in_dodge_path(start_pos, target_pos)

	# Create tween for smooth dodge movement
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, DODGE_DURATION)
	tween.tween_callback(func(): _on_dodge_complete_with_phantom_strike(enemies_in_path))

	# Play dodge sound
	if SoundManager:
		SoundManager.play_dodge() if SoundManager.has_method("play_dodge") else null

	# Visual effect
	if player.has_method("spawn_dodge_effect"):
		player.spawn_dodge_effect()

func _get_enemies_in_dodge_path(start: Vector2, end: Vector2) -> Array:
	"""Find all enemies along the dodge path for Phantom Strike."""
	var enemies_hit: Array = []
	var enemies = player.get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		# Check if enemy is within the dodge path (using line segment distance)
		var enemy_pos = enemy.global_position
		var distance_to_line = _point_to_line_distance(enemy_pos, start, end)

		# If enemy is close enough to the line (within ~60 pixels)
		if distance_to_line < 60.0:
			# Also check if enemy is between start and end
			var to_enemy = enemy_pos - start
			var to_end = end - start
			var dot = to_enemy.dot(to_end.normalized())
			if dot > 0 and dot < to_end.length():
				enemies_hit.append(enemy)

	return enemies_hit

func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	"""Calculate perpendicular distance from a point to a line segment."""
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_length = line_vec.length()

	if line_length < 0.001:
		return point_vec.length()

	var line_unit = line_vec / line_length
	var proj_length = point_vec.dot(line_unit)
	proj_length = clamp(proj_length, 0, line_length)
	var closest_point = line_start + line_unit * proj_length
	return (point - closest_point).length()

func _on_dodge_complete_with_phantom_strike(enemies_hit: Array) -> void:
	"""Called when dodge movement finishes, applies Phantom Strike if applicable."""
	is_dodging = false
	if player and player.has_method("set_invulnerable"):
		player.set_invulnerable(false)

	# Apply Phantom Strike damage to enemies we passed through
	if not enemies_hit.is_empty() and AbilityManager:
		AbilityManager.on_dodge_through_enemy(player, enemies_hit)

func _on_dodge_complete() -> void:
	"""Called when dodge movement finishes."""
	is_dodging = false
	if player and player.has_method("set_invulnerable"):
		player.set_invulnerable(false)

# ============================================
# ABILITY SELECTION FOR LEVEL UP
# ============================================

func get_random_abilities_for_level(level: int, is_melee: bool, count: int = 3) -> Array[ActiveAbilityData]:
	## Get random BASE active abilities for the level-up selection screen.
	## Only returns new base abilities - upgrades are mixed into passive selection instead.
	var available = _get_available_abilities(is_melee)

	if available.is_empty():
		return []

	# Get rarity weights for this level
	var weights = ActiveAbilityData.get_rarity_weights_for_level(level)

	# Select abilities with weighted randomness
	var selected: Array[ActiveAbilityData] = []
	var attempts = 0
	var max_attempts = 100

	while selected.size() < count and attempts < max_attempts:
		attempts += 1

		# Roll for rarity and pick from available base abilities
		var rarity = _roll_rarity(weights)
		var rarity_abilities = available.filter(func(a): return a.rarity == rarity)
		if rarity_abilities.is_empty():
			continue
		var ability = rarity_abilities[randi() % rarity_abilities.size()]

		if ability == null:
			continue

		# Check not already selected
		var already_selected = false
		for sel in selected:
			if sel.id == ability.id:
				already_selected = true
				break

		if not already_selected:
			selected.append(ability)
			available = available.filter(func(a): return a.id != ability.id)

	return selected

func get_available_upgrades() -> Array[ActiveAbilityData]:
	## Public: Get all available upgrades for currently equipped abilities.
	## Called by AbilityManager to mix into passive selection.
	return _get_available_upgrades()

func _get_available_upgrades() -> Array[ActiveAbilityData]:
	"""Get all available upgrades for currently equipped abilities."""
	var upgrades: Array[ActiveAbilityData] = []

	for i in MAX_ABILITY_SLOTS:
		var current = ability_slots[i]
		if current == null:
			continue

		# Get upgrades for this ability from the tree registry
		var ability_upgrades = AbilityTreeRegistry.get_available_upgrades_for_ability(current.id)
		for upgrade in ability_upgrades:
			# Don't include already acquired abilities
			if upgrade.id not in acquired_ability_ids:
				upgrades.append(upgrade)

	return upgrades

func _get_available_abilities(is_melee: bool) -> Array[ActiveAbilityData]:
	## Get BASE abilities available for selection (not yet acquired).
	## Only returns Tier 1 (base) abilities - upgrades come from _get_available_upgrades().
	var all_abilities = ActiveAbilityDatabase.get_abilities_for_class(is_melee)
	var available: Array[ActiveAbilityData] = []

	for ability in all_abilities:
		# Only include BASE tier abilities - upgrades are handled separately
		if ability.is_base() and ability.id not in acquired_ability_ids:
			available.append(ability)

	return available

func _roll_rarity(weights: Dictionary) -> ActiveAbilityData.Rarity:
	"""Roll for a rarity based on weights."""
	var total = 0
	for weight in weights.values():
		total += weight

	var roll = randi() % total
	var cumulative = 0

	for rarity in weights.keys():
		cumulative += weights[rarity]
		if roll < cumulative:
			return rarity

	return ActiveAbilityData.Rarity.COMMON

# ============================================
# DAMAGE CALCULATION
# ============================================

func calculate_ability_damage(ability: ActiveAbilityData) -> float:
	"""Calculate the final damage for an ability based on player stats."""
	var base = ability.base_damage

	# Get player's damage multiplier (from gear, passives, upgrades)
	var damage_mult = 1.0
	if AbilityManager:
		damage_mult = AbilityManager.get_damage_multiplier()
		# Apply Empowered Abilities bonus (active abilities deal extra damage)
		damage_mult *= AbilityManager.get_active_ability_damage_multiplier()

	# Apply ability's own damage multiplier
	return base * ability.damage_multiplier * damage_mult

func get_cooldown_remaining(slot: int) -> float:
	"""Get remaining cooldown for a slot."""
	if slot >= 0 and slot < MAX_ABILITY_SLOTS:
		return cooldown_timers[slot]
	return 0.0

func get_cooldown_percent(slot: int) -> float:
	"""Get cooldown progress (0 = ready, 1 = just used)."""
	if slot < 0 or slot >= MAX_ABILITY_SLOTS:
		return 0.0
	var ability = ability_slots[slot]
	if ability == null or ability.cooldown <= 0:
		return 0.0
	# Use the modified cooldown for percentage calculation
	var modified_cooldown = ability.cooldown * get_cooldown_multiplier()
	return cooldown_timers[slot] / modified_cooldown

func get_dodge_cooldown_percent() -> float:
	"""Get dodge cooldown progress (0 = ready, 1 = just used)."""
	var total_cooldown = DODGE_COOLDOWN_DOUBLE if max_dodge_charges > 1 else DODGE_COOLDOWN
	return dodge_cooldown_timer / total_cooldown

func get_dodge_charges() -> int:
	"""Get current dodge charges available."""
	return dodge_charges

func get_max_dodge_charges() -> int:
	"""Get max dodge charges."""
	return max_dodge_charges

func reduce_all_cooldowns(amount: float) -> void:
	"""Reduce all active ability cooldowns by a flat amount (used by Arcane Absorption)."""
	for i in MAX_ABILITY_SLOTS:
		if cooldown_timers[i] > 0:
			cooldown_timers[i] = maxf(0.0, cooldown_timers[i] - amount)
	# Also reduce dodge cooldown
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer = maxf(0.0, dodge_cooldown_timer - amount)

# ============================================
# RANK TRACKING (for UI display)
# ============================================

func get_ability_rank(base_ability_id: String) -> int:
	"""Get current rank/tier of an active ability by its base ID (1, 2, or 3)."""
	return ability_ranks.get(base_ability_id, 0)

func _update_ability_rank(ability: ActiveAbilityData) -> void:
	"""Update rank tracking when ability is acquired or upgraded."""
	var base_id = ability.base_ability_id if not ability.base_ability_id.is_empty() else ability.id
	var rank = 1
	match ability.tier:
		ActiveAbilityData.AbilityTier.BASE:
			rank = 1
		ActiveAbilityData.AbilityTier.BRANCH:
			rank = 2
		ActiveAbilityData.AbilityTier.SIGNATURE:
			rank = 3
	ability_ranks[base_id] = rank

func is_ability_upgrade(base_ability_id: String) -> bool:
	"""Check if this ability has been upgraded from base (rank > 1)."""
	return get_ability_rank(base_ability_id) > 1
