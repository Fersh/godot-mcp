extends Node2D

# Enemy scenes - loaded dynamically
@export var enemy_scene: PackedScene  # Orc (legacy, kept for compatibility)
@export var ratfolk_scene: PackedScene
@export var imp_scene: PackedScene
@export var slime_scene: PackedScene
@export var skeleton_scene: PackedScene
@export var kobold_priest_scene: PackedScene

# New enemy types
@export var ratfolk_mage_scene: PackedScene
@export var bat_scene: PackedScene
@export var akaname_scene: PackedScene
@export var ghoul_scene: PackedScene
@export var eye_monster_scene: PackedScene
@export var intellect_devourer_scene: PackedScene
@export var bandit_necromancer_scene: PackedScene
@export var golem_scene: PackedScene
@export var shardsoul_slayer_scene: PackedScene

@export var initial_spawn_interval: float = 1.5  # Faster early game spawns
@export var final_spawn_interval: float = 0.69  # 30% fewer mobs (was 0.5)
@export var ramp_up_time: float = 90.0  # Ramp up time
@export var min_spawn_distance: float = 200.0

# Dynamic arena bounds (set by procedural map generator)
var arena_bounds: Rect2 = Rect2(0, 0, 2500, 2500)

# Legacy constants for backwards compatibility
var ARENA_WIDTH: float = 2500
var ARENA_HEIGHT: float = 2500
var ARENA_LEFT: float = 0
var ARENA_RIGHT: float = 2500
var ARENA_TOP: float = 0
var ARENA_BOTTOM: float = 2500

# Spawn scaling - increases enemy count over time
const SCALING_START_TIME: float = 150.0  # 2.5 minutes
const SCALING_INTERVAL: float = 150.0    # Every 2.5 minutes after that
const SCALING_BONUS: float = 0.10        # 10% more spawns per interval

var spawn_timer: float = 0.0
var game_time: float = 0.0

# Spawning control (for challenge mode)
var is_spawning_enabled: bool = true

# Early game boost - spawn extra mobs in first 15 seconds
const EARLY_BOOST_DURATION: float = 15.0
const EARLY_BOOST_EXTRA_MOBS: int = 10
var early_boost_spawned: int = 0
var early_boost_timer: float = 0.0

# Level 0 initial spawn - spawn at screen edge so player has immediate action
var initial_spawn_done: bool = false
const INITIAL_SPAWN_COUNT: int = 4  # Number of mobs to spawn at screen edge

# =============================================================================
# ENDLESS MODE - 20 minute progression (enemies ordered weakest to strongest)
# =============================================================================
# 1. Ratfolk      2. Orc           3. Ratfolk Mage   4. Bat
# 5. Imp          6. Akaname       7. Ghoul          8. Slime
# 9. Skeleton    10. Eye Monster  11. Golem         12. Intellect Devourer
# 13. Necromancer 14. Kobold Priest 15. Shardsoul Slayer

const ENDLESS_RATFOLK_START: float = 0.0
const ENDLESS_ORC_START: float = 60.0             # 1:00
const ENDLESS_RATFOLK_MAGE_START: float = 150.0   # 2:30
const ENDLESS_BAT_START: float = 210.0            # 3:30
const ENDLESS_IMP_START: float = 300.0            # 5:00
const ENDLESS_AKANAME_START: float = 360.0        # 6:00
const ENDLESS_GHOUL_START: float = 420.0          # 7:00
const ENDLESS_SLIME_START: float = 480.0          # 8:00
const ENDLESS_SKELETON_START: float = 600.0       # 10:00
const ENDLESS_EYE_MONSTER_START: float = 660.0    # 11:00
const ENDLESS_GOLEM_START: float = 720.0          # 12:00 (moved up)
const ENDLESS_INTELLECT_START: float = 840.0      # 14:00
const ENDLESS_NECROMANCER_START: float = 900.0    # 15:00
const ENDLESS_KOBOLD_START: float = 1020.0        # 17:00
const ENDLESS_SHARDSOUL_START: float = 1200.0     # 20:00

