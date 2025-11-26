extends CharacterBody2D

@export var speed: float = 180.0  # 3 pixels/frame * 60fps
@export var animation_speed: float = 10.0
@export var attack_cooldown: float = 0.79  # ~1.27 attacks per second (25% slower)
@export var fire_range: float = 440.0  # 55 frames * 8 pixels/frame
@export var arrow_scene: PackedScene
@export var max_health: float = 25.0
@export var damage_number_scene: PackedScene
@export var muzzle_flash_scene: PackedScene
@export var swipe_effect_scene: PackedScene

# Camera
@onready var camera: Camera2D = $Camera2D
var camera_lerp_speed: float = 8.0

# Recoil
var recoil_offset: Vector2 = Vector2.ZERO
var recoil_recovery: float = 15.0

# Base stats (for ability modifications)
var base_speed: float
var base_attack_cooldown: float
var base_max_health: float
var base_damage: float = 1.0

var current_health: float
@onready var health_bar: Node2D = $HealthBar

# Ability-related stats
var pickup_range_multiplier: float = 1.0
var size_scale: float = 1.0

# Temporary buffs
var temp_speed_boost: float = 0.0
var temp_speed_timer: float = 0.0
var temp_attack_speed_boost: float = 0.0
var temp_attack_speed_timer: float = 0.0

# Active buffs tracking for UI {buff_id: {timer: float, duration: float, name: String, description: String, color: Color}}
var active_buffs: Dictionary = {}
signal buff_changed(buffs: Dictionary)

# Heal accumulator (for small heals that would round to 0)
var accumulated_heal: float = 0.0

# Joystick input (replaces direct touch)
var joystick: Control = null
var joystick_direction: Vector2 = Vector2.ZERO

# Character data
var character_data: CharacterData = null
var is_melee: bool = false

# Animation rows - dynamically set based on character
var row_idle: int = 0
var row_move: int = 1
var row_attack: int = 2
var row_attack_up: int = 3
var row_attack_down: int = 4
var row_damage: int = 5
var row_death: int = 6

var cols_per_row: int = 8

var frame_counts: Dictionary = {}

var current_row: int = 0
var animation_frame: float = 0.0
@onready var sprite: Sprite2D = $Sprite

# Combat
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT
var facing_right: bool = true

# Melee attack hitbox
var melee_hitbox_active: bool = false
var melee_hit_enemies: Array = []  # Track enemies hit this attack

# Death state
var is_dead: bool = false
var death_animation_finished: bool = false

# XP System
var current_xp: float = 0.0
var xp_to_next_level: float = 531.6  # Base XP required (30% reduction from 759.4)
var current_level: int = 1

signal xp_changed(current_xp: float, xp_needed: float, level: int)
signal level_up(new_level: int)
signal health_changed(current_health: float, max_health: float)
signal player_died()

func _ready() -> void:
	# Load character data from CharacterManager
	_load_character_data()

	# Store base stats for ability calculations
	base_speed = speed
	base_attack_cooldown = attack_cooldown
	base_max_health = max_health
	base_damage = character_data.base_damage if character_data else 1.0

	# Apply permanent upgrades to base stats
	_apply_permanent_upgrades()

	# Apply character passive bonuses
	_apply_character_passive()

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Register camera with JuiceManager for screen shake
	if camera and JuiceManager:
		JuiceManager.register_camera(camera)
		# Disable camera position smoothing since we do it manually
		camera.position_smoothing_enabled = false

func _load_character_data() -> void:
	if not CharacterManager:
		# Fallback to archer defaults
		_setup_archer_defaults()
		return

	character_data = CharacterManager.get_selected_character()
	if character_data == null:
		_setup_archer_defaults()
		return

	# Apply character stats
	speed = character_data.base_speed
	attack_cooldown = character_data.base_attack_cooldown
	max_health = character_data.base_health
	fire_range = character_data.attack_range
	is_melee = character_data.attack_type == CharacterData.AttackType.MELEE

	# Setup sprite
	if sprite and character_data.sprite_texture:
		sprite.texture = character_data.sprite_texture
		sprite.hframes = character_data.hframes
		sprite.vframes = character_data.vframes
		sprite.scale = character_data.sprite_scale

	# Setup animation rows
	row_idle = character_data.row_idle
	row_move = character_data.row_move
	row_attack = character_data.row_attack
	row_attack_up = character_data.row_attack_up
	row_attack_down = character_data.row_attack_down
	row_damage = character_data.row_damage
	row_death = character_data.row_death
	cols_per_row = character_data.hframes

	# Setup frame counts
	frame_counts = {
		row_idle: character_data.frames_idle,
		row_move: character_data.frames_move,
		row_attack: character_data.frames_attack,
		row_attack_up: character_data.frames_attack_up,
		row_attack_down: character_data.frames_attack_down,
		row_damage: character_data.frames_damage,
		row_death: character_data.frames_death,
	}

	current_row = row_idle

func _setup_archer_defaults() -> void:
	# Fallback archer configuration
	is_melee = false
	row_idle = 0
	row_move = 1
	row_attack = 2
	row_attack_up = 3
	row_attack_down = 4
	row_damage = 5
	row_death = 6
	cols_per_row = 8

	frame_counts = {
		row_idle: 4,
		row_move: 8,
		row_attack: 8,
		row_attack_up: 8,
		row_attack_down: 8,
		row_damage: 4,
		row_death: 4,
	}

	current_row = row_idle

