extends Node2D

# Enemy scenes - loaded dynamically
@export var enemy_scene: PackedScene  # Orc (legacy, kept for compatibility)
@export var ratfolk_scene: PackedScene
@export var imp_scene: PackedScene
@export var slime_scene: PackedScene
@export var skeleton_scene: PackedScene
@export var kobold_priest_scene: PackedScene

@export var initial_spawn_interval: float = 2.75  # 30% fewer mobs (was 2.0)
@export var final_spawn_interval: float = 0.69  # 30% fewer mobs (was 0.5)
@export var ramp_up_time: float = 90.0
@export var min_spawn_distance: float = 200.0

const ARENA_WIDTH = 1536
const ARENA_HEIGHT = 1382

# Spawn scaling - increases enemy count over time
const SCALING_START_TIME: float = 150.0  # 2.5 minutes
const SCALING_INTERVAL: float = 150.0    # Every 2.5 minutes after that
const SCALING_BONUS: float = 0.10        # 10% more spawns per interval

var spawn_timer: float = 0.0
var game_time: float = 0.0

# Wave timing configuration (in seconds)
# Phase 1: 0:00 - 0:30   - Primarily ratfolk (starter enemies)
# Phase 2: 0:30 - 2:30   - Orcs phase in, ratfolk phase out
# Phase 3: 2:30 - 4:00   - Primarily orcs, imps start appearing
# Phase 4: 4:00 - 5:00   - Orcs + imps, slimes start appearing
# Phase 5: 5:00 - 6:30   - Slimes + skeletons join the mix
# Phase 6: 6:30 - 8:00   - Kobold priests appear (healers)
# Phase 7: 8:00+         - Full enemy variety, continuous scaling

const PHASE_RATFOLK_START: float = 0.0
const PHASE_ORC_START: float = 30.0       # 0:30
const PHASE_IMP_START: float = 150.0      # 2:30
const PHASE_SLIME_START: float = 240.0    # 4:00 (moved earlier)
const PHASE_SKELETON_START: float = 300.0 # 5:00
const PHASE_KOBOLD_START: float = 390.0   # 6:30

# Transition durations (how long it takes to fully phase in/out)
const TRANSITION_DURATION: float = 90.0  # 1.5 minutes for smooth transitions