# =============================================================================
# CHALLENGE MODE - 10 minute compressed progression
# =============================================================================
const CHALLENGE_RATFOLK_START: float = 0.0
const CHALLENGE_ORC_START: float = 30.0           # 0:30
const CHALLENGE_RATFOLK_MAGE_START: float = 75.0  # 1:15
const CHALLENGE_BAT_START: float = 105.0          # 1:45
const CHALLENGE_IMP_START: float = 150.0          # 2:30
const CHALLENGE_AKANAME_START: float = 180.0      # 3:00
const CHALLENGE_GHOUL_START: float = 210.0        # 3:30
const CHALLENGE_SLIME_START: float = 240.0        # 4:00
const CHALLENGE_SKELETON_START: float = 300.0     # 5:00
const CHALLENGE_EYE_MONSTER_START: float = 330.0  # 5:30
const CHALLENGE_GOLEM_START: float = 360.0        # 6:00
const CHALLENGE_INTELLECT_START: float = 420.0    # 7:00
const CHALLENGE_NECROMANCER_START: float = 450.0  # 7:30
const CHALLENGE_KOBOLD_START: float = 510.0       # 8:30
const CHALLENGE_SHARDSOUL_START: float = 600.0    # 10:00

# Active phase constants (set based on mode)
var PHASE_RATFOLK_START: float = 0.0
var PHASE_ORC_START: float = 60.0
var PHASE_RATFOLK_MAGE_START: float = 150.0
var PHASE_BAT_START: float = 210.0
var PHASE_IMP_START: float = 300.0
var PHASE_AKANAME_START: float = 360.0
var PHASE_GHOUL_START: float = 420.0
var PHASE_SLIME_START: float = 480.0
var PHASE_SKELETON_START: float = 600.0
var PHASE_EYE_MONSTER_START: float = 660.0
var PHASE_GOLEM_START: float = 720.0
var PHASE_INTELLECT_START: float = 840.0
var PHASE_NECROMANCER_START: float = 900.0
var PHASE_KOBOLD_START: float = 1020.0
var PHASE_SHARDSOUL_START: float = 1200.0

# Transition durations
const ENDLESS_TRANSITION: float = 90.0   # 1.5 minutes for endless
const CHALLENGE_TRANSITION: float = 45.0  # 45 seconds for challenge
var TRANSITION_DURATION: float = 90.0

# =============================================================================
# DIFFICULTY-BASED ENEMY POOLS
# =============================================================================
# Each difficulty removes the weakest enemy and makes hardest enemies more common
# Juvenile: All enemies, hardest very rare
# Very Easy: No Ratfolk
# Easy: No Ratfolk, Orc
# Normal: No Ratfolk, Orc, Ratfolk Mage
# Nightmare: No Ratfolk, Orc, Ratfolk Mage, Bat - hardest enemies very common

# Enemy tiers (0=weakest, 14=strongest)
const ENEMY_TIERS = {
	"ratfolk": 0,
	"orc": 1,
	"ratfolk_mage": 2,
	"bat": 3,
	"imp": 4,
	"akaname": 5,
	"ghoul": 6,
	"slime": 7,
	"skeleton": 8,
	"eye_monster": 9,
	"golem": 10,
	"intellect_devourer": 11,
	"bandit_necromancer": 12,
	"kobold_priest": 13,
	"shardsoul_slayer": 14,
}

# Minimum enemy tier per difficulty (enemies below this tier are removed)
const DIFFICULTY_MIN_TIER = {
	0: 0,  # Juvenile: all enemies
	1: 1,  # Very Easy: no ratfolk
	2: 2,  # Easy: no ratfolk, orc
	3: 3,  # Normal: no ratfolk, orc, ratfolk_mage
	4: 4,  # Nightmare: no ratfolk, orc, ratfolk_mage, bat
}

# Hardest enemy availability multiplier per difficulty (higher = more common)
const DIFFICULTY_HARD_ENEMY_MULT = {
	0: 0.3,  # Juvenile: hardest enemies very rare
	1: 0.5,  # Very Easy: hardest enemies rare
	2: 0.7,  # Easy: hardest enemies uncommon
	3: 1.0,  # Normal: hardest enemies normal
	4: 1.5,  # Nightmare: hardest enemies very common
}

func _ready() -> void:
	_setup_phase_timings()