func _apply_character_passive() -> void:
	if not CharacterManager:
		return

	var bonuses = CharacterManager.get_passive_bonuses()

	# Apply max HP bonus from passive
	var hp_bonus = bonuses.get("max_hp", 0.0)
	if hp_bonus > 0:
		base_max_health = base_max_health * (1.0 + hp_bonus)
		max_health = base_max_health

func _apply_permanent_upgrades() -> void:
	if not PermanentUpgrades:
		return

	var bonuses = PermanentUpgrades.get_all_bonuses()

	# Apply max HP bonus
	var hp_bonus = bonuses.get("max_hp", 0.0)
	base_max_health = base_max_health * (1.0 + hp_bonus)
	max_health = base_max_health

	# Apply movement speed bonus
	var speed_bonus = bonuses.get("move_speed", 0.0)
	base_speed = base_speed * (1.0 + speed_bonus)
	speed = base_speed

	# Apply attack speed bonus
	var attack_speed_bonus = bonuses.get("attack_speed", 0.0)
	base_attack_cooldown = base_attack_cooldown / (1.0 + attack_speed_bonus)
	attack_cooldown = base_attack_cooldown

	# Apply pickup range bonus
	var pickup_bonus = bonuses.get("pickup_range", 0.0)
	pickup_range_multiplier = 1.0 + pickup_bonus

func take_damage(amount: float) -> void:
	# Check for invulnerability (from dodge or abilities)
	if is_invulnerable:
		return

	# Check for dodge first
	if AbilityManager:
		var dodge_chance = AbilityManager.get_dodge_chance()
		if randf() < dodge_chance:
			# Dodged the attack!
			spawn_dodge_text()
			return

	# Check for block
	var was_blocked = false
	if AbilityManager:
		var block_chance = AbilityManager.get_block_chance()
		if randf() < block_chance:
			was_blocked = true

	# Transcendence shields absorb damage first
	var damage_after_shields = amount
	if AbilityManager:
		damage_after_shields = AbilityManager.damage_transcendence_shields(amount)
		if damage_after_shields <= 0:
			# All damage absorbed by shields
			spawn_shield_text()
			return

	# Calculate total damage reduction
	var final_damage = damage_after_shields
	var total_reduction = 0.0

	# Add permanent upgrade damage reduction
	if PermanentUpgrades:
		total_reduction += PermanentUpgrades.get_all_bonuses().get("damage_reduction", 0.0)

	# Add equipment damage reduction
	if AbilityManager:
		total_reduction += AbilityManager.get_equipment_damage_reduction()

	# Add character passive damage reduction (Knight's Iron Will - conditional)
	if CharacterManager:
		var bonuses = CharacterManager.get_passive_bonuses()
		var passive_reduction = bonuses.get("damage_reduction", 0.0)
		var threshold = bonuses.get("damage_reduction_threshold", 0.0)
		if passive_reduction > 0 and threshold > 0:
			var health_percent = current_health / max_health
			if health_percent < threshold:
				total_reduction += passive_reduction

	# Apply total damage reduction (cap at 75% to prevent invincibility)
	total_reduction = min(total_reduction, 0.75)
	final_damage = amount * (1.0 - total_reduction)

	# Block reduces damage by 50%
	if was_blocked:
		final_damage *= 0.5

	current_health -= final_damage
	if health_bar:
		health_bar.set_health(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)

	# Play player hurt sound
	if SoundManager:
		SoundManager.play_player_hurt()

	# Haptic feedback on damage
	if HapticManager:
		HapticManager.damage()

	# Spawn damage number (red for player, show blocked if applicable)
	if was_blocked:
		spawn_blocked_damage_number(final_damage)
	else:
		spawn_damage_number(final_damage)

	# Trigger Retribution explosion when taking damage
	if AbilityManager:
		AbilityManager.trigger_retribution(global_position)

	# Screen shake and damage flash when taking damage
	if JuiceManager:
		if was_blocked:
			JuiceManager.shake_small()  # Less shake when blocked
		else:
			JuiceManager.shake_medium()
		JuiceManager.damage_flash()
		JuiceManager.update_player_health(current_health / max_health)

	if current_health <= 0 and not is_dead:
		current_health = 0
		# Check for phoenix revive before dying
		if AbilityManager and AbilityManager.try_phoenix_revive(self):
			return  # Phoenix triggered, don't die
		is_dead = true
		death_animation_finished = false
		animation_frame = 0.0
		current_row = row_death
		emit_signal("player_died")
		if JuiceManager:
			JuiceManager.shake_large()
		# Strong haptic feedback on death
		if HapticManager:
			HapticManager.death()

func spawn_damage_number(amount: float) -> void:
	if damage_number_scene == null:
		return

	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -40)
	get_parent().add_child(dmg_num)
	dmg_num.set_damage(amount, false, true)  # is_player_damage = true

func spawn_blocked_damage_number(amount: float) -> void:
	if damage_number_scene == null:
		return

	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -40)
	get_parent().add_child(dmg_num)
	if dmg_num.has_method("set_blocked"):
		dmg_num.set_blocked(amount)
	else:
		dmg_num.set_damage(amount, false, true)

