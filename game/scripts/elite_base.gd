class_name EliteBase
extends EnemyBase

# Elite Base - Extends EnemyBase for elite enemies with multiple attack types
# Designed to be modular for different elite types (Cyclops, future elites, etc.)

# Signals for health bar UI
signal elite_health_changed(current: float, max_hp: float)
signal elite_died(elite: Node)

# Elite-specific properties
@export var elite_name: String = "Elite"
@export var xp_multiplier: float = 5.0
@export var coin_multiplier: float = 5.0
@export var guaranteed_drop: bool = true

# Attack system - elites can have multiple attack types
enum AttackType { MELEE, RANGED, SPECIAL }

# Attack definitions - override in subclasses
var available_attacks: Array[Dictionary] = []
# Format: { "type": AttackType, "name": "attack_name", "range": float, "cooldown": float, "priority": int }

var attack_cooldowns: Dictionary = {}  # Track cooldown per attack type
var current_attack: Dictionary = {}
var is_using_special: bool = false
var special_timer: float = 0.0

# Warning indicator
var warning_indicator: Label = null
const WARNING_OFFSET: Vector2 = Vector2(0, -80)

func _on_ready() -> void:
	enemy_rarity = "elite"
	# Elites and bosses cannot be pushed by the player
	# Remove player layer (1) from collision mask, keep walls layer (2)
	collision_mask = 2
	_setup_elite()
	_init_attack_cooldowns()

	# Start elite music (unless this is a boss subclass)
	if enemy_rarity == "elite" and SoundManager:
		SoundManager.play_elite_music(self)

# Override in subclasses to setup specific elite properties
func _setup_elite() -> void:
	pass

func _init_attack_cooldowns() -> void:
	for attack in available_attacks:
		attack_cooldowns[attack.name] = 0.0

func _physics_process(delta: float) -> void:
	# Update attack cooldowns
	for attack_name in attack_cooldowns:
		if attack_cooldowns[attack_name] > 0:
			attack_cooldowns[attack_name] -= delta

	# Handle special attack timer
	if is_using_special:
		special_timer -= delta
		if special_timer <= 0:
			_on_special_complete()

	super._physics_process(delta)

# Override behavior for intelligent attack selection
func _process_behavior(delta: float) -> void:
	if is_using_special:
		_process_special_attack(delta)
		return

	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position)
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# Select best attack based on distance and cooldowns
		var best_attack = _select_best_attack(distance)

		if best_attack.is_empty():
			# No attack available, move toward player
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		elif distance > best_attack.range:
			# Move into range for selected attack
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			# In range, execute attack
			velocity = Vector2.ZERO
			if can_attack and attack_cooldowns[best_attack.name] <= 0:
				current_attack = best_attack
				_start_elite_attack(best_attack)
			else:
				update_animation(delta, ROW_IDLE, dir_normalized)
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func _select_best_attack(distance: float) -> Dictionary:
	var valid_attacks: Array[Dictionary] = []

	for attack in available_attacks:
		# Check if attack is off cooldown
		if attack_cooldowns[attack.name] <= 0:
			valid_attacks.append(attack)

	if valid_attacks.is_empty():
		return {}

	# Sort by priority and distance suitability
	var best: Dictionary = {}
	var best_score: float = -1.0

	for attack in valid_attacks:
		var score = attack.priority
		# Bonus score if we're already in range
		if distance <= attack.range:
			score += 10
		# Prefer ranged attacks when far, melee when close
		if attack.type == AttackType.MELEE and distance < 100:
			score += 5
		elif attack.type == AttackType.RANGED and distance > 150:
			score += 5
		elif attack.type == AttackType.SPECIAL:
			score += 3  # Special attacks get slight bonus

		if score > best_score:
			best_score = score
			best = attack

	return best

func _start_elite_attack(attack: Dictionary) -> void:
	can_attack = false
	attack_cooldowns[attack.name] = attack.cooldown

	# Call attack-specific method
	match attack.name:
		_:
			_execute_attack(attack)

# Override in subclasses for specific attack implementations
func _execute_attack(attack: Dictionary) -> void:
	start_attack()  # Default to base windup system

# Override in subclasses for special attack processing
func _process_special_attack(_delta: float) -> void:
	pass

func _on_special_complete() -> void:
	is_using_special = false
	can_attack = false  # Reset attack cooldown

# Show warning indicator (red !)
func show_warning() -> void:
	if warning_indicator == null:
		warning_indicator = Label.new()
		warning_indicator.text = "!"
		warning_indicator.add_theme_font_size_override("font_size", 32)
		warning_indicator.add_theme_color_override("font_color", Color.RED)
		warning_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning_indicator.position = WARNING_OFFSET - Vector2(8, 16)
		add_child(warning_indicator)
	warning_indicator.visible = true

func hide_warning() -> void:
	if warning_indicator:
		warning_indicator.visible = false

# Override die to handle elite-specific rewards
func die() -> void:
	is_dying = true
	current_row = ROW_DEATH
	animation_frame = 0.0
	velocity = Vector2.ZERO

	# Emit elite died signal for UI
	elite_died.emit(self)

	# End elite music (only if this is an elite, not a boss)
	if enemy_rarity == "elite" and SoundManager:
		SoundManager.on_elite_died()

	if SoundManager:
		SoundManager.play_enemy_death()

	flash_timer = 0.0
	if sprite.material:
		sprite.material.set_shader_parameter("flash_intensity", 0.0)

	spawn_death_particles()

	# Award multiplied XP
	if player and is_instance_valid(player) and player.has_method("give_kill_xp"):
		player.give_kill_xp(max_health * xp_multiplier)

	if AbilityManager and player and is_instance_valid(player):
		AbilityManager.on_enemy_killed(self, player)

	remove_from_group("enemies")

	var stats = get_node_or_null("/root/Main/StatsDisplay")
	if stats and stats.has_method("add_kill_points"):
		# Award bonus points for elite kill
		for i in range(int(xp_multiplier)):
			stats.add_kill_points()

	# Signal elite death for spawner tracking
	var elite_spawner = get_node_or_null("/root/Main/EliteSpawner")
	if elite_spawner and elite_spawner.has_method("on_elite_killed"):
		elite_spawner.on_elite_killed(self)

# Override to guarantee item drop for elites
func spawn_gold_coin() -> void:
	if gold_coin_scene == null:
		return

	# Spawn multiple coins based on multiplier
	for i in range(int(coin_multiplier)):
		var coin = gold_coin_scene.instantiate()
		coin.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		get_parent().add_child(coin)

	# Guaranteed item drop for elites
	if guaranteed_drop:
		_drop_guaranteed_item()
	else:
		try_drop_item()

func _drop_guaranteed_item() -> void:
	if dropped_item_scene == null:
		return

	if EquipmentManager == null:
		return

	# Generate item with elite rarity bonus
	var item = EquipmentManager.generate_item("elite")
	var dropped = dropped_item_scene.instantiate()
	dropped.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	dropped.setup(item)
	get_parent().add_child(dropped)

# Override take_damage to emit health changed signal
func take_damage(amount: float, is_critical: bool = false) -> void:
	super.take_damage(amount, is_critical)
	# Emit health changed signal for UI
	elite_health_changed.emit(current_health, max_health)