func _setup_phase_timings() -> void:
	"""Set phase timings based on game mode."""
	var is_challenge = DifficultyManager and DifficultyManager.is_challenge_mode()

	if is_challenge:
		PHASE_RATFOLK_START = CHALLENGE_RATFOLK_START
		PHASE_ORC_START = CHALLENGE_ORC_START
		PHASE_RATFOLK_MAGE_START = CHALLENGE_RATFOLK_MAGE_START
		PHASE_BAT_START = CHALLENGE_BAT_START
		PHASE_IMP_START = CHALLENGE_IMP_START
		PHASE_AKANAME_START = CHALLENGE_AKANAME_START
		PHASE_GHOUL_START = CHALLENGE_GHOUL_START
		PHASE_SLIME_START = CHALLENGE_SLIME_START
		PHASE_SKELETON_START = CHALLENGE_SKELETON_START
		PHASE_EYE_MONSTER_START = CHALLENGE_EYE_MONSTER_START
		PHASE_GOLEM_START = CHALLENGE_GOLEM_START
		PHASE_INTELLECT_START = CHALLENGE_INTELLECT_START
		PHASE_NECROMANCER_START = CHALLENGE_NECROMANCER_START
		PHASE_KOBOLD_START = CHALLENGE_KOBOLD_START
		PHASE_SHARDSOUL_START = CHALLENGE_SHARDSOUL_START
		TRANSITION_DURATION = CHALLENGE_TRANSITION
	else:
		PHASE_RATFOLK_START = ENDLESS_RATFOLK_START
		PHASE_ORC_START = ENDLESS_ORC_START
		PHASE_RATFOLK_MAGE_START = ENDLESS_RATFOLK_MAGE_START
		PHASE_BAT_START = ENDLESS_BAT_START
		PHASE_IMP_START = ENDLESS_IMP_START
		PHASE_AKANAME_START = ENDLESS_AKANAME_START
		PHASE_GHOUL_START = ENDLESS_GHOUL_START
		PHASE_SLIME_START = ENDLESS_SLIME_START
		PHASE_SKELETON_START = ENDLESS_SKELETON_START
		PHASE_EYE_MONSTER_START = ENDLESS_EYE_MONSTER_START
		PHASE_GOLEM_START = ENDLESS_GOLEM_START
		PHASE_INTELLECT_START = ENDLESS_INTELLECT_START
		PHASE_NECROMANCER_START = ENDLESS_NECROMANCER_START
		PHASE_KOBOLD_START = ENDLESS_KOBOLD_START
		PHASE_SHARDSOUL_START = ENDLESS_SHARDSOUL_START
		TRANSITION_DURATION = ENDLESS_TRANSITION

func _process(delta: float) -> void:
	game_time += delta

	# Don't spawn if disabled (challenge mode after boss killed)
	if not is_spawning_enabled:
		return

	# Initial spawn at screen edge for immediate action at level 0
	if not initial_spawn_done:
		_do_initial_spawn()
		initial_spawn_done = true

	spawn_timer += delta

	var ramp_progress = clamp(game_time / ramp_up_time, 0.0, 1.0)
	var current_interval = lerp(initial_spawn_interval, final_spawn_interval, ramp_progress)

	# Apply difficulty spawn rate multiplier (lower interval = faster spawns)
	if DifficultyManager:
		current_interval /= DifficultyManager.get_spawn_rate_multiplier()

	# Apply Horde Mode curse (even faster spawns)
	if CurseEffects:
		current_interval /= CurseEffects.get_spawn_rate_multiplier()

	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		spawn_enemy()

	# Early game boost - spawn extra mobs in first 15 seconds
	if game_time <= EARLY_BOOST_DURATION and early_boost_spawned < EARLY_BOOST_EXTRA_MOBS:
		early_boost_timer += delta
		var boost_interval = EARLY_BOOST_DURATION / EARLY_BOOST_EXTRA_MOBS  # ~1.5 seconds per extra mob
		if early_boost_timer >= boost_interval:
			early_boost_timer = 0.0
			early_boost_spawned += 1
			spawn_enemy()

func spawn_enemy() -> void:
	var enemy_type = select_enemy_type()
	var scene = get_scene_for_type(enemy_type)

	if scene == null:
		return

	# Calculate how many enemies to spawn based on time scaling
	var spawn_count = get_spawn_count()

	for i in range(spawn_count):
		var enemy = scene.instantiate()
		enemy.global_position = get_spawn_position()

		# Check for champion spawn (Nightmare+ difficulty or curse)
		if _should_spawn_champion():
			_make_champion(enemy)

		# Apply Berserk Enemies curse (faster enemy movement)
		if CurseEffects:
			CurseEffects.modify_enemy_stats(enemy)

		get_parent().add_child(enemy)

		# Vary enemy type for additional spawns
		if i > 0:
			enemy_type = select_enemy_type()
			scene = get_scene_for_type(enemy_type)
			if scene == null:
				continue