func spawn_dodge_text() -> void:
	if damage_number_scene == null:
		return

	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -40)
	get_parent().add_child(dmg_num)
	if dmg_num.has_method("set_dodge"):
		dmg_num.set_dodge()
	else:
		# Fallback - just show 0 damage
		dmg_num.set_damage(0, false, true)

func spawn_shield_text() -> void:
	if damage_number_scene == null:
		return

	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -40)
	get_parent().add_child(dmg_num)
	if dmg_num.has_method("set_shield"):
		dmg_num.set_shield()
	else:
		# Fallback - just show 0 damage with shield color
		dmg_num.set_damage(0, false, true)

func register_joystick(js: Control) -> void:
	joystick = js
	if joystick.has_signal("direction_changed"):
		joystick.direction_changed.connect(_on_joystick_direction_changed)

func _on_joystick_direction_changed(direction: Vector2) -> void:
	joystick_direction = direction

func _physics_process(delta: float) -> void:
	# If dead, only update death animation
	if is_dead:
		update_death_animation(delta)
		return

	# Update temporary buffs
	var buffs_changed = false
	if temp_speed_timer > 0:
		temp_speed_timer -= delta
		if temp_speed_timer <= 0:
			temp_speed_boost = 0.0
			if active_buffs.has("speed_boost"):
				active_buffs.erase("speed_boost")
				buffs_changed = true
		elif active_buffs.has("speed_boost"):
			active_buffs["speed_boost"].timer = temp_speed_timer

	if temp_attack_speed_timer > 0:
		temp_attack_speed_timer -= delta
		if temp_attack_speed_timer <= 0:
			temp_attack_speed_boost = 0.0
			if active_buffs.has("attack_speed_boost"):
				active_buffs.erase("attack_speed_boost")
				buffs_changed = true
		elif active_buffs.has("attack_speed_boost"):
			active_buffs["attack_speed_boost"].timer = temp_attack_speed_timer

	# Track conditional ability buffs
	if AbilityManager:
		var is_standing_still = velocity.length() < 5.0
		var is_moving = velocity.length() > 50.0

		# Focus Regen - active when standing still
		if AbilityManager.has_focus_regen:
			if is_standing_still and not active_buffs.has("focus_regen"):
				active_buffs["focus_regen"] = {
					"timer": -1, "duration": -1,  # Infinite while condition met
					"name": "Focus",
					"description": "Regenerating HP",
					"color": Color(0.2, 0.9, 0.4)  # Green
				}
				buffs_changed = true
			elif not is_standing_still and active_buffs.has("focus_regen"):
				active_buffs.erase("focus_regen")
				buffs_changed = true

		# Practiced Stance - active when standing still
		if AbilityManager.has_practiced_stance:
			if is_standing_still and not active_buffs.has("practiced_stance"):
				active_buffs["practiced_stance"] = {
					"timer": -1, "duration": -1,
					"name": "Stance",
					"description": "+" + str(int(AbilityManager.practiced_stance_bonus * 100)) + "% Damage",
					"color": Color(0.9, 0.6, 0.2)  # Orange
				}
				buffs_changed = true
			elif not is_standing_still and active_buffs.has("practiced_stance"):
				active_buffs.erase("practiced_stance")
				buffs_changed = true

		# Momentum - active when moving
		if AbilityManager.has_momentum:
			if is_moving and not active_buffs.has("momentum"):
				active_buffs["momentum"] = {
					"timer": -1, "duration": -1,
					"name": "Momentum",
					"description": "+" + str(int(AbilityManager.momentum_bonus * 100)) + "% Damage",
					"color": Color(0.4, 0.7, 1.0)  # Blue
				}
				buffs_changed = true
			elif not is_moving and active_buffs.has("momentum"):
				active_buffs.erase("momentum")
				buffs_changed = true

		# Combat Momentum - active when stacks > 0
		if AbilityManager.has_combat_momentum:
			if AbilityManager.combat_momentum_stacks > 0 and not active_buffs.has("combat_momentum"):
				active_buffs["combat_momentum"] = {
					"timer": -1, "duration": -1,
					"name": "C.Momentum",
					"description": str(AbilityManager.combat_momentum_stacks) + " stacks",
					"color": Color(0.9, 0.3, 0.5)  # Pink
				}
				buffs_changed = true
			elif AbilityManager.combat_momentum_stacks > 0 and active_buffs.has("combat_momentum"):
				# Update stack count
				active_buffs["combat_momentum"].description = str(AbilityManager.combat_momentum_stacks) + " stacks"
			elif AbilityManager.combat_momentum_stacks == 0 and active_buffs.has("combat_momentum"):
				active_buffs.erase("combat_momentum")
				buffs_changed = true

		# Rampage - kill streak damage bonus
		if AbilityManager.has_rampage:
			if AbilityManager.rampage_stacks > 0:
				if not active_buffs.has("rampage"):
					active_buffs["rampage"] = {
						"timer": AbilityManager.rampage_timer, "duration": AbilityManager.RAMPAGE_DECAY_TIME,
						"name": "Rampage",
						"description": "+" + str(AbilityManager.rampage_stacks * 3) + "% DMG",
						"color": Color(1.0, 0.3, 0.2)  # Red
					}
					buffs_changed = true
				else:
					active_buffs["rampage"].timer = AbilityManager.rampage_timer
					active_buffs["rampage"].description = "+" + str(AbilityManager.rampage_stacks * 3) + "% DMG"
			elif active_buffs.has("rampage"):
				active_buffs.erase("rampage")
				buffs_changed = true

		# Killing Frenzy - kill streak attack speed bonus
		if AbilityManager.has_killing_frenzy:
			if AbilityManager.killing_frenzy_stacks > 0:
				if not active_buffs.has("killing_frenzy"):
					active_buffs["killing_frenzy"] = {
						"timer": AbilityManager.killing_frenzy_timer, "duration": AbilityManager.KILLING_FRENZY_DECAY_TIME,
						"name": "Frenzy",
						"description": "+" + str(AbilityManager.killing_frenzy_stacks * 5) + "% SPD",
						"color": Color(1.0, 0.7, 0.2)  # Orange
					}
					buffs_changed = true
				else:
					active_buffs["killing_frenzy"].timer = AbilityManager.killing_frenzy_timer
					active_buffs["killing_frenzy"].description = "+" + str(AbilityManager.killing_frenzy_stacks * 5) + "% SPD"
			elif active_buffs.has("killing_frenzy"):
				active_buffs.erase("killing_frenzy")
				buffs_changed = true

		# Massacre - kill streak damage + speed bonus
		if AbilityManager.has_massacre:
			if AbilityManager.massacre_stacks > 0:
				if not active_buffs.has("massacre"):
					active_buffs["massacre"] = {
						"timer": AbilityManager.massacre_timer, "duration": AbilityManager.MASSACRE_DECAY_TIME,
						"name": "Massacre",
						"description": "+" + str(AbilityManager.massacre_stacks * 2) + "% ALL",
						"color": Color(0.8, 0.2, 0.8)  # Purple
					}
					buffs_changed = true
				else:
					active_buffs["massacre"].timer = AbilityManager.massacre_timer
					active_buffs["massacre"].description = "+" + str(AbilityManager.massacre_stacks * 2) + "% ALL"
			elif active_buffs.has("massacre"):
				active_buffs.erase("massacre")
				buffs_changed = true

	if buffs_changed:
		emit_signal("buff_changed", active_buffs)

	var direction := Vector2.ZERO

	# Joystick input for mobile
	if joystick_direction.length() > 0:
		direction = joystick_direction

	# Keyboard input for testing (Arrow keys + WASD)
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1

	if direction.length() > 0:
		direction = direction.normalized()

	# Apply speed with ability modifiers and temp boosts
	var effective_speed = speed * (1.0 + temp_speed_boost)
	velocity = direction * effective_speed
	move_and_slide()

	# Keep player within arena bounds (1536x1382)
	const ARENA_WIDTH = 1536
	const ARENA_HEIGHT = 1382
	const MARGIN = 40
	position.x = clamp(position.x, MARGIN, ARENA_WIDTH - MARGIN)
	position.y = clamp(position.y, MARGIN, ARENA_HEIGHT - MARGIN)

	# Auto-attack (apply temp attack speed boost)
	attack_timer += delta
	var effective_cooldown = attack_cooldown / (1.0 + temp_attack_speed_boost)
	if attack_timer >= effective_cooldown:
		try_attack()

	# Apply recoil to actual position
	if recoil_offset.length() > 0.1:
		position += recoil_offset * delta * 60  # Apply as movement
		recoil_offset = recoil_offset.lerp(Vector2.ZERO, recoil_recovery * delta)

	# Update animation
	update_animation(delta, direction)

	# Update active ability timers
	_update_active_ability_timers(delta)

