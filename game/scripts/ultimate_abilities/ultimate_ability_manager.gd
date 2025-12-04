extends Node

# Singleton for managing Ultimate abilities - unlocked at level 15

signal ultimate_acquired(ability: UltimateAbilityData)
signal ultimate_used(ability: UltimateAbilityData)
signal ultimate_cooldown_updated(remaining: float, total: float)
signal ultimate_ready()

# Level at which ultimate unlocks
const ULTIMATE_UNLOCK_LEVEL: int = 15

# Current ultimate ability
var current_ultimate: UltimateAbilityData = null
var cooldown_timer: float = 0.0
var is_executing: bool = false

# Keyboard input state
var _ultimate_key_held: bool = false

# Reference to player
var player: Node2D = null

# Reference to activation overlay
var activation_overlay: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("ultimate_ability_manager")

	# Initialize database
	UltimateAbilityDatabase.initialize()

func _process(delta: float) -> void:
	# Update cooldown timer (respects time scale for normal gameplay)
	if cooldown_timer > 0 and not is_executing:
		# Use unscaled delta during time manipulation
		var actual_delta = delta
		if Engine.time_scale < 1.0 and Engine.time_scale > 0:
			actual_delta = delta / Engine.time_scale

		cooldown_timer = max(0.0, cooldown_timer - actual_delta)
		if current_ultimate:
			emit_signal("ultimate_cooldown_updated", cooldown_timer, current_ultimate.cooldown)

		if cooldown_timer <= 0:
			emit_signal("ultimate_ready")

	# Keyboard shortcut for ultimate: '/5
	if not get_tree().paused and not is_executing:
		if Input.is_key_pressed(KEY_APOSTROPHE) or Input.is_key_pressed(KEY_5):
			if not _ultimate_key_held:
				_ultimate_key_held = true
				use_ultimate()
		else:
			_ultimate_key_held = false

func reset_for_new_run() -> void:
	"""Reset ultimate for a new game run."""
	current_ultimate = null
	cooldown_timer = 0.0
	is_executing = false

func register_player(p: Node2D) -> void:
	"""Register the player reference for ability execution."""
	player = p

func register_activation_overlay(overlay: Node) -> void:
	"""Register the comic book activation overlay."""
	activation_overlay = overlay

# ============================================
# ULTIMATE MANAGEMENT
# ============================================

func has_ultimate() -> bool:
	"""Check if player has acquired an ultimate."""
	return current_ultimate != null

func acquire_ultimate(ability: UltimateAbilityData) -> void:
	"""Set the player's ultimate ability."""
	current_ultimate = ability
	cooldown_timer = 0.0  # Ready to use immediately
	emit_signal("ultimate_acquired", ability)
	emit_signal("ultimate_ready")

func get_current_ultimate() -> UltimateAbilityData:
	"""Get the current ultimate ability."""
	return current_ultimate

# ============================================
# ULTIMATE EXECUTION
# ============================================

func can_use_ultimate() -> bool:
	"""Check if ultimate is ready to use."""
	if current_ultimate == null:
		return false
	if cooldown_timer > 0:
		return false
	if is_executing:
		return false
	if player and player.is_dead:
		return false
	return true

func use_ultimate() -> bool:
	"""Attempt to use the ultimate ability. Returns true if successful."""
	if not can_use_ultimate():
		return false

	is_executing = true

	# Start the epic activation sequence
	_start_activation_sequence()

	return true

func _start_activation_sequence() -> void:
	"""Begin the comic book activation sequence."""
	if not current_ultimate:
		is_executing = false
		return

	# Play epic haptic feedback
	if HapticManager:
		HapticManager.ultimate()

	# Trigger the activation overlay
	if activation_overlay and activation_overlay.has_method("play_activation"):
		activation_overlay.play_activation(current_ultimate, player, _on_activation_complete)
	else:
		# Fallback if no overlay - just execute immediately
		# Note: _on_activation_complete already calls _execute_ultimate, so don't call it here
		_on_activation_complete()