func get_spawn_count() -> int:
	"""Calculate how many enemies to spawn based on time scaling."""
	if game_time < SCALING_START_TIME:
		return 1

	# Calculate scaling tiers (every 2.5 mins after the first 2.5 mins)
	var scaling_tiers = int((game_time - SCALING_START_TIME) / SCALING_INTERVAL) + 1
	var total_bonus = scaling_tiers * SCALING_BONUS

	# Continuous scaling - can spawn up to 3 enemies in very late game
	# But keep it reasonable (not crazy)
	var spawn_count = 1

	# First extra enemy chance
	if randf() < total_bonus:
		spawn_count = 2
		# Second extra enemy chance (only after 10 minutes, requires 80%+ bonus)
		if game_time > 600.0 and total_bonus > 0.8 and randf() < (total_bonus - 0.8):
			spawn_count = 3

	return spawn_count

func select_enemy_type() -> String:
	# Calculate spawn weights for each enemy type based on game time
	var weights = calculate_spawn_weights()

	# Weighted random selection
	var total_weight = 0.0
	for w in weights.values():
		total_weight += w

	if total_weight <= 0:
		return "orc"  # Fallback

	var roll = randf() * total_weight
	var cumulative = 0.0

	for enemy_type in weights:
		cumulative += weights[enemy_type]
		if roll <= cumulative:
			return enemy_type

	return "orc"  # Fallback

func calculate_spawn_weights() -> Dictionary:
	var weights = _calculate_base_weights()

	# Apply difficulty-based filtering
	weights = _apply_difficulty_filter(weights)

	return weights