func try_attack() -> void:
	var closest_enemy = find_closest_enemy()
	if closest_enemy:
		attack_timer = 0.0
		is_attacking = true
		animation_frame = 0.0  # Reset animation frame to ensure attack animation plays from start
		attack_direction = (closest_enemy.global_position - global_position).normalized()

		# Update facing direction
		if attack_direction.x != 0:
			facing_right = attack_direction.x > 0
			sprite.flip_h = not facing_right

		if is_melee:
			# Melee attack
			perform_melee_attack()
		else:
			# Ranged attack - spawn arrow
			spawn_arrow()

func find_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = fire_range  # Only consider enemies within fire range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	return closest

func spawn_arrow() -> void:
	if arrow_scene == null:
		return

	# Play arrow sound
	if SoundManager:
		SoundManager.play_arrow()

	# Muzzle flash
	spawn_muzzle_flash()

	# Recoil - push player back slightly
	recoil_offset = -attack_direction * 1.0

	# Get ability modifiers (includes permanent upgrades)
	var extra_projectiles: int = 0
	var spread_angle: float = 0.0
	var has_rear_shot: bool = false

	if AbilityManager:
		extra_projectiles = AbilityManager.get_total_projectile_count()
		spread_angle = AbilityManager.stat_modifiers.get("projectile_spread", 0.0)
		has_rear_shot = AbilityManager.has_rear_shot

	var total_projectiles = 1 + extra_projectiles

	# Calculate spread for multiple projectiles
	if total_projectiles > 1:
		var base_spread = spread_angle if spread_angle > 0 else 0.2  # Default small spread
		var start_angle = -base_spread * (total_projectiles - 1) / 2.0

		for i in total_projectiles:
			var angle_offset = start_angle + i * base_spread
			var dir = attack_direction.rotated(angle_offset)
			spawn_single_arrow(dir)
	else:
		spawn_single_arrow(attack_direction)

	# Rear shot ability
	if has_rear_shot:
		spawn_single_arrow(-attack_direction)

