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

@export var initial_spawn_interval: float = 2.75  # 30% fewer mobs (was 2.0)
@export var final_spawn_interval: float = 0.69  # 30% fewer mobs (was 0.5)
@export var ramp_up_time: float = 90.0
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

# Wave timing configuration (in seconds) - 20 minute progression
# Phase 1: 0:00 - 1:00   - Primarily ratfolk (starter enemies)
# Phase 2: 1:00 - 2:00   - Orcs phase in, ratfolk phase out
# Phase 3: 2:30 - 3:30   - Ratfolk Mage appears (early caster)
# Phase 4: 3:30 - 4:30   - Bats appear (fast glass cannons)
# Phase 5: 5:00 - 6:00   - Imps start appearing
# Phase 6: 6:00 - 7:00   - Akaname (poison) joins
# Phase 7: 7:00 - 8:00   - Ghouls appear (tanky melee)
# Phase 8: 8:00 - 9:00   - Slimes start appearing
# Phase 9: 10:00 - 11:00 - Skeletons join
# Phase 10: 11:00 - 12:00 - Eye Monsters (acid ranged)
# Phase 11: 13:00 - 14:00 - Intellect Devourers (ability drain)
# Phase 12: 14:00 - 15:00 - Bandit Necromancers (summoners)
# Phase 13: 16:00 - 17:00 - Kobold priests (healers)
# Phase 14: 18:00 - 19:00 - Golems (tanks)
# Phase 15: 20:00+        - Shardsoul Slayers (elite melee)

const PHASE_RATFOLK_START: float = 0.0
const PHASE_ORC_START: float = 60.0            # 1:00
const PHASE_RATFOLK_MAGE_START: float = 150.0  # 2:30
const PHASE_BAT_START: float = 210.0           # 3:30
const PHASE_IMP_START: float = 300.0           # 5:00
const PHASE_AKANAME_START: float = 360.0       # 6:00
const PHASE_GHOUL_START: float = 420.0         # 7:00
const PHASE_SLIME_START: float = 480.0         # 8:00
const PHASE_SKELETON_START: float = 600.0      # 10:00
const PHASE_EYE_MONSTER_START: float = 660.0   # 11:00
const PHASE_INTELLECT_START: float = 780.0     # 13:00
const PHASE_NECROMANCER_START: float = 840.0   # 14:00
const PHASE_KOBOLD_START: float = 960.0        # 16:00
const PHASE_GOLEM_START: float = 1080.0        # 18:00
const PHASE_SHARDSOUL_START: float = 1200.0    # 20:00

# Transition durations (how long it takes to fully phase in/out)
const TRANSITION_DURATION: float = 90.0  # 1.5 minutes for smooth transitions