func _calculate_base_weights() -> Dictionary:
	"""Calculate base spawn weights based on game time."""
	var weights = {
		"ratfolk": 0.0,
		"orc": 0.0,
		"ratfolk_mage": 0.0,
		"bat": 0.0,
		"imp": 0.0,
		"akaname": 0.0,
		"ghoul": 0.0,
		"slime": 0.0,
		"skeleton": 0.0,
		"eye_monster": 0.0,
		"golem": 0.0,
		"intellect_devourer": 0.0,
		"bandit_necromancer": 0.0,
		"kobold_priest": 0.0,
		"shardsoul_slayer": 0.0,
	}

	# ===================
	# EARLY GAME
	# ===================

	# Ratfolk: Starts at 100%, tapers off
	if game_time < PHASE_ORC_START:
		weights["ratfolk"] = 1.0
	elif game_time < PHASE_IMP_START:
		var progress = (game_time - PHASE_ORC_START) / TRANSITION_DURATION
		weights["ratfolk"] = lerp(0.7, 0.15, clamp(progress, 0.0, 1.0))
	else:
		weights["ratfolk"] = lerp(0.15, 0.03, clamp((game_time - PHASE_IMP_START) / 300.0, 0.0, 1.0))

	# Orc: Core enemy
	if game_time >= PHASE_ORC_START:
		if game_time < PHASE_IMP_START:
			var progress = (game_time - PHASE_ORC_START) / TRANSITION_DURATION
			weights["orc"] = lerp(0.2, 0.6, clamp(progress, 0.0, 1.0))
		elif game_time < PHASE_GOLEM_START:
			weights["orc"] = lerp(0.5, 0.15, clamp((game_time - PHASE_IMP_START) / 300.0, 0.0, 1.0))
		else:
			weights["orc"] = 0.08

	# Ratfolk Mage: Early caster
	if game_time >= PHASE_RATFOLK_MAGE_START:
		if game_time < PHASE_NECROMANCER_START:
			var progress = (game_time - PHASE_RATFOLK_MAGE_START) / TRANSITION_DURATION
			weights["ratfolk_mage"] = lerp(0.08, 0.18, clamp(progress, 0.0, 1.0))
		else:
			weights["ratfolk_mage"] = lerp(0.15, 0.06, clamp((game_time - PHASE_NECROMANCER_START) / 180.0, 0.0, 1.0))

	# Bat: Fast glass cannon
	if game_time >= PHASE_BAT_START:
		if game_time < PHASE_SKELETON_START:
			var progress = (game_time - PHASE_BAT_START) / TRANSITION_DURATION
			weights["bat"] = lerp(0.1, 0.2, clamp(progress, 0.0, 1.0))
		else:
			weights["bat"] = lerp(0.18, 0.08, clamp((game_time - PHASE_SKELETON_START) / 180.0, 0.0, 1.0))

	# ===================
	# MID GAME
	# ===================

	# Imp: Ranged
	if game_time >= PHASE_IMP_START:
		if game_time < PHASE_EYE_MONSTER_START:
			var progress = (game_time - PHASE_IMP_START) / TRANSITION_DURATION
			weights["imp"] = lerp(0.1, 0.22, clamp(progress, 0.0, 1.0))
		else:
			weights["imp"] = lerp(0.2, 0.1, clamp((game_time - PHASE_EYE_MONSTER_START) / 180.0, 0.0, 1.0))

	# Akaname: Poison
	if game_time >= PHASE_AKANAME_START:
		if game_time < PHASE_INTELLECT_START:
			var progress = (game_time - PHASE_AKANAME_START) / TRANSITION_DURATION
			weights["akaname"] = lerp(0.08, 0.16, clamp(progress, 0.0, 1.0))
		else:
			weights["akaname"] = 0.1

	# Ghoul: Tanky melee
	if game_time >= PHASE_GHOUL_START:
		if game_time < PHASE_GOLEM_START:
			var progress = (game_time - PHASE_GHOUL_START) / TRANSITION_DURATION
			weights["ghoul"] = lerp(0.1, 0.2, clamp(progress, 0.0, 1.0))
		else:
			weights["ghoul"] = lerp(0.18, 0.1, clamp((game_time - PHASE_GOLEM_START) / 120.0, 0.0, 1.0))

	# Slime: Tank
	if game_time >= PHASE_SLIME_START:
		if game_time < PHASE_GOLEM_START:
			var progress = (game_time - PHASE_SLIME_START) / TRANSITION_DURATION
			weights["slime"] = lerp(0.08, 0.15, clamp(progress, 0.0, 1.0))
		else:
			weights["slime"] = 0.08

	# Skeleton: Hard-hitter
	if game_time >= PHASE_SKELETON_START:
		if game_time < PHASE_SHARDSOUL_START:
			var progress = (game_time - PHASE_SKELETON_START) / TRANSITION_DURATION
			weights["skeleton"] = lerp(0.1, 0.2, clamp(progress, 0.0, 1.0))
		else:
			weights["skeleton"] = lerp(0.18, 0.1, clamp((game_time - PHASE_SHARDSOUL_START) / 120.0, 0.0, 1.0))

	# ===================
	# LATE GAME
	# ===================

	# Eye Monster: Acid ranged
	if game_time >= PHASE_EYE_MONSTER_START:
		var progress = (game_time - PHASE_EYE_MONSTER_START) / TRANSITION_DURATION
		weights["eye_monster"] = lerp(0.06, 0.14, clamp(progress, 0.0, 1.0))

	# Golem: Massive tank (moved up after eye monster)
	if game_time >= PHASE_GOLEM_START:
		var progress = (game_time - PHASE_GOLEM_START) / TRANSITION_DURATION
		weights["golem"] = lerp(0.03, 0.08, clamp(progress, 0.0, 1.0))

	# Intellect Devourer: Ability drain
	if game_time >= PHASE_INTELLECT_START:
		var progress = (game_time - PHASE_INTELLECT_START) / TRANSITION_DURATION
		weights["intellect_devourer"] = lerp(0.05, 0.12, clamp(progress, 0.0, 1.0))

	# Bandit Necromancer: Summoner
	if game_time >= PHASE_NECROMANCER_START:
		var progress = (game_time - PHASE_NECROMANCER_START) / TRANSITION_DURATION
		weights["bandit_necromancer"] = lerp(0.03, 0.1, clamp(progress, 0.0, 1.0))

	# Kobold Priest: Healer
	if game_time >= PHASE_KOBOLD_START:
		var progress = (game_time - PHASE_KOBOLD_START) / TRANSITION_DURATION
		weights["kobold_priest"] = lerp(0.04, 0.12, clamp(progress, 0.0, 1.0))

	# ===================
	# ENDGAME
	# ===================

	# Shardsoul Slayer: Elite melee (strongest)
	if game_time >= PHASE_SHARDSOUL_START:
		var progress = (game_time - PHASE_SHARDSOUL_START) / TRANSITION_DURATION
		weights["shardsoul_slayer"] = lerp(0.03, 0.1, clamp(progress, 0.0, 1.0))

	return weights