func _process(delta: float) -> void:
	game_time += delta
	spawn_timer += delta

	var ramp_progress = clamp(game_time / ramp_up_time, 0.0, 1.0)
	var current_interval = lerp(initial_spawn_interval, final_spawn_interval, ramp_progress)

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
		"imp": 0.0,
		"slime": 0.0,
		"skeleton": 0.0,
		"kobold_priest": 0.0,
	}

	# Ratfolk: Starts at 100%, tapers off after orcs appear
	# Peak at start, long tail after 2:30
	if game_time < PHASE_ORC_START:
		weights["ratfolk"] = 1.0
	elif game_time < PHASE_IMP_START:
		# Transition from ratfolk to orc dominant
		var progress = (game_time - PHASE_ORC_START) / TRANSITION_DURATION
		weights["ratfolk"] = lerp(0.8, 0.2, clamp(progress, 0.0, 1.0))
	else:
		# Long tail - ratfolk become rare but never fully disappear
		var late_progress = (game_time - PHASE_IMP_START) / (TRANSITION_DURATION * 2)
		weights["ratfolk"] = lerp(0.2, 0.05, clamp(late_progress, 0.0, 1.0))

	# Orc: Starts appearing at 0:30, becomes dominant by 2:30
	if game_time >= PHASE_ORC_START:
		if game_time < PHASE_IMP_START:
			var progress = (game_time - PHASE_ORC_START) / TRANSITION_DURATION
			weights["orc"] = lerp(0.2, 0.8, clamp(progress, 0.0, 1.0))
		elif game_time < PHASE_SLIME_START:
			# Orcs stay dominant during imp phase
			var progress = (game_time - PHASE_IMP_START) / TRANSITION_DURATION
			weights["orc"] = lerp(0.7, 0.5, clamp(progress, 0.0, 1.0))
		elif game_time < PHASE_SKELETON_START:
			# Orcs reduce as slimes appear
			var progress = (game_time - PHASE_SLIME_START) / TRANSITION_DURATION
			weights["orc"] = lerp(0.5, 0.35, clamp(progress, 0.0, 1.0))
		else:
			# Late game - orcs reduce more as skeletons appear
			var progress = (game_time - PHASE_SKELETON_START) / TRANSITION_DURATION
			weights["orc"] = lerp(0.35, 0.25, clamp(progress, 0.0, 1.0))

	# Imp: Starts appearing at 2:30, ramps up gradually
	if game_time >= PHASE_IMP_START:
		if game_time < PHASE_SLIME_START:
			var progress = (game_time - PHASE_IMP_START) / TRANSITION_DURATION
			weights["imp"] = lerp(0.1, 0.3, clamp(progress, 0.0, 1.0))
		elif game_time < PHASE_KOBOLD_START:
			# Imps stay consistent until kobolds appear
			weights["imp"] = 0.25
		else:
			# Imps reduce slightly when kobolds appear (less ranged spam)
			var progress = (game_time - PHASE_KOBOLD_START) / TRANSITION_DURATION
			weights["imp"] = lerp(0.25, 0.18, clamp(progress, 0.0, 1.0))

	# Slime: Starts appearing at 4:00, slowly ramps up
	if game_time >= PHASE_SLIME_START:
		if game_time < PHASE_SKELETON_START:
			var progress = (game_time - PHASE_SLIME_START) / TRANSITION_DURATION
			weights["slime"] = lerp(0.1, 0.2, clamp(progress, 0.0, 1.0))
		else:
			# Slimes stay consistent in late game
			weights["slime"] = 0.15

	# Skeleton: Starts appearing at 5:00, fast and hard-hitting threat
	if game_time >= PHASE_SKELETON_START:
		if game_time < PHASE_KOBOLD_START:
			var progress = (game_time - PHASE_SKELETON_START) / TRANSITION_DURATION
			weights["skeleton"] = lerp(0.1, 0.25, clamp(progress, 0.0, 1.0))
		else:
			# Skeletons stay as a major threat
			var progress = (game_time - PHASE_KOBOLD_START) / TRANSITION_DURATION
			weights["skeleton"] = lerp(0.25, 0.22, clamp(progress, 0.0, 1.0))

	# Kobold Priest: Starts appearing at 6:30, dangerous healer support
	if game_time >= PHASE_KOBOLD_START:
		var progress = (game_time - PHASE_KOBOLD_START) / TRANSITION_DURATION
		# Kobolds are rare but impactful - they heal other enemies
		weights["kobold_priest"] = lerp(0.05, 0.12, clamp(progress, 0.0, 1.0))

	return weights

func get_scene_for_type(enemy_type: String) -> PackedScene:
	match enemy_type:
		"ratfolk":
			return ratfolk_scene if ratfolk_scene else enemy_scene
		"orc":
			return enemy_scene
		"imp":
			return imp_scene if imp_scene else enemy_scene
		"slime":
			return slime_scene if slime_scene else enemy_scene
		"skeleton":
			return skeleton_scene if skeleton_scene else enemy_scene
		"kobold_priest":
			return kobold_priest_scene if kobold_priest_scene else enemy_scene
		_:
			return enemy_scene

func get_spawn_position() -> Vector2:
	var edge = randi() % 4
	var pos: Vector2

	match edge:
		0:  # Top
			pos = Vector2(randf_range(50, ARENA_WIDTH - 50), -50)
		1:  # Bottom
			pos = Vector2(randf_range(50, ARENA_WIDTH - 50), ARENA_HEIGHT + 50)
		2:  # Left
			pos = Vector2(-50, randf_range(50, ARENA_HEIGHT - 50))
		3:  # Right
			pos = Vector2(ARENA_WIDTH + 50, randf_range(50, ARENA_HEIGHT - 50))

	return pos