func _process(delta: float) -> void:
	game_time += delta

	# Don't spawn if disabled (challenge mode after boss killed)
	if not is_spawning_enabled:
		return

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
		"intellect_devourer": 0.0,
		"bandit_necromancer": 0.0,
		"kobold_priest": 0.0,
		"golem": 0.0,
		"shardsoul_slayer": 0.0,
	}

	# ===================
	# EARLY GAME (0:00 - 2:30)
	# ===================

	# Ratfolk: Starts at 100%, tapers off gradually
	if game_time < PHASE_ORC_START:
		weights["ratfolk"] = 1.0
	elif game_time < PHASE_IMP_START:
		var progress = (game_time - PHASE_ORC_START) / TRANSITION_DURATION
		weights["ratfolk"] = lerp(0.7, 0.15, clamp(progress, 0.0, 1.0))
	else:
		weights["ratfolk"] = lerp(0.15, 0.03, clamp((game_time - PHASE_IMP_START) / 300.0, 0.0, 1.0))

	# Orc: Appears at 0:30, core enemy throughout
	if game_time >= PHASE_ORC_START:
		if game_time < PHASE_IMP_START:
			var progress = (game_time - PHASE_ORC_START) / TRANSITION_DURATION
			weights["orc"] = lerp(0.2, 0.6, clamp(progress, 0.0, 1.0))
		elif game_time < PHASE_GOLEM_START:
			weights["orc"] = lerp(0.5, 0.2, clamp((game_time - PHASE_IMP_START) / 300.0, 0.0, 1.0))
		else:
			weights["orc"] = 0.12

	# Ratfolk Mage: Early caster at 1:30, introduces ranged threats early
	if game_time >= PHASE_RATFOLK_MAGE_START:
		if game_time < PHASE_NECROMANCER_START:
			var progress = (game_time - PHASE_RATFOLK_MAGE_START) / TRANSITION_DURATION
			weights["ratfolk_mage"] = lerp(0.08, 0.18, clamp(progress, 0.0, 1.0))
		else:
			weights["ratfolk_mage"] = lerp(0.15, 0.08, clamp((game_time - PHASE_NECROMANCER_START) / 180.0, 0.0, 1.0))

	# Bat: Fast glass cannons at 2:00
	if game_time >= PHASE_BAT_START:
		if game_time < PHASE_SKELETON_START:
			var progress = (game_time - PHASE_BAT_START) / TRANSITION_DURATION
			weights["bat"] = lerp(0.1, 0.2, clamp(progress, 0.0, 1.0))
		else:
			weights["bat"] = lerp(0.18, 0.1, clamp((game_time - PHASE_SKELETON_START) / 180.0, 0.0, 1.0))

	# ===================
	# MID GAME (2:30 - 5:00)
	# ===================

	# Imp: Ranged at 2:30
	if game_time >= PHASE_IMP_START:
		if game_time < PHASE_EYE_MONSTER_START:
			var progress = (game_time - PHASE_IMP_START) / TRANSITION_DURATION
			weights["imp"] = lerp(0.1, 0.22, clamp(progress, 0.0, 1.0))
		else:
			weights["imp"] = lerp(0.2, 0.1, clamp((game_time - PHASE_EYE_MONSTER_START) / 180.0, 0.0, 1.0))

	# Akaname: Poison at 3:00
	if game_time >= PHASE_AKANAME_START:
		if game_time < PHASE_INTELLECT_START:
			var progress = (game_time - PHASE_AKANAME_START) / TRANSITION_DURATION
			weights["akaname"] = lerp(0.08, 0.16, clamp(progress, 0.0, 1.0))
		else:
			weights["akaname"] = 0.1

	# Ghoul: Tanky melee at 3:30
	if game_time >= PHASE_GHOUL_START:
		if game_time < PHASE_GOLEM_START:
			var progress = (game_time - PHASE_GHOUL_START) / TRANSITION_DURATION
			weights["ghoul"] = lerp(0.1, 0.2, clamp(progress, 0.0, 1.0))
		else:
			weights["ghoul"] = lerp(0.18, 0.1, clamp((game_time - PHASE_GOLEM_START) / 120.0, 0.0, 1.0))

	# Slime: Tank at 4:00
	if game_time >= PHASE_SLIME_START:
		if game_time < PHASE_GOLEM_START:
			var progress = (game_time - PHASE_SLIME_START) / TRANSITION_DURATION
			weights["slime"] = lerp(0.08, 0.15, clamp(progress, 0.0, 1.0))
		else:
			weights["slime"] = 0.08

	# Skeleton: Hard-hitters at 5:00
	if game_time >= PHASE_SKELETON_START:
		if game_time < PHASE_SHARDSOUL_START:
			var progress = (game_time - PHASE_SKELETON_START) / TRANSITION_DURATION
			weights["skeleton"] = lerp(0.1, 0.2, clamp(progress, 0.0, 1.0))
		else:
			weights["skeleton"] = lerp(0.18, 0.1, clamp((game_time - PHASE_SHARDSOUL_START) / 120.0, 0.0, 1.0))

	# ===================
	# LATE GAME (5:00 - 8:00)
	# ===================

	# Eye Monster: Acid ranged at 5:30
	if game_time >= PHASE_EYE_MONSTER_START:
		var progress = (game_time - PHASE_EYE_MONSTER_START) / TRANSITION_DURATION
		weights["eye_monster"] = lerp(0.06, 0.14, clamp(progress, 0.0, 1.0))

	# Intellect Devourer: Ability drain at 6:30
	if game_time >= PHASE_INTELLECT_START:
		var progress = (game_time - PHASE_INTELLECT_START) / TRANSITION_DURATION
		weights["intellect_devourer"] = lerp(0.05, 0.12, clamp(progress, 0.0, 1.0))

	# Bandit Necromancer: Summoners at 7:00 (rare but dangerous)
	if game_time >= PHASE_NECROMANCER_START:
		var progress = (game_time - PHASE_NECROMANCER_START) / TRANSITION_DURATION
		weights["bandit_necromancer"] = lerp(0.03, 0.08, clamp(progress, 0.0, 1.0))

	# Kobold Priest: Healers at 8:00
	if game_time >= PHASE_KOBOLD_START:
		var progress = (game_time - PHASE_KOBOLD_START) / TRANSITION_DURATION
		weights["kobold_priest"] = lerp(0.04, 0.1, clamp(progress, 0.0, 1.0))

	# ===================
	# ENDGAME (9:00+)
	# ===================

	# Golem: Massive tanks at 9:00 (rare)
	if game_time >= PHASE_GOLEM_START:
		var progress = (game_time - PHASE_GOLEM_START) / TRANSITION_DURATION
		weights["golem"] = lerp(0.02, 0.06, clamp(progress, 0.0, 1.0))

	# Shardsoul Slayer: Elite melee at 10:00 (rare but deadly)
	if game_time >= PHASE_SHARDSOUL_START:
		var progress = (game_time - PHASE_SHARDSOUL_START) / TRANSITION_DURATION
		weights["shardsoul_slayer"] = lerp(0.02, 0.08, clamp(progress, 0.0, 1.0))

	return weights

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
# CHAMPION ENEMIES (Nightmare+ Difficulty)
# ============================================

const CHAMPION_SPAWN_CHANCE: float = 0.08  # 8% chance per enemy

func _should_spawn_champion() -> bool:
	"""Check if this enemy should be a champion."""
	# Check difficulty-based champions
	if DifficultyManager and DifficultyManager.has_champion_enemies():
		if randf() < CHAMPION_SPAWN_CHANCE:
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