func spawn_muzzle_flash() -> void:
	if muzzle_flash_scene == null:
		return

	var flash = muzzle_flash_scene.instantiate()
	flash.global_position = global_position + attack_direction * 20
	get_parent().add_child(flash)

func spawn_swipe_effect() -> void:
	if swipe_effect_scene == null:
		return

	var swipe = swipe_effect_scene.instantiate()
	swipe.global_position = global_position
	swipe.direction = attack_direction
	# Set arc radius based on melee range
	var melee_reach = fire_range
	if AbilityManager:
		melee_reach *= AbilityManager.get_melee_range_multiplier()
	swipe.arc_radius = melee_reach
	# Set arc angle based on melee area
	var melee_arc = PI / 2  # Base 90 degrees
	if AbilityManager:
		melee_arc *= AbilityManager.get_melee_area_multiplier()
	swipe.arc_angle = melee_arc
	# Apply elemental tint
	var elemental_tint = get_elemental_tint()
	if elemental_tint != Color.WHITE:
		swipe.tint_color = elemental_tint
	get_parent().add_child(swipe)

func spawn_blade_beam() -> void:
	# Create a blade beam projectile (energy wave from melee swing)
	if arrow_scene == null:
		return

	var beam = arrow_scene.instantiate()
	beam.global_position = global_position + attack_direction * 30  # Start slightly in front
	beam.direction = attack_direction

	# Blade beam properties - travels further and does good damage
	beam.speed_multiplier = 1.2  # Slightly faster than normal arrows
	beam.damage_multiplier = 1.0
	if AbilityManager:
		beam.damage_multiplier = AbilityManager.get_damage_multiplier()
	beam.pierce_count = 2  # Pierce through a couple enemies

	# Visual distinction - tint the projectile (blend with elemental tint if present)
	var elemental_tint = get_elemental_tint()
	if elemental_tint != Color.WHITE:
		beam.modulate = Color(0.7, 0.9, 1.0, 0.9).lerp(elemental_tint, 0.5)
	else:
		beam.modulate = Color(0.7, 0.9, 1.0, 0.9)  # Light blue tint

	get_parent().add_child(beam)

	# Play a sound effect
	if SoundManager and SoundManager.has_method("play_arrow"):
		SoundManager.play_arrow()

func spawn_single_arrow(direction: Vector2) -> void:
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position
	arrow.direction = direction

	# Pass ability info to arrow (includes permanent upgrades)
	if AbilityManager:
		arrow.pierce_count = AbilityManager.stat_modifiers.get("projectile_pierce", 0)
		arrow.can_bounce = AbilityManager.has_rubber_walls
		arrow.has_sniper = AbilityManager.has_sniper_damage
		arrow.sniper_bonus = AbilityManager.sniper_bonus
		arrow.damage_multiplier = AbilityManager.get_damage_multiplier()
		arrow.crit_chance = AbilityManager.get_crit_chance()
		arrow.crit_multiplier = AbilityManager.get_crit_damage_multiplier()
		arrow.has_knockback = AbilityManager.has_knockback
		arrow.knockback_force = AbilityManager.knockback_force
		arrow.speed_multiplier = AbilityManager.get_projectile_speed_multiplier()

	# Apply elemental tint
	var elemental_tint = get_elemental_tint()
	if elemental_tint != Color.WHITE:
		arrow.modulate = elemental_tint

	get_parent().add_child(arrow)

func snap_to_8_directions(dir: Vector2) -> Vector2:
	# Snap direction to nearest of 8 cardinal/diagonal directions
	var angle = dir.angle()
	# Round to nearest 45 degrees (PI/4)
	var snapped_angle = round(angle / (PI / 4)) * (PI / 4)
	return Vector2(cos(snapped_angle), sin(snapped_angle))

func perform_melee_attack() -> void:
	# Reset hit tracking for this attack
	melee_hit_enemies.clear()
	melee_hitbox_active = true

	# Snap attack direction to 8 directions for cleaner arc attacks
	attack_direction = snap_to_8_directions(attack_direction)

	# Play swing sound
	if SoundManager:
		SoundManager.play_swing()

	# Spawn swipe effect for melee attacks
	spawn_swipe_effect()

	# Blade Beam - fire a projectile on melee swing
	if AbilityManager and AbilityManager.should_fire_blade_beam():
		spawn_blade_beam()

	# Recoil - push player back slightly for melee (only when not moving)
	if velocity.length() < 5.0:
		recoil_offset = -attack_direction * 1.0

	# Calculate melee damage
	var melee_damage = 10.0 * base_damage  # Base melee damage

	# Apply ability modifiers
	if AbilityManager:
		melee_damage *= AbilityManager.get_damage_multiplier()

	# Get enemies in melee range with arc check
	var enemies = get_tree().get_nodes_in_group("enemies")

	# Base melee arc (90 degrees), modified by melee_area ability
	var melee_arc = PI / 2
	if AbilityManager:
		melee_arc *= AbilityManager.get_melee_area_multiplier()

	# Melee range, modified by melee_range ability
	var melee_reach = fire_range
	if AbilityManager:
		melee_reach *= AbilityManager.get_melee_range_multiplier()

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy not in melee_hit_enemies:
			var to_enemy = enemy.global_position - global_position
			var dist = to_enemy.length()

			if dist <= melee_reach:
				# Check if enemy is within attack arc
				var angle_to_enemy = to_enemy.angle()
				var attack_angle = attack_direction.angle()
				var angle_diff = abs(angle_to_enemy - attack_angle)

				# Normalize angle difference
				if angle_diff > PI:
					angle_diff = TAU - angle_diff

				if angle_diff <= melee_arc / 2:
					# Hit this enemy
					melee_hit_enemies.append(enemy)

					# Calculate final damage
					var final_damage = melee_damage
					var is_crit = false

					# Crit check
					if AbilityManager:
						var crit_chance = AbilityManager.get_crit_chance()
						if randf() < crit_chance:
							is_crit = true
							final_damage *= AbilityManager.get_crit_damage_multiplier()
							# Tiny screen shake on crit
							if JuiceManager:
								JuiceManager.shake_crit()

					# Apply damage
					if enemy.has_method("take_damage"):
						enemy.take_damage(final_damage, is_crit)

					# Apply stagger on melee hit (0.5s stun)
					if enemy.has_method("apply_stagger"):
						enemy.apply_stagger()

					# Knockback
					if AbilityManager and AbilityManager.has_knockback:
						if enemy.has_method("apply_knockback"):
							enemy.apply_knockback(to_enemy.normalized() * AbilityManager.knockback_force)

					# Apply elemental effects
					_apply_elemental_effects_to_enemy(enemy)

	# Slight screen shake on melee hit
	if melee_hit_enemies.size() > 0 and JuiceManager:
		JuiceManager.shake_small()