func _apply_difficulty_filter(weights: Dictionary) -> Dictionary:
	"""Apply difficulty-based filtering to spawn weights."""
	# Get current difficulty tier (0-4)
	var difficulty_tier = 0
	if DifficultyManager and DifficultyManager.is_challenge_mode():
		difficulty_tier = DifficultyManager.current_difficulty

	var min_tier = DIFFICULTY_MIN_TIER.get(difficulty_tier, 0)
	var hard_mult = DIFFICULTY_HARD_ENEMY_MULT.get(difficulty_tier, 1.0)

	# Define which enemies are "hard" (tier 10+)
	const HARD_ENEMY_THRESHOLD = 10

	var filtered = {}
	var removed_weight = 0.0

	for enemy_type in weights:
		var tier = ENEMY_TIERS.get(enemy_type, 0)

		if tier < min_tier:
			# Remove this enemy from the pool
			removed_weight += weights[enemy_type]
			filtered[enemy_type] = 0.0
		elif tier >= HARD_ENEMY_THRESHOLD:
			# Apply hard enemy multiplier
			filtered[enemy_type] = weights[enemy_type] * hard_mult
		else:
			filtered[enemy_type] = weights[enemy_type]

	# Redistribute removed weight to remaining mid-tier enemies
	if removed_weight > 0:
		var redistribution_targets = []
		for enemy_type in filtered:
			var tier = ENEMY_TIERS.get(enemy_type, 0)
			# Redistribute to enemies in the mid tiers (min_tier to HARD_ENEMY_THRESHOLD)
			if tier >= min_tier and tier < HARD_ENEMY_THRESHOLD and filtered[enemy_type] > 0:
				redistribution_targets.append(enemy_type)

		if redistribution_targets.size() > 0:
			var bonus_per_enemy = removed_weight / redistribution_targets.size()
			for enemy_type in redistribution_targets:
				filtered[enemy_type] += bonus_per_enemy

	return filtered

func get_scene_for_type(enemy_type: String) -> PackedScene:
	match enemy_type:
		"ratfolk":
			return ratfolk_scene if ratfolk_scene else enemy_scene
		"orc":
			return enemy_scene
		"ratfolk_mage":
			return ratfolk_mage_scene if ratfolk_mage_scene else enemy_scene
		"bat":
			return bat_scene if bat_scene else enemy_scene
		"imp":
			return imp_scene if imp_scene else enemy_scene
		"akaname":
			return akaname_scene if akaname_scene else enemy_scene
		"ghoul":
			return ghoul_scene if ghoul_scene else enemy_scene
		"slime":
			return slime_scene if slime_scene else enemy_scene
		"skeleton":
			return skeleton_scene if skeleton_scene else enemy_scene
		"eye_monster":
			return eye_monster_scene if eye_monster_scene else enemy_scene
		"intellect_devourer":
			return intellect_devourer_scene if intellect_devourer_scene else enemy_scene
		"bandit_necromancer":
			return bandit_necromancer_scene if bandit_necromancer_scene else enemy_scene
		"kobold_priest":
			return kobold_priest_scene if kobold_priest_scene else enemy_scene
		"golem":
			return golem_scene if golem_scene else enemy_scene
		"shardsoul_slayer":
			return shardsoul_slayer_scene if shardsoul_slayer_scene else enemy_scene
		_:
			return enemy_scene

func get_spawn_position() -> Vector2:
	# Spawn from all 4 edges of the arena
	var roll = randf()
	var pos: Vector2
	var margin = 50.0

	if roll < 0.25:
		# Left (spawn just outside left boundary)
		pos = Vector2(ARENA_LEFT - margin, randf_range(ARENA_TOP + margin, ARENA_BOTTOM - margin))
	elif roll < 0.5:
		# Right (spawn just outside right boundary)
		pos = Vector2(ARENA_RIGHT + margin, randf_range(ARENA_TOP + margin, ARENA_BOTTOM - margin))
	elif roll < 0.75:
		# Top
		pos = Vector2(randf_range(ARENA_LEFT + margin, ARENA_RIGHT - margin), ARENA_TOP - margin)
	else:
		# Bottom
		pos = Vector2(randf_range(ARENA_LEFT + margin, ARENA_RIGHT - margin), ARENA_BOTTOM + margin)

	return pos