func _on_activation_complete() -> void:
	"""Called when activation sequence finishes."""
	# Execute the actual ability effect
	_execute_ultimate()

	# Start cooldown (with any cooldown reduction)
	var cooldown = current_ultimate.cooldown * _get_cooldown_multiplier()
	cooldown_timer = cooldown

	emit_signal("ultimate_used", current_ultimate)
	is_executing = false

func _execute_ultimate() -> void:
	"""Execute the ultimate ability effect."""
	if not player or not current_ultimate:
		return

	# Get the executor and run the ability
	var executor = _get_ultimate_executor()
	if executor:
		executor.execute(current_ultimate, player)

	# Big screen shake
	if JuiceManager:
		JuiceManager.shake_ultimate()

	# Big haptic at moment of release
	if HapticManager:
		HapticManager.heavy()

func _get_ultimate_executor() -> Node:
	"""Get or create the ultimate ability executor node."""
	var executor = get_node_or_null("UltimateAbilityExecutor")
	if not executor:
		var executor_script = load("res://scripts/ultimate_abilities/ultimate_ability_executor.gd")
		if executor_script:
			executor = Node.new()
			executor.set_script(executor_script)
			executor.name = "UltimateAbilityExecutor"
			add_child(executor)
	return executor

func _get_cooldown_multiplier() -> float:
	"""Get cooldown multiplier from permanent upgrades."""
	var multiplier = 1.0

	if PermanentUpgrades:
		var reduction = PermanentUpgrades.get_all_bonuses().get("cooldown_reduction", 0.0)
		multiplier -= reduction

	return maxf(multiplier, 0.1)

# ============================================
# COOLDOWN HELPERS
# ============================================

func get_cooldown_remaining() -> float:
	"""Get remaining cooldown."""
	return cooldown_timer

func get_cooldown_percent() -> float:
	"""Get cooldown progress (0 = ready, 1 = just used)."""
	if current_ultimate == null or current_ultimate.cooldown <= 0:
		return 0.0
	var modified_cooldown = current_ultimate.cooldown * _get_cooldown_multiplier()
	return cooldown_timer / modified_cooldown

func is_ready() -> bool:
	"""Check if ultimate is ready (has ability and off cooldown)."""
	return current_ultimate != null and cooldown_timer <= 0 and not is_executing

func reduce_cooldown(amount: float) -> void:
	"""Reduce ultimate cooldown by a flat amount."""
	if cooldown_timer > 0:
		cooldown_timer = maxf(0.0, cooldown_timer - amount)
		if cooldown_timer <= 0:
			emit_signal("ultimate_ready")

# ============================================
# SELECTION FOR LEVEL UP
# ============================================

func is_ultimate_unlock_level(level: int) -> bool:
	"""Check if this level grants ultimate ability choice."""
	return level == ULTIMATE_UNLOCK_LEVEL

func get_random_ultimates_for_selection(character_class_id: String, count: int = 3) -> Array:
	"""Get random ultimates for the level 15 selection screen."""
	var ultimate_class = _convert_character_id_to_class(character_class_id)
	return UltimateAbilityDatabase.get_random_ultimates_for_class(ultimate_class, count)

func _convert_character_id_to_class(character_id: String) -> UltimateAbilityData.CharacterClass:
	"""Convert character ID string to UltimateAbilityData.CharacterClass enum."""
	match character_id:
		"archer":
			return UltimateAbilityData.CharacterClass.ARCHER
		"knight":
			return UltimateAbilityData.CharacterClass.KNIGHT
		"beast":
			return UltimateAbilityData.CharacterClass.BEAST
		"mage":
			return UltimateAbilityData.CharacterClass.MAGE
		"monk":
			return UltimateAbilityData.CharacterClass.MONK
	return UltimateAbilityData.CharacterClass.ARCHER