func _apply_elemental_effects_to_enemy(enemy: Node2D) -> void:
	"""Apply elemental on-hit effects to an enemy."""
	if not AbilityManager:
		return

	# Ignite - apply burn damage
	if AbilityManager.check_ignite():
		if enemy.has_method("apply_burn"):
			enemy.apply_burn(3.0)
		_spawn_elemental_text(enemy, "BURN", Color(1.0, 0.4, 0.2))

	# Frostbite - apply chill (slow)
	if AbilityManager.check_frostbite():
		if enemy.has_method("apply_slow"):
			enemy.apply_slow(0.5, 2.0)
		_spawn_elemental_text(enemy, "CHILL", Color(0.4, 0.7, 1.0))

	# Toxic Tip - apply poison
	if AbilityManager.check_toxic_tip():
		if enemy.has_method("apply_poison"):
			enemy.apply_poison(50.0, 5.0)
		_spawn_elemental_text(enemy, "POISON", Color(0.4, 1.0, 0.4))

	# Lightning Proc - trigger lightning
	if AbilityManager.check_lightning_proc():
		AbilityManager.trigger_lightning_at(enemy.global_position)
		_spawn_elemental_text(enemy, "ZAP", Color(1.0, 0.9, 0.4))

func _spawn_elemental_text(enemy: Node2D, text: String, color: Color) -> void:
	"""Spawn a colored elemental damage number."""
	if damage_number_scene:
		var dmg_num = damage_number_scene.instantiate()
		dmg_num.global_position = enemy.global_position + Vector2(randf_range(-15, 15), -30)
		get_parent().add_child(dmg_num)
		if dmg_num.has_method("set_elemental"):
			dmg_num.set_elemental(text, color)

func update_animation(delta: float, move_direction: Vector2) -> void:
	var prev_row = current_row
	var target_row: int

	if is_attacking:
		if is_melee:
			# Melee uses single attack animation
			target_row = row_attack
		else:
			# Ranged - choose shoot animation based on attack direction
			var angle = attack_direction.angle()
			if angle > -PI/4 and angle < PI/4:
				# Shooting right (straight)
				target_row = row_attack
			elif angle >= PI/4 and angle <= 3*PI/4:
				# Shooting down
				target_row = row_attack_down
			elif angle <= -PI/4 and angle >= -3*PI/4:
				# Shooting up
				target_row = row_attack_up
			else:
				# Shooting left (straight, sprite flipped)
				target_row = row_attack

		# Check if attack animation finished
		if animation_frame >= frame_counts.get(target_row, 8) - 1:
			is_attacking = false
			melee_hitbox_active = false
	elif move_direction.length() > 0:
		target_row = row_move
		# Update facing based on movement when not attacking
		if move_direction.x != 0:
			facing_right = move_direction.x > 0
			sprite.flip_h = not facing_right
	else:
		target_row = row_idle

	current_row = target_row

	# Reset frame when animation changes
	if prev_row != current_row:
		animation_frame = 0.0

	# Advance animation frame
	animation_frame += animation_speed * delta
	var max_frames = frame_counts.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0
		if is_attacking:
			is_attacking = false
			melee_hitbox_active = false

	# Set the sprite frame
	sprite.frame = current_row * cols_per_row + int(animation_frame)

func update_death_animation(delta: float) -> void:
	# Play death animation once, then hold on last frame
	if death_animation_finished:
		return

	current_row = row_death
	animation_frame += animation_speed * delta

	var max_frames = frame_counts.get(row_death, 4)
	if animation_frame >= max_frames - 1:
		animation_frame = max_frames - 1
		death_animation_finished = true

	# Set the sprite frame
	sprite.frame = current_row * cols_per_row + int(animation_frame)