func set_arena_bounds(bounds: Rect2) -> void:
	"""Set the arena boundaries for enemy spawning."""
	arena_bounds = bounds
	ARENA_LEFT = bounds.position.x
	ARENA_TOP = bounds.position.y
	ARENA_RIGHT = bounds.end.x
	ARENA_BOTTOM = bounds.end.y
	ARENA_WIDTH = bounds.size.x
	ARENA_HEIGHT = bounds.size.y

# ============================================
# CHALLENGE MODE CONTROLS
# ============================================

func stop_spawning() -> void:
	"""Stop all enemy spawning (called when challenge mode boss is killed)."""
	is_spawning_enabled = false

func start_spawning() -> void:
	"""Resume enemy spawning."""
	is_spawning_enabled = true

func get_game_time() -> float:
	"""Get the current game time in seconds."""
	return game_time

# ============================================
# INITIAL SPAWN (Level 0 - Screen Edge)
# ============================================

func _do_initial_spawn() -> void:
	"""Spawn initial enemies at the screen edge so player has immediate action."""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var scene = get_scene_for_type("ratfolk")  # Use weakest enemy for initial spawn
	if not scene:
		scene = enemy_scene

	# Spawn enemies around the screen edge
	for i in range(INITIAL_SPAWN_COUNT):
		var enemy = scene.instantiate()
		enemy.global_position = _get_screen_edge_spawn_position(player)
		get_parent().add_child(enemy)

func _get_screen_edge_spawn_position(player: Node2D) -> Vector2:
	"""Get a spawn position at the edge of the visible screen."""
	var viewport = get_viewport()
	if not viewport:
		return get_spawn_position()  # Fallback to normal spawn

	var screen_size = viewport.get_visible_rect().size
	var camera = viewport.get_camera_2d()
	var player_pos = player.global_position

	# Calculate screen bounds relative to player/camera
	var screen_center = player_pos
	if camera:
		screen_center = camera.global_position

	var half_width = screen_size.x / 2.0
	var half_height = screen_size.y / 2.0

	# Spawn just inside the screen edge (with small offset so they're visible immediately)
	var edge_offset = 30.0  # Pixels inside the screen edge
	var pos: Vector2
	var roll = randf()

	if roll < 0.25:
		# Left edge
		pos = Vector2(screen_center.x - half_width + edge_offset, screen_center.y + randf_range(-half_height * 0.6, half_height * 0.6))
	elif roll < 0.5:
		# Right edge
		pos = Vector2(screen_center.x + half_width - edge_offset, screen_center.y + randf_range(-half_height * 0.6, half_height * 0.6))
	elif roll < 0.75:
		# Top edge
		pos = Vector2(screen_center.x + randf_range(-half_width * 0.6, half_width * 0.6), screen_center.y - half_height + edge_offset)
	else:
		# Bottom edge
		pos = Vector2(screen_center.x + randf_range(-half_width * 0.6, half_width * 0.6), screen_center.y + half_height - edge_offset)

	return pos

# ============================================
# CHAMPION ENEMIES (Nightmare+ Difficulty)
# ============================================

func _should_spawn_champion() -> bool:
	"""Check if this enemy should be a champion."""
	# Check difficulty-based champions (uses tier-specific chance from difficulty data)
	if DifficultyManager and DifficultyManager.has_champion_enemies():
		var chance = DifficultyManager.get_champion_chance()
		if randf() < chance:
			return true

	# Check Champion's Gauntlet curse
	if CurseEffects:
		var curse_chance = CurseEffects.get_champion_chance()
		if curse_chance > 0 and randf() < curse_chance:
			return true

	return false

func _make_champion(enemy: Node) -> void:
	"""Transform a normal enemy into a champion with buffs."""
	if not enemy.has_method("make_champion"):
		# Fallback: apply buffs directly if method doesn't exist
		if "max_health" in enemy:
			enemy.max_health *= 2.0
			if "current_health" in enemy:
				enemy.current_health = enemy.max_health
		if "attack_damage" in enemy:
			enemy.attack_damage *= 1.25
		if "speed" in enemy:
			enemy.speed *= 1.15
		# Visual indicator
		if "scale" in enemy:
			enemy.scale *= 1.2
	else:
		enemy.make_champion()