func add_xp(amount: float) -> void:
	# Apply XP multiplier from abilities
	var xp_multiplier = 1.0
	if AbilityManager:
		xp_multiplier = AbilityManager.get_xp_multiplier()
		# Check for double XP
		if AbilityManager.should_double_xp():
			xp_multiplier *= 2.0

	var final_amount = amount * xp_multiplier
	current_xp += final_amount
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		xp_to_next_level *= 1.5
		# Play level up sound
		if SoundManager:
			SoundManager.play_levelup()
		# Haptic feedback on level up
		if HapticManager:
			HapticManager.level_up()
		emit_signal("level_up", current_level)
		emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

func give_kill_xp(enemy_max_hp: float = 100.0) -> void:
	# XP based on enemy HP: 10-30 scaled by HP (100 HP = base, higher HP = more XP)
	var hp_factor = clamp(enemy_max_hp / 100.0, 0.5, 3.0)
	var xp_gain = randf_range(10.0, 30.0) * hp_factor
	add_xp(xp_gain)

# Ability system helper functions
func heal(amount: float, _play_sound: bool = true) -> void:
	var actual_heal = min(amount, max_health - current_health)
	if actual_heal <= 0:
		return  # Already at full health

	current_health += actual_heal
	if health_bar:
		health_bar.set_health(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)

	# Update low HP vignette
	if JuiceManager:
		JuiceManager.update_player_health(current_health / max_health)

	# Accumulate heal for display - only show when >= 1
	accumulated_heal += actual_heal
	if accumulated_heal >= 1.0:
		var display_amount = floor(accumulated_heal)
		spawn_heal_number(display_amount)
		accumulated_heal -= display_amount

func revive_with_percent(hp_percent: float) -> void:
	"""Revive player with a percentage of max health (phoenix ability)."""
	current_health = max_health * hp_percent
	is_dead = false
	death_animation_finished = false
	animation_frame = 0.0
	current_row = row_idle

	if health_bar:
		health_bar.set_health(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)

	# Visual feedback
	if JuiceManager:
		JuiceManager.update_player_health(current_health / max_health)
		JuiceManager.shake_large()

	# Brief invulnerability after revive
	set_invulnerable(true, 1.5)

func spawn_heal_number(amount: float) -> void:
	if damage_number_scene == null:
		return

	var heal_num = damage_number_scene.instantiate()
	heal_num.global_position = global_position + Vector2(0, -40)
	get_parent().add_child(heal_num)
	heal_num.set_heal(amount)

func apply_temporary_speed_boost(boost: float, duration: float) -> void:
	temp_speed_boost = boost
	temp_speed_timer = duration
	active_buffs["speed_boost"] = {
		"timer": duration,
		"duration": duration,
		"name": "Adrenaline",
		"description": "+" + str(int(boost * 100)) + "% Move Speed",
		"color": Color(0.2, 0.8, 0.2)  # Green
	}
	emit_signal("buff_changed", active_buffs)

func apply_temporary_attack_speed_boost(boost: float, duration: float) -> void:
	temp_attack_speed_boost = boost
	temp_attack_speed_timer = duration
	active_buffs["attack_speed_boost"] = {
		"timer": duration,
		"duration": duration,
		"name": "Bloodthirst",
		"description": "+" + str(int(boost * 100)) + "% Attack Speed",
		"color": Color(0.8, 0.2, 0.2)  # Red
	}
	emit_signal("buff_changed", active_buffs)

func update_ability_stats(modifiers: Dictionary) -> void:
	# Update speed
	var speed_mult = 1.0 + modifiers.get("move_speed", 0.0)
	speed = base_speed * speed_mult

	# Update attack cooldown (attack speed is inverse)
	var attack_speed_mult = 1.0 + modifiers.get("attack_speed", 0.0)
	# Check for frenzy
	if AbilityManager and AbilityManager.has_frenzy:
		if current_health / max_health < 0.3:
			attack_speed_mult += AbilityManager.frenzy_boost
	attack_cooldown = base_attack_cooldown / attack_speed_mult

	# Update max HP (add flat amount)
	var hp_change = modifiers.get("max_hp", 0.0)
	var old_max = max_health
	var new_max = base_max_health + hp_change

	# When max HP increases, add the bonus to current health too
	# (so 10/25 + 50 max HP = 60/75, not 30/75)
	if new_max != old_max:
		var hp_difference = new_max - old_max
		max_health = new_max
		# Add the HP difference to current health (but cap at new max)
		current_health = min(current_health + hp_difference, max_health)
		if health_bar:
			health_bar.set_health(current_health, max_health)
		emit_signal("health_changed", current_health, max_health)
		# Update low HP vignette
		if JuiceManager:
			JuiceManager.update_player_health(current_health / max_health)

	# Update pickup range
	pickup_range_multiplier = 1.0 + modifiers.get("pickup_range", 0.0)

	# Update size
	var new_size = 1.0 + modifiers.get("size", 0.0)
	if new_size != size_scale:
		size_scale = new_size
		scale = Vector2(size_scale, size_scale)

func get_pickup_range() -> float:
	return 80.0 * pickup_range_multiplier  # Base pickup range * multiplier

# ============================================
# ACTIVE ABILITY HELPER FUNCTIONS
# ============================================

# Invulnerability state
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0

# Damage boost state
var damage_boost_multiplier: float = 1.0
var damage_boost_timer: float = 0.0

func set_invulnerable(invulnerable: bool, duration: float = 0.0) -> void:
	"""Set the player's invulnerability state."""
	is_invulnerable = invulnerable
	if invulnerable:
		# Visual feedback - make player slightly transparent
		modulate.a = 0.6
		if duration > 0:
			invulnerability_timer = duration
			active_buffs["invulnerable"] = {
				"timer": duration,
				"duration": duration,
				"name": "Shield",
				"description": "Invulnerable",
				"color": Color(0.4, 0.8, 1.0)  # Cyan
			}
			emit_signal("buff_changed", active_buffs)
	else:
		modulate.a = 1.0
		if active_buffs.has("invulnerable"):
			active_buffs.erase("invulnerable")
			emit_signal("buff_changed", active_buffs)

func get_attack_direction() -> Vector2:
	"""Get the current attack/facing direction."""
	return attack_direction

func get_facing_direction() -> Vector2:
	"""Get the direction the player is facing."""
	return Vector2.RIGHT if facing_right else Vector2.LEFT

func apply_damage_boost(multiplier: float, duration: float) -> void:
	"""Apply a temporary damage boost."""
	damage_boost_multiplier = multiplier
	damage_boost_timer = duration
	var boost_percent = int((multiplier - 1.0) * 100)
	active_buffs["damage_boost"] = {
		"timer": duration,
		"duration": duration,
		"name": "Battle Cry",
		"description": "+" + str(boost_percent) + "% Damage",
		"color": Color(1.0, 0.8, 0.2)  # Gold/Yellow
	}
	emit_signal("buff_changed", active_buffs)

func get_damage_boost() -> float:
	"""Get the current damage boost multiplier."""
	return damage_boost_multiplier if damage_boost_timer > 0 else 1.0

func get_elemental_tint() -> Color:
	"""Get tint color based on active elemental effects."""
	if not AbilityManager:
		return Color.WHITE

	var colors: Array[Color] = []

	# Check each elemental effect and add its color
	if AbilityManager.has_ignite:
		colors.append(Color(1.0, 0.4, 0.2))  # Fire - Orange/Red
	if AbilityManager.has_frostbite:
		colors.append(Color(0.4, 0.7, 1.0))  # Ice - Blue/Cyan
	if AbilityManager.has_toxic_tip:
		colors.append(Color(0.4, 1.0, 0.4))  # Poison - Green
	if AbilityManager.has_lightning_proc:
		colors.append(Color(1.0, 0.9, 0.4))  # Lightning - Yellow

	if colors.is_empty():
		return Color.WHITE

	# Blend all active elemental colors
	var blended = colors[0]
	for i in range(1, colors.size()):
		blended = blended.lerp(colors[i], 0.5)

	# Make tint subtle by lerping toward white
	return Color.WHITE.lerp(blended, 0.6)

func spawn_dodge_effect() -> void:
	"""Spawn a visual effect for dodging."""
	# Spawn dash smoke effect using the new sprite animation
	_spawn_dash_smoke()

	# Create afterimage effect
	if sprite:
		var afterimage = Sprite2D.new()
		afterimage.texture = sprite.texture
		afterimage.hframes = sprite.hframes
		afterimage.vframes = sprite.vframes
		afterimage.frame = sprite.frame
		afterimage.flip_h = sprite.flip_h
		afterimage.global_position = global_position
		afterimage.scale = scale
		afterimage.modulate = Color(0.4, 0.8, 1.0, 0.6)  # Cyan tint
		get_parent().add_child(afterimage)

		# Fade out and remove
		var tween = afterimage.create_tween()
		tween.tween_property(afterimage, "modulate:a", 0.0, 0.3)
		tween.tween_callback(afterimage.queue_free)

func _spawn_dash_smoke() -> void:
	"""Spawn the dash smoke sprite effect."""
	var smoke_scene = load("res://scenes/effects/ability_effects/dash_smoke.tscn")
	if smoke_scene:
		var smoke = smoke_scene.instantiate()
		smoke.global_position = global_position
		# Set direction based on movement or facing
		var dir = velocity.normalized() if velocity.length() > 10 else (Vector2.RIGHT if facing_right else Vector2.LEFT)
		if smoke.has_method("set_direction"):
			smoke.set_direction(dir)
		get_parent().add_child(smoke)

func dash_toward(target_pos: Vector2) -> void:
	"""Dash toward a target position (used by Adrenaline Rush)."""
	var direction = (target_pos - global_position).normalized()
	var dash_distance = 80.0

	# Move player toward target
	global_position += direction * dash_distance

	# Update facing direction
	if direction.x > 0:
		facing_right = true
	elif direction.x < 0:
		facing_right = false

	# Spawn visual effect
	_spawn_dash_smoke()

	# Play sound
	if SoundManager:
		SoundManager.play_dash()

func _update_active_ability_timers(delta: float) -> void:
	"""Update timers for active ability effects."""
	# Update invulnerability timer
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		if active_buffs.has("invulnerable"):
			active_buffs["invulnerable"].timer = invulnerability_timer
		if invulnerability_timer <= 0:
			set_invulnerable(false)

	# Update damage boost timer
	if damage_boost_timer > 0:
		damage_boost_timer -= delta
		if active_buffs.has("damage_boost"):
			active_buffs["damage_boost"].timer = damage_boost_timer
		if damage_boost_timer <= 0:
			damage_boost_multiplier = 1.0
			if active_buffs.has("damage_boost"):
				active_buffs.erase("damage_boost")
				emit_signal("buff_changed", active_buffs)
