extends CharacterBody2D

@export var speed: float = 116.64  # 180 * 0.72 * 0.9 (10% slower)
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

# Toxic Traits trail spawning
var toxic_trail_timer: float = 0.0
const TOXIC_TRAIL_INTERVAL: float = 0.4  # Spawn pool every 0.4 seconds while moving

# Active buffs tracking for UI {buff_id: {timer: float, duration: float, name: String, description: String, color: Color}}
var active_buffs: Dictionary = {}
signal buff_changed(buffs: Dictionary)

# Heal accumulator (for small heals that would round to 0)
var accumulated_heal: float = 0.0

# Joystick input (replaces direct touch)
var joystick: Control = null
var joystick_direction: Vector2 = Vector2.ZERO

# Dynamic arena bounds (set by procedural map generator)
var arena_bounds: Rect2 = Rect2(0, 0, 2500, 2500)
var arena_margin: float = 40.0

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

# Beast-specific animation rows
var row_attack_alt: int = -1  # Alternate attack (randomly chosen)
var has_alt_attack: bool = false
var current_attack_row: int = 2  # Which attack row to use this attack

# Monk-specific triple attack system
var row_attack_2: int = -1  # Second attack animation
var row_attack_3: int = -1  # Third attack animation
var has_triple_attack: bool = false
var monk_attack_cycle: int = 0  # Cycles through 0, 1, 2 for attack variety

# Monk Flow system (Flowing Strikes passive)
var has_flow: bool = false
var flow_stacks: int = 0
var flow_max_stacks: int = 5
var flow_timer: float = 0.0
var flow_decay_time: float = 1.5
var flow_damage_per_stack: float = 0.08
var flow_speed_per_stack: float = 0.05
var flow_dash_threshold: int = 3

# Mage Arcane Focus system
var has_arcane_focus: bool = false
var arcane_focus_stacks: float = 0.0  # Float for smooth buildup/decay
var arcane_focus_max_stacks: int = 5
var arcane_focus_per_stack: float = 0.10  # +10% per stack
var arcane_focus_decay_time: float = 5.0  # Decay over 5s

# Ranger Heartseeker system (consecutive hits on same target)
var has_heartseeker: bool = false
var heartseeker_stacks: int = 0
var heartseeker_max_stacks: int = 5
var heartseeker_damage_per_stack: float = 0.10
var heartseeker_last_target: Node2D = null

# Knight Retribution system (damage boost after taking damage)
var has_retribution: bool = false
var retribution_ready: bool = false
var retribution_timer: float = 0.0
var retribution_duration: float = 2.0
var retribution_damage_bonus: float = 0.50
var retribution_stun_duration: float = 0.5

# Barbarian Berserker Rage system (10% chance for AOE spin attack)
var has_berserker_rage: bool = false
var row_spin_attack: int = -1
var frames_spin_attack: int = 8
var berserker_rage_chance: float = 0.10
var berserker_rage_aoe_radius: float = 120.0
var berserker_rage_damage_multiplier: float = 2.0
var is_spin_attacking: bool = false  # Track if currently doing spin attack

# Assassin Shadow Dance system
var has_shadow_dance: bool = false
var is_hybrid_attacker: bool = false
var assassin_melee_range: float = 70.0
var row_melee_attack: int = -1
var row_disappear: int = -1
var frames_melee_attack: int = 8
var frames_disappear: int = 8
var shadow_dance_hit_count: int = 0
var shadow_dance_hits_required: int = 5
var shadow_dance_duration: float = 1.5
var shadow_dance_damage_bonus: float = 1.0
var is_stealthed: bool = false
var stealth_timer: float = 0.0
var is_playing_disappear: bool = false  # Track if playing vanish animation

# Mage-specific death animation
var death_frame_skip: int = 1  # Skip N frames (1 = every frame, 2 = every other)
var death_spans_rows: bool = false  # Death animation spans multiple rows
var death_row_2: int = -1  # Second row for death if spans rows
var frames_death_row_2: int = 0  # Frames in second death row

var cols_per_row: int = 8

var frame_counts: Dictionary = {}

var current_row: int = 0
var animation_frame: float = 0.0
@onready var sprite: Sprite2D = $Sprite

# Sprite offset (for off-center sprites like beast)
var base_sprite_offset: Vector2 = Vector2.ZERO

# Combat
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT
var facing_right: bool = true

# Melee attack hitbox
var melee_hitbox_active: bool = false
var melee_hit_enemies: Array = []  # Track enemies hit this attack

# Bladestorm animation state
var is_bladestorming: bool = false
var bladestorm_timer: float = 0.0
var bladestorm_flip_timer: float = 0.0
const BLADESTORM_FLIP_SPEED: float = 0.15  # Flip direction every 0.15 seconds

# Death state
var is_dead: bool = false
var death_animation_finished: bool = false

# Target indicator (shows nearest enemy)
var target_indicator: Node2D = null
var target_indicator_pulse: float = 0.0
var current_target: Node2D = null

# XP System
const MAX_LEVEL: int = 20
var current_xp: float = 0.0
var xp_to_next_level: float = 526.24  # Base XP required (10% increase from 478.4)
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

	# Create target indicator
	_create_target_indicator()

func _create_target_indicator() -> void:
	target_indicator = Node2D.new()
	target_indicator.z_index = -10  # Well below enemies

	# Create 4 corner brackets using Line2D with pixelated curved corners
	var bracket_size: float = 14.0
	var bracket_length: float = 7.0
	var bracket_color: Color = Color(1.0, 0.2, 0.2, 0.9)  # Red
	var line_width: float = 4.0
	var corner_step: float = 2.0  # Pixel step for curved corner effect

	# Top-left bracket: vertical down, diagonal, then horizontal right
	var tl = Line2D.new()
	tl.width = line_width
	tl.default_color = bracket_color
	tl.points = [
		Vector2(-bracket_size, -bracket_size + bracket_length),
		Vector2(-bracket_size, -bracket_size + corner_step),
		Vector2(-bracket_size + corner_step, -bracket_size),
		Vector2(-bracket_size + bracket_length, -bracket_size)
	]
	target_indicator.add_child(tl)

	# Top-right bracket: horizontal left, diagonal, then vertical down
	var tr = Line2D.new()
	tr.width = line_width
	tr.default_color = bracket_color
	tr.points = [
		Vector2(bracket_size - bracket_length, -bracket_size),
		Vector2(bracket_size - corner_step, -bracket_size),
		Vector2(bracket_size, -bracket_size + corner_step),
		Vector2(bracket_size, -bracket_size + bracket_length)
	]
	target_indicator.add_child(tr)

	# Bottom-left bracket: vertical up, diagonal, then horizontal right
	var bl = Line2D.new()
	bl.width = line_width
	bl.default_color = bracket_color
	bl.points = [
		Vector2(-bracket_size, bracket_size - bracket_length),
		Vector2(-bracket_size, bracket_size - corner_step),
		Vector2(-bracket_size + corner_step, bracket_size),
		Vector2(-bracket_size + bracket_length, bracket_size)
	]
	target_indicator.add_child(bl)

	# Bottom-right bracket: horizontal left, diagonal, then vertical up
	var br = Line2D.new()
	br.width = line_width
	br.default_color = bracket_color
	br.points = [
		Vector2(bracket_size - bracket_length, bracket_size),
		Vector2(bracket_size - corner_step, bracket_size),
		Vector2(bracket_size, bracket_size - corner_step),
		Vector2(bracket_size, bracket_size - bracket_length)
	]
	target_indicator.add_child(br)

	target_indicator.visible = false
	get_parent().call_deferred("add_child", target_indicator)

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
		base_sprite_offset = character_data.sprite_offset
		sprite.offset = base_sprite_offset

	# Setup animation rows
	row_idle = character_data.row_idle
	row_move = character_data.row_move
	row_attack = character_data.row_attack
	row_attack_up = character_data.row_attack_up
	row_attack_down = character_data.row_attack_down
	row_damage = character_data.row_damage
	row_death = character_data.row_death
	cols_per_row = character_data.hframes

	# Beast-specific animations
	row_attack_alt = character_data.row_attack_alt
	has_alt_attack = character_data.has_alt_attack
	current_attack_row = row_attack

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

	# Add alternate attack frames if available
	if has_alt_attack and row_attack_alt >= 0:
		frame_counts[row_attack_alt] = character_data.frames_attack_alt

	# Monk-specific triple attack animations
	row_attack_2 = character_data.row_attack_2
	row_attack_3 = character_data.row_attack_3
	has_triple_attack = character_data.has_triple_attack
	if has_triple_attack:
		if row_attack_2 >= 0:
			frame_counts[row_attack_2] = character_data.frames_attack_2
		if row_attack_3 >= 0:
			frame_counts[row_attack_3] = character_data.frames_attack_3

	# Mage-specific death animation properties
	death_frame_skip = character_data.death_frame_skip
	death_spans_rows = character_data.death_spans_rows
	death_row_2 = character_data.death_row_2
	frames_death_row_2 = character_data.frames_death_row_2

	# Barbarian-specific spin attack animation
	row_spin_attack = character_data.row_spin_attack
	frames_spin_attack = character_data.frames_spin_attack
	has_berserker_rage = character_data.has_berserker_rage
	if has_berserker_rage and row_spin_attack >= 0:
		frame_counts[row_spin_attack] = frames_spin_attack

	# Assassin-specific hybrid attack and shadow dance
	row_melee_attack = character_data.row_melee_attack
	row_disappear = character_data.row_disappear
	frames_melee_attack = character_data.frames_melee_attack
	frames_disappear = character_data.frames_disappear
	is_hybrid_attacker = character_data.is_hybrid_attacker
	assassin_melee_range = character_data.melee_range
	has_shadow_dance = character_data.has_shadow_dance
	if is_hybrid_attacker:
		if row_melee_attack >= 0:
			frame_counts[row_melee_attack] = frames_melee_attack
		if row_disappear >= 0:
			frame_counts[row_disappear] = frames_disappear

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

	# Apply max HP bonus from passive (Knight)
	var hp_bonus = bonuses.get("max_hp", 0.0)
	if hp_bonus > 0:
		base_max_health = base_max_health * (1.0 + hp_bonus)
		max_health = base_max_health

	# Apply attack speed bonus from passive (Beast)
	var attack_speed_bonus = bonuses.get("attack_speed", 0.0)
	if attack_speed_bonus > 0:
		base_attack_cooldown = base_attack_cooldown / (1.0 + attack_speed_bonus)
		attack_cooldown = base_attack_cooldown

	# Initialize Monk Flow system
	has_flow = bonuses.get("has_flow", 0.0) > 0.0
	if has_flow:
		flow_damage_per_stack = bonuses.get("flow_damage_per_stack", 0.08)
		flow_speed_per_stack = bonuses.get("flow_speed_per_stack", 0.05)
		flow_dash_threshold = int(bonuses.get("flow_dash_threshold", 3))
		flow_max_stacks = int(bonuses.get("flow_max_stacks", 5))
		flow_decay_time = bonuses.get("flow_decay_time", 1.5)
		flow_stacks = 0
		flow_timer = 0.0

	# Initialize Mage Arcane Focus system
	has_arcane_focus = bonuses.get("has_arcane_focus", 0.0) > 0.0
	if has_arcane_focus:
		arcane_focus_per_stack = bonuses.get("arcane_focus_per_stack", 0.10)
		arcane_focus_max_stacks = int(bonuses.get("arcane_focus_max_stacks", 5))
		arcane_focus_decay_time = bonuses.get("arcane_focus_decay_time", 5.0)
		arcane_focus_stacks = 0.0

	# Initialize Ranger Heartseeker system
	has_heartseeker = bonuses.get("has_heartseeker", 0.0) > 0.0
	if has_heartseeker:
		heartseeker_damage_per_stack = bonuses.get("heartseeker_damage_per_stack", 0.10)
		heartseeker_max_stacks = int(bonuses.get("heartseeker_max_stacks", 5))
		heartseeker_stacks = 0
		heartseeker_last_target = null

	# Initialize Knight Retribution system
	has_retribution = bonuses.get("has_retribution", 0.0) > 0.0
	if has_retribution:
		retribution_damage_bonus = bonuses.get("retribution_damage_bonus", 0.50)
		retribution_duration = bonuses.get("retribution_duration", 2.0)
		retribution_stun_duration = bonuses.get("retribution_stun_duration", 0.5)
		retribution_ready = false
		retribution_timer = 0.0

	# Initialize Barbarian Berserker Rage system
	if bonuses.get("has_berserker_rage", 0.0) > 0.0:
		has_berserker_rage = true
		berserker_rage_chance = bonuses.get("berserker_rage_chance", 0.10)
		berserker_rage_aoe_radius = bonuses.get("berserker_rage_aoe_radius", 120.0)
		berserker_rage_damage_multiplier = bonuses.get("berserker_rage_damage_multiplier", 2.0)
		is_spin_attacking = false

	# Initialize Assassin Shadow Dance system
	if bonuses.get("has_shadow_dance", 0.0) > 0.0:
		has_shadow_dance = true
		shadow_dance_hits_required = int(bonuses.get("shadow_dance_hits_required", 5))
		shadow_dance_duration = bonuses.get("shadow_dance_duration", 1.5)
		shadow_dance_damage_bonus = bonuses.get("shadow_dance_damage_bonus", 1.0)
		shadow_dance_hit_count = 0
		is_stealthed = false
		stealth_timer = 0.0
	if bonuses.get("is_hybrid_attacker", 0.0) > 0.0:
		is_hybrid_attacker = true
		assassin_melee_range = bonuses.get("assassin_melee_range", 70.0)

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
	# If dead, still show damage effects (funny to keep getting beat up)
	# but don't actually reduce HP further
	var is_posthumous_damage = is_dead

	# Check for invulnerability (from dodge or abilities) - but not when dead
	if is_invulnerable and not is_posthumous_damage:
		return

	# Apply Mage Arcane Focus damage taken increase
	var modified_amount = amount
	if has_arcane_focus and arcane_focus_stacks > 0 and not is_posthumous_damage:
		modified_amount *= get_arcane_focus_multiplier()

	# Skip dodge/block/shield checks when dead - just show the damage effects
	var was_blocked = false
	var damage_after_shields = modified_amount

	if not is_posthumous_damage:
		# Check for dodge first
		if AbilityManager:
			var dodge_chance = AbilityManager.get_dodge_chance()
			if randf() < dodge_chance:
				# Dodged the attack!
				spawn_dodge_text()
				return

		# Check for block
		if AbilityManager:
			var block_chance = AbilityManager.get_block_chance()
			if randf() < block_chance:
				was_blocked = true

		# Transcendence shields absorb damage first
		if AbilityManager:
			damage_after_shields = AbilityManager.damage_transcendence_shields(modified_amount)
			if damage_after_shields <= 0:
				# All damage absorbed by shields
				spawn_shield_text()
				return

	# Calculate total damage reduction (skip when dead - just show raw damage)
	var final_damage = damage_after_shields

	if not is_posthumous_damage:
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

		# Add ultimate ability damage reduction
		total_reduction += get_damage_reduction()

		# Apply total damage reduction (cap at 90% to allow ultimates to be powerful)
		total_reduction = min(total_reduction, 0.90)
		final_damage = damage_after_shields * (1.0 - total_reduction)

		# Block reduces damage by 50%
		if was_blocked:
			final_damage *= 0.5

	# Only reduce HP if not already dead (but still show effects)
	if not is_posthumous_damage:
		current_health -= final_damage
		if health_bar:
			health_bar.set_health(current_health, max_health)
		emit_signal("health_changed", current_health, max_health)

	# Play player hurt sound (even when dead - it's funny)
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

	# Skip ability triggers when dead
	if not is_posthumous_damage:
		# Trigger Retribution explosion when taking damage (ability)
		if AbilityManager:
			AbilityManager.trigger_retribution(global_position)
			# Trigger Adrenaline Surge (reduces active ability cooldowns)
			AbilityManager.on_player_damaged()

		# Trigger Knight Retribution passive (damage boost on next attack)
		if has_retribution and not retribution_ready:
			_activate_retribution()

	# Screen shake and damage flash when taking damage (even when dead)
	if JuiceManager:
		if was_blocked:
			JuiceManager.shake_small()  # Less shake when blocked
		else:
			JuiceManager.shake_medium()
			# 1-frame freeze on player damage for impact (#14)
			JuiceManager.player_damage_freeze()
		JuiceManager.damage_flash()
		if not is_posthumous_damage:
			JuiceManager.update_player_health(current_health / max_health)

	# Death check - only if not already dead
	if current_health <= 0 and not is_dead:
		current_health = 0
		# Check for Unbreakable Will (Knight ultimate) first
		if trigger_unbreakable_will():
			return  # Death prevented by ultimate

		# Check for phoenix revive before dying
		if AbilityManager:
			print("[Phoenix Debug] has_phoenix: ", AbilityManager.has_phoenix, " phoenix_used: ", AbilityManager.phoenix_used)
			if AbilityManager.try_phoenix_revive(self):
				print("[Phoenix Debug] Phoenix triggered! Reviving...")
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

func set_arena_bounds(bounds: Rect2, camera_bounds: Rect2 = Rect2()) -> void:
	"""Set the arena boundaries and optionally update camera limits."""
	arena_bounds = bounds

	# Update camera limits if provided
	if camera_bounds.size.x > 0 and camera:
		camera.limit_left = int(camera_bounds.position.x)
		camera.limit_top = int(camera_bounds.position.y)
		camera.limit_right = int(camera_bounds.end.x)
		camera.limit_bottom = int(camera_bounds.end.y)
	elif camera:
		# Default: use arena bounds with small margin
		camera.limit_left = int(bounds.position.x - 100)
		camera.limit_top = int(bounds.position.y - 100)
		camera.limit_right = int(bounds.end.x + 100)
		camera.limit_bottom = int(bounds.end.y + 100)

func _physics_process(delta: float) -> void:
	# Update z_index based on Y position for depth sorting with trees
	z_index = int(global_position.y / 10)

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

	# Bladestorm animation - rapid left/right attacking
	if is_bladestorming:
		bladestorm_timer -= delta
		bladestorm_flip_timer += delta
		# Flip direction rapidly for frantic attack animation
		if bladestorm_flip_timer >= BLADESTORM_FLIP_SPEED:
			bladestorm_flip_timer = 0.0
			sprite.flip_h = not sprite.flip_h
			facing_right = not facing_right
		# End bladestorm when timer expires
		if bladestorm_timer <= 0:
			stop_bladestorm_animation()

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
						"description": "+" + str(AbilityManager.rampage_stacks * 3) + "% Damage",
						"color": Color(1.0, 0.3, 0.2)  # Red
					}
					buffs_changed = true
				else:
					active_buffs["rampage"].timer = AbilityManager.rampage_timer
					active_buffs["rampage"].description = "+" + str(AbilityManager.rampage_stacks * 3) + "% Damage"
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
						"description": "+" + str(AbilityManager.killing_frenzy_stacks * 5) + "% Speed",
						"color": Color(1.0, 0.7, 0.2)  # Orange
					}
					buffs_changed = true
				else:
					active_buffs["killing_frenzy"].timer = AbilityManager.killing_frenzy_timer
					active_buffs["killing_frenzy"].description = "+" + str(AbilityManager.killing_frenzy_stacks * 5) + "% Speed"
			elif active_buffs.has("killing_frenzy"):
				active_buffs.erase("killing_frenzy")
				buffs_changed = true

		# Massacre - kill streak damage + speed bonus
		if AbilityManager.has_massacre:
			if AbilityManager.massacre_stacks > 0:
				if not active_buffs.has("massacre"):
					active_buffs["massacre"] = {
						"timer": AbilityManager.massacre_timer, "duration": AbilityManager.MASSACRE_DECAY_TIME,
						"name": "Massacre x" + str(AbilityManager.massacre_stacks),
						"description": "+" + str(AbilityManager.massacre_stacks * 2) + "% All Stats",
						"color": Color(0.8, 0.2, 0.8)  # Purple
					}
					buffs_changed = true
				else:
					active_buffs["massacre"].timer = AbilityManager.massacre_timer
					active_buffs["massacre"].name = "Massacre x" + str(AbilityManager.massacre_stacks)
					active_buffs["massacre"].description = "+" + str(AbilityManager.massacre_stacks * 2) + "% All Stats"
			elif active_buffs.has("massacre"):
				active_buffs.erase("massacre")
				buffs_changed = true

		# Horde Breaker - damage bonus per nearby enemy
		if AbilityManager.has_horde_breaker:
			var nearby_count = 0
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 160.0:
					nearby_count += 1
			if nearby_count > 0:
				var bonus_pct = min(int(AbilityManager.horde_breaker_bonus * nearby_count * 100), 20)
				if not active_buffs.has("horde_breaker"):
					active_buffs["horde_breaker"] = {
						"timer": -1, "duration": -1,
						"name": "Horde x" + str(nearby_count),
						"description": "+" + str(bonus_pct) + "% Damage",
						"color": Color(0.9, 0.5, 0.2)  # Orange-red
					}
					buffs_changed = true
				else:
					var new_name = "Horde x" + str(nearby_count)
					var new_desc = "+" + str(bonus_pct) + "% Damage"
					if active_buffs["horde_breaker"].name != new_name or active_buffs["horde_breaker"].description != new_desc:
						active_buffs["horde_breaker"].name = new_name
						active_buffs["horde_breaker"].description = new_desc
						buffs_changed = true
			elif active_buffs.has("horde_breaker"):
				active_buffs.erase("horde_breaker")
				buffs_changed = true

		# Combo Master - damage boost after using active ability or dodge
		if AbilityManager.has_combo_master:
			if AbilityManager.combo_master_active and AbilityManager.combo_master_timer > 0:
				var bonus_percent = int(AbilityManager.combo_master_bonus * 100)
				if not active_buffs.has("combo_master"):
					active_buffs["combo_master"] = {
						"timer": AbilityManager.combo_master_timer,
						"duration": 3.0,
						"name": "Combo",
						"description": "+" + str(bonus_percent) + "% Damage",
						"color": Color(1.0, 0.5, 0.2)  # Orange
					}
					buffs_changed = true
				else:
					active_buffs["combo_master"].timer = AbilityManager.combo_master_timer
			elif active_buffs.has("combo_master"):
				active_buffs.erase("combo_master")
				buffs_changed = true

	if buffs_changed:
		emit_signal("buff_changed", active_buffs)

	# Update shield display on health bar
	if health_bar and AbilityManager and AbilityManager.has_transcendence:
		if health_bar.has_method("set_shield"):
			health_bar.set_shield(AbilityManager.transcendence_shields, AbilityManager.transcendence_max)

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
	# Apply Swift Dodge speed bonus
	if AbilityManager:
		effective_speed *= AbilityManager.get_swift_dodge_speed_multiplier()
	velocity = direction * effective_speed
	move_and_slide()

	# Update Mage Arcane Focus stacks
	if has_arcane_focus:
		_update_arcane_focus(delta, direction.length() < 0.1)

	# Toxic Traits - spawn poison pools while moving
	if AbilityManager and AbilityManager.has_toxic_traits:
		if direction.length() > 0.1:  # Only spawn when actually moving
			toxic_trail_timer += delta
			if toxic_trail_timer >= TOXIC_TRAIL_INTERVAL:
				toxic_trail_timer = 0.0
				AbilityManager.spawn_toxic_pool(global_position)
		else:
			toxic_trail_timer = 0.0  # Reset timer when standing still

	# Keep player within dynamic arena bounds
	position.x = clamp(position.x, arena_bounds.position.x + arena_margin, arena_bounds.end.x - arena_margin)
	position.y = clamp(position.y, arena_bounds.position.y + arena_margin, arena_bounds.end.y - arena_margin)

	# Auto-attack (apply temp attack speed boost and flow bonus)
	attack_timer += delta
	var effective_cooldown = attack_cooldown / (1.0 + temp_attack_speed_boost)
	# Apply Monk Flow attack speed bonus
	if has_flow and flow_stacks > 0:
		effective_cooldown /= get_flow_attack_speed_multiplier()
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

	# Update target indicator
	_update_target_indicator(delta)

func _update_target_indicator(delta: float) -> void:
	if target_indicator == null or not is_instance_valid(target_indicator):
		return

	# Find nearest enemy (use existing function but without range limit)
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = INF

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	current_target = closest

	if current_target == null or not is_instance_valid(current_target):
		target_indicator.visible = false
		return

	# Position indicator at bottom of enemy sprite
	target_indicator.visible = true

	# Use collision shape to determine proper positioning
	var collision_shape = current_target.get_node_or_null("CollisionShape2D")
	var y_pos: float = 30.0  # Default fallback

	if collision_shape and collision_shape.shape:
		# Get the bottom of the collision shape
		if collision_shape.shape is RectangleShape2D:
			y_pos = collision_shape.shape.size.y / 2.0 + 5.0
		elif collision_shape.shape is CircleShape2D:
			y_pos = collision_shape.shape.radius + 5.0
		elif collision_shape.shape is CapsuleShape2D:
			y_pos = collision_shape.shape.height / 2.0 + 5.0
	else:
		# Fallback: check sprite but cap the offset to a reasonable value
		var enemy_sprite = current_target.get_node_or_null("Sprite")
		if enemy_sprite and enemy_sprite is Sprite2D:
			var texture = enemy_sprite.texture
			if texture:
				var total_height = texture.get_height()
				var vframes = enemy_sprite.vframes if enemy_sprite.vframes > 0 else 1
				var frame_height = (total_height / vframes) * enemy_sprite.scale.y
				y_pos = min(frame_height / 2.0, 50.0)  # Cap at 50px

	# Special offset for specific enemy types
	if current_target.has_method("get") and current_target.get("enemy_type") == "ratfolk":
		y_pos += 20.0  # Lower indicator for rat enemies

	target_indicator.global_position = current_target.global_position + Vector2(0, y_pos)

	# Pulse animation (scale and slight vertical movement)
	target_indicator_pulse += delta * 3.0
	var pulse_value = sin(target_indicator_pulse)
	var scale_pulse = 0.75 + pulse_value * 0.05  # Scale between 0.70 and 0.80 (25% smaller, less variance)
	var y_offset = pulse_value * 3.0  # Move up/down by 3 pixels
	target_indicator.scale = Vector2(scale_pulse, scale_pulse)
	target_indicator.global_position.y += y_offset

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

		var enemy_dist = global_position.distance_to(closest_enemy.global_position)

		# Assassin hybrid attack: melee if close, ranged if far
		if is_hybrid_attacker:
			if enemy_dist <= assassin_melee_range:
				# Close range - use melee attack
				perform_assassin_melee_attack()
			else:
				# Far range - throw dagger
				spawn_assassin_dagger()
		elif is_melee:
			# Check for Barbarian Berserker Rage (10% chance for spin attack)
			if has_berserker_rage and randf() < berserker_rage_chance:
				perform_spin_attack()
			else:
				# Normal melee attack
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
	# Set arc angle based on melee area - Beast has narrow focus
	var melee_arc = PI / 2  # Base 90 degrees
	if character_data and character_data.id == "beast":
		melee_arc = PI / 6  # Beast: 30 degrees - single target focused
		swipe.is_claw_attack = true
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

	# Set mage orb visual if playing as mage
	if character_data and character_data.id == "mage":
		arrow.is_mage_orb = true

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
		arrow.has_boomerang = AbilityManager.should_boomerang()
		# Ricochet - arrows bounce to nearby enemies
		arrow.has_ricochet = AbilityManager.has_ricochet
		arrow.max_ricochets = AbilityManager.ricochet_bounces

	# Apply Mage Arcane Focus damage bonus
	if has_arcane_focus and arcane_focus_stacks > 0:
		arrow.damage_multiplier *= get_arcane_focus_multiplier()

	# Apply Ranger Heartseeker damage bonus
	if has_heartseeker and heartseeker_stacks > 0:
		arrow.damage_multiplier *= get_heartseeker_damage_multiplier()

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

	# Choose attack animation based on character type
	if has_triple_attack:
		# Monk: Cycle through 3 attack animations
		match monk_attack_cycle:
			0:
				current_attack_row = row_attack
			1:
				current_attack_row = row_attack_2 if row_attack_2 >= 0 else row_attack
			2:
				current_attack_row = row_attack_3 if row_attack_3 >= 0 else row_attack
		monk_attack_cycle = (monk_attack_cycle + 1) % 3
	elif has_alt_attack and row_attack_alt >= 0:
		# Beast: Randomly pick between 2 attacks
		current_attack_row = row_attack if randf() < 0.5 else row_attack_alt
	else:
		current_attack_row = row_attack

	# Snap attack direction to 8 directions for cleaner arc attacks
	# Exception: Beast has narrow arc (30 deg) so snapping (up to 22.5 deg error) causes misses
	if not (character_data and character_data.id == "beast"):
		attack_direction = snap_to_8_directions(attack_direction)

	# Monk Flow dash - dash toward enemy at 3+ stacks
	var closest_enemy = find_closest_enemy()
	if has_flow and flow_stacks >= flow_dash_threshold and closest_enemy:
		_perform_flow_dash(closest_enemy.global_position)

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

	# Apply Monk Flow damage bonus
	if has_flow and flow_stacks > 0:
		melee_damage *= get_flow_damage_multiplier()

	# Apply Knight Retribution damage bonus
	var using_retribution = false
	if has_retribution and retribution_ready:
		melee_damage *= (1.0 + retribution_damage_bonus)
		using_retribution = true

	# Get enemies in melee range with arc check
	var enemies = get_tree().get_nodes_in_group("enemies")

	# Base melee arc - Beast has narrow focus, others have 90 degrees
	var melee_arc = PI / 2  # Default 90 degrees
	if character_data and character_data.id == "beast":
		melee_arc = PI / 6  # Beast: 30 degrees - single target focused
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
							# Beast passive: Lifesteal on crit
							if CharacterManager:
								var bonuses = CharacterManager.get_passive_bonuses()
								if bonuses.get("lifesteal_on_crit", 0.0) > 0:
									var heal_amount = final_damage * bonuses.get("lifesteal_on_crit", 0.0)
									heal(heal_amount, true, false, true)  # Show heal text

					# Apply damage
					if enemy.has_method("take_damage"):
						# Mark as ability kill if attack speed boost is active (e.g. Monster Energy)
						if has_ability_boosted_attacks() and enemy.has_method("mark_ability_kill"):
							enemy.mark_ability_kill()
						enemy.take_damage(final_damage, is_crit)

					# Apply Retribution stun (longer stun on first hit after taking damage)
					if using_retribution and enemy.has_method("apply_stun"):
						enemy.apply_stun(retribution_stun_duration)
					# Apply stagger on melee hit (0.5s stun)
					elif enemy.has_method("apply_stagger"):
						enemy.apply_stagger()

					# Knockback
					if AbilityManager and AbilityManager.has_knockback:
						if enemy.has_method("apply_knockback"):
							enemy.apply_knockback(to_enemy.normalized() * AbilityManager.knockback_force)

					# Apply elemental effects
					_apply_elemental_effects_to_enemy(enemy)

					# Adrenaline Rush - chance to dash on hit
					if AbilityManager:
						AbilityManager.check_adrenaline_dash_on_hit(self)

	# Slight screen shake on melee hit
	if melee_hit_enemies.size() > 0 and JuiceManager:
		JuiceManager.shake_small()

	# Monk Flow: Build stacks on successful hits
	if has_flow and melee_hit_enemies.size() > 0:
		_add_flow_stack()

	# Consume Knight Retribution after hitting enemies
	if using_retribution and melee_hit_enemies.size() > 0:
		_consume_retribution()

	# Double Strike - trigger a second attack after a brief delay (from passive)
	if AbilityManager and AbilityManager.should_double_strike():
		_queue_extra_swing(1)

	# Multiswing - trigger additional attacks from permanent upgrade
	if AbilityManager:
		var extra_swings = AbilityManager.get_extra_melee_swings()
		for i in range(extra_swings):
			_queue_extra_swing(i + 1)

var _extra_swings_queued: int = 0

func _queue_extra_swing(swing_index: int) -> void:
	_extra_swings_queued += 1
	var delay = 0.12 * swing_index  # Stagger each swing
	get_tree().create_timer(delay).timeout.connect(_perform_extra_swing)

func _perform_extra_swing() -> void:
	_extra_swings_queued -= 1
	if is_dead:
		return
	# Perform an extra melee attack hit (damage only, no animations/sounds)
	var melee_damage = 10.0 * base_damage
	if AbilityManager:
		melee_damage *= AbilityManager.get_damage_multiplier()
	if has_flow and flow_stacks > 0:
		melee_damage *= get_flow_damage_multiplier()

	var enemies = get_tree().get_nodes_in_group("enemies")
	var melee_arc = PI / 2
	if character_data and character_data.id == "beast":
		melee_arc = PI / 6
	if AbilityManager:
		melee_arc *= AbilityManager.get_melee_area_multiplier()
	var melee_reach = fire_range
	if AbilityManager:
		melee_reach *= AbilityManager.get_melee_range_multiplier()

	for enemy in enemies:
		if is_instance_valid(enemy):
			var to_enemy = enemy.global_position - global_position
			var dist = to_enemy.length()
			if dist <= melee_reach:
				var angle_to_enemy = to_enemy.angle()
				var attack_angle = attack_direction.angle()
				var angle_diff = abs(angle_to_enemy - attack_angle)
				if angle_diff > PI:
					angle_diff = TAU - angle_diff
				if angle_diff <= melee_arc / 2:
					var final_damage = melee_damage
					var is_crit = false
					if AbilityManager:
						var crit_chance = AbilityManager.get_crit_chance()
						if randf() < crit_chance:
							is_crit = true
							final_damage *= AbilityManager.get_crit_damage_multiplier()
					if enemy.has_method("take_damage"):
						# Mark as ability kill if attack speed boost is active (e.g. Monster Energy)
						if has_ability_boosted_attacks() and enemy.has_method("mark_ability_kill"):
							enemy.mark_ability_kill()
						enemy.take_damage(final_damage, is_crit)

# Barbarian Spin Attack - 360 degree AOE attack
func perform_spin_attack() -> void:
	melee_hit_enemies.clear()
	melee_hitbox_active = true
	is_spin_attacking = true
	current_attack_row = row_spin_attack if row_spin_attack >= 0 else row_attack

	# Play swing sound
	if SoundManager:
		SoundManager.play_swing()

	# Spawn swipe effect (full circle)
	spawn_swipe_effect()

	# Calculate spin attack damage (double damage for spin)
	var spin_damage = 10.0 * base_damage * berserker_rage_damage_multiplier

	# Apply ability modifiers
	if AbilityManager:
		spin_damage *= AbilityManager.get_damage_multiplier()

	# Get ALL enemies in AOE radius (360 degree attack)
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy not in melee_hit_enemies:
			var to_enemy = enemy.global_position - global_position
			var dist = to_enemy.length()

			# Hit all enemies within AOE radius (no arc check - it's 360 degrees)
			if dist <= berserker_rage_aoe_radius:
				melee_hit_enemies.append(enemy)

				var final_damage = spin_damage
				var is_crit = false

				# Crit check
				if AbilityManager:
					var crit_chance = AbilityManager.get_crit_chance()
					if randf() < crit_chance:
						is_crit = true
						final_damage *= AbilityManager.get_crit_damage_multiplier()
						if JuiceManager:
							JuiceManager.shake_crit()

				# Apply damage
				if enemy.has_method("take_damage"):
					# Mark as ability kill if attack speed boost is active (e.g. Monster Energy)
					if has_ability_boosted_attacks() and enemy.has_method("mark_ability_kill"):
						enemy.mark_ability_kill()
					enemy.take_damage(final_damage, is_crit)

				# Apply stagger
				if enemy.has_method("apply_stagger"):
					enemy.apply_stagger()

				# Knockback away from player
				if AbilityManager and AbilityManager.has_knockback:
					if enemy.has_method("apply_knockback"):
						enemy.apply_knockback(to_enemy.normalized() * AbilityManager.knockback_force * 1.5)

				# Apply elemental effects
				_apply_elemental_effects_to_enemy(enemy)

	# Screen shake for spin attack (bigger than normal melee)
	if melee_hit_enemies.size() > 0 and JuiceManager:
		JuiceManager.shake_medium()

# Assassin Melee Attack - close range dagger slash
func perform_assassin_melee_attack() -> void:
	melee_hit_enemies.clear()
	melee_hitbox_active = true
	current_attack_row = row_melee_attack if row_melee_attack >= 0 else row_attack

	# Play swing sound
	if SoundManager:
		SoundManager.play_swing()

	# Spawn swipe effect
	spawn_swipe_effect()

	# Calculate melee damage
	var melee_damage = 10.0 * base_damage

	# Apply ability modifiers
	if AbilityManager:
		melee_damage *= AbilityManager.get_damage_multiplier()

	# Apply Shadow Dance stealth bonus
	var from_stealth = false
	if has_shadow_dance and is_stealthed:
		melee_damage *= (1.0 + shadow_dance_damage_bonus)  # +100% damage
		from_stealth = true
		_exit_stealth()

	# Get enemies in melee range
	var enemies = get_tree().get_nodes_in_group("enemies")
	var melee_arc = PI / 3  # 60 degree arc (focused assassin strikes)
	var melee_reach = assassin_melee_range

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy not in melee_hit_enemies:
			var to_enemy = enemy.global_position - global_position
			var dist = to_enemy.length()

			if dist <= melee_reach:
				var angle_to_enemy = to_enemy.angle()
				var attack_angle = attack_direction.angle()
				var angle_diff = abs(angle_to_enemy - attack_angle)
				if angle_diff > PI:
					angle_diff = TAU - angle_diff

				if angle_diff <= melee_arc / 2:
					melee_hit_enemies.append(enemy)

					var final_damage = melee_damage
					var is_crit = false

					# Crit check (assassins have high crit)
					if AbilityManager:
						var crit_chance = AbilityManager.get_crit_chance()
						if randf() < crit_chance:
							is_crit = true
							final_damage *= AbilityManager.get_crit_damage_multiplier()
							if JuiceManager:
								JuiceManager.shake_crit()

					# Apply damage
					if enemy.has_method("take_damage"):
						# Mark as ability kill if attack speed boost is active (e.g. Monster Energy)
						if has_ability_boosted_attacks() and enemy.has_method("mark_ability_kill"):
							enemy.mark_ability_kill()
						enemy.take_damage(final_damage, is_crit)

					# Stagger on hit
					if enemy.has_method("apply_stagger"):
						enemy.apply_stagger()

					# Apply elemental effects
					_apply_elemental_effects_to_enemy(enemy)

					# Track Shadow Dance hits
					_on_shadow_dance_hit()

	# Screen shake
	if melee_hit_enemies.size() > 0 and JuiceManager:
		JuiceManager.shake_small()

# Assassin Ranged Attack - throw dagger
func spawn_assassin_dagger() -> void:
	if arrow_scene == null:
		return

	# Play throwing sound (use arrow sound for now)
	if SoundManager:
		SoundManager.play_arrow()

	# Muzzle flash
	spawn_muzzle_flash()

	# Calculate damage
	var dagger_damage = 10.0 * base_damage

	# Apply ability modifiers
	if AbilityManager:
		dagger_damage *= AbilityManager.get_damage_multiplier()

	# Apply Shadow Dance stealth bonus
	var from_stealth = false
	if has_shadow_dance and is_stealthed:
		dagger_damage *= (1.0 + shadow_dance_damage_bonus)  # +100% damage
		from_stealth = true
		_exit_stealth()

	# Spawn the dagger (using arrow scene with modified visuals)
	var dagger = arrow_scene.instantiate()
	dagger.global_position = global_position
	dagger.direction = attack_direction
	dagger.damage = dagger_damage
	dagger.is_assassin_dagger = true  # Flag for dagger visuals

	# Apply ability modifiers to projectile
	if AbilityManager:
		dagger.pierce_count = AbilityManager.stat_modifiers["projectile_pierce"]
		dagger.can_bounce = AbilityManager.has_rubber_walls
		dagger.has_sniper = AbilityManager.has_sniper_damage
		dagger.sniper_bonus = AbilityManager.sniper_bonus
		dagger.has_ricochet = AbilityManager.has_ricochet
		dagger.max_ricochets = AbilityManager.ricochet_bounces
		dagger.crit_chance = AbilityManager.get_crit_chance()
		dagger.crit_multiplier = AbilityManager.get_crit_damage_multiplier()
		dagger.has_knockback = AbilityManager.has_knockback
		dagger.knockback_force = AbilityManager.knockback_force
		dagger.speed_multiplier = AbilityManager.get_projectile_speed_multiplier()

	# Track Shadow Dance on hit
	dagger.connect("enemy_hit", _on_shadow_dance_hit)

	get_parent().add_child(dagger)

# Shadow Dance - track hits and trigger stealth
func _on_shadow_dance_hit() -> void:
	if not has_shadow_dance or is_stealthed:
		return

	shadow_dance_hit_count += 1
	if shadow_dance_hit_count >= shadow_dance_hits_required:
		_enter_stealth()

func _enter_stealth() -> void:
	if is_stealthed:
		return

	is_stealthed = true
	stealth_timer = shadow_dance_duration
	shadow_dance_hit_count = 0
	is_playing_disappear = true
	animation_frame = 0.0

	# Visual feedback - become semi-transparent
	modulate.a = 0.4

	# Add buff display (indefinite until attack)
	active_buffs["shadow_dance"] = {
		"timer": -1,
		"duration": -1,
		"name": "Shadow Dance",
		"description": "+100% Damage (Stealthed)",
		"color": Color(0.5, 0.3, 0.8)  # Purple
	}
	emit_signal("buff_changed", active_buffs)

	# Shadow Dance: Dash to nearest enemy and perform melee attack
	_shadow_dance_dash_attack()

func _shadow_dance_dash_attack() -> void:
	"""Dash to nearest enemy and perform a melee attack from stealth."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	# Find nearest enemy
	var nearest_enemy: Node2D = null
	var nearest_dist: float = 999999.0
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_enemy = enemy

	if nearest_enemy == null:
		return

	# Only dash if enemy is within reasonable range (not too far)
	var max_dash_range = 400.0
	if nearest_dist > max_dash_range:
		return

	# Calculate dash target position (slightly in front of enemy)
	var to_enemy = (nearest_enemy.global_position - global_position).normalized()
	var dash_target = nearest_enemy.global_position - to_enemy * (assassin_melee_range * 0.5)

	# Clamp to arena bounds
	dash_target.x = clamp(dash_target.x, arena_bounds.position.x + arena_margin, arena_bounds.end.x - arena_margin)
	dash_target.y = clamp(dash_target.y, arena_bounds.position.y + arena_margin, arena_bounds.end.y - arena_margin)

	# Update facing direction
	facing_right = to_enemy.x > 0
	attack_direction = to_enemy

	# Smooth dash using tween
	var dash_duration = 0.15
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", dash_target, dash_duration)

	# Spawn dash trail effect
	_spawn_shadow_trail()

	# Perform melee attack after dash completes
	tween.tween_callback(_shadow_dance_strike.bind(nearest_enemy))

func _spawn_shadow_trail() -> void:
	"""Spawn a purple shadow trail during the dash."""
	var trail_count = 5
	for i in range(trail_count):
		var delay = i * 0.025
		get_tree().create_timer(delay).timeout.connect(func():
			if not is_instance_valid(self):
				return
			var ghost = Sprite2D.new()
			ghost.texture = sprite.texture
			ghost.hframes = sprite.hframes
			ghost.vframes = sprite.vframes
			ghost.frame = sprite.frame
			ghost.global_position = global_position
			ghost.flip_h = sprite.flip_h
			ghost.scale = sprite.scale
			ghost.modulate = Color(0.5, 0.2, 0.8, 0.6)  # Purple ghost
			ghost.z_index = z_index - 1
			get_parent().add_child(ghost)
			# Fade out
			var ghost_tween = ghost.create_tween()
			ghost_tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
			ghost_tween.tween_callback(ghost.queue_free)
		)

func _shadow_dance_strike(target_enemy: Node2D) -> void:
	"""Perform the stealth strike on the target enemy."""
	if not is_instance_valid(target_enemy):
		return

	# Play melee attack animation
	if row_melee_attack >= 0:
		current_row = row_melee_attack
		animation_frame = 0.0
		is_attacking = true

	# Play sound
	if SoundManager:
		SoundManager.play_swing()

	# Spawn slash effect on enemy (S0181)
	_spawn_shadow_slash_effect(target_enemy)

	# Calculate damage with stealth bonus already applied
	var melee_damage = 10.0 * base_damage
	if AbilityManager:
		melee_damage *= AbilityManager.get_damage_multiplier()
	melee_damage *= (1.0 + shadow_dance_damage_bonus)  # +100% damage from stealth

	# Check for crit
	var crit_chance = AbilityManager.get_crit_chance() if AbilityManager else 0.05
	var is_crit = randf() < crit_chance
	var final_damage = melee_damage
	if is_crit:
		final_damage *= (AbilityManager.get_crit_damage_multiplier() if AbilityManager else 2.0)

	# Apply damage
	if target_enemy.has_method("take_damage"):
		# Mark as ability kill if attack speed boost is active (e.g. Monster Energy)
		if has_ability_boosted_attacks() and target_enemy.has_method("mark_ability_kill"):
			target_enemy.mark_ability_kill()
		target_enemy.take_damage(final_damage, is_crit)

	# Stagger
	if target_enemy.has_method("apply_stagger"):
		target_enemy.apply_stagger()

	# Screen shake for impact
	if JuiceManager:
		if is_crit:
			JuiceManager.shake_crit()
		else:
			JuiceManager.shake_small()
		JuiceManager.hitstop_micro()

	# Exit stealth after the strike
	_exit_stealth()

func _exit_stealth() -> void:
	is_stealthed = false
	stealth_timer = 0.0
	is_playing_disappear = false
	modulate.a = 1.0

	# Remove buff display
	if active_buffs.has("shadow_dance"):
		active_buffs.erase("shadow_dance")
		emit_signal("buff_changed", active_buffs)

func _spawn_shadow_slash_effect(target_enemy: Node2D) -> void:
	"""Spawn the S0181 slash effect on the enemy."""
	if not is_instance_valid(target_enemy):
		return

	# Create animated sprite for the slash effect
	var slash = AnimatedSprite2D.new()
	slash.name = "ShadowSlash"

	# Create sprite frames from individual images
	var frames = SpriteFrames.new()
	frames.add_animation("slash")
	frames.set_animation_speed("slash", 20.0)  # Fast animation
	frames.set_animation_loop("slash", false)

	# Load frames S0181.png through S0190.png
	var base_path = "res://assets/sprites/effects/40/Slash and Swing/S0181/"
	for i in range(10):
		var frame_num = 181 + i
		var frame_path = base_path + "S0" + str(frame_num) + ".png"
		var texture = load(frame_path)
		if texture:
			frames.add_frame("slash", texture)

	slash.sprite_frames = frames
	slash.animation = "slash"
	slash.centered = true
	slash.z_index = 10  # Above enemy

	# Position on enemy
	slash.global_position = target_enemy.global_position

	# Add to world
	get_parent().add_child(slash)

	# Play animation
	slash.play("slash")

	# Queue free when done
	slash.animation_finished.connect(slash.queue_free)

func _apply_elemental_effects_to_enemy(enemy: Node2D) -> void:
	"""Apply elemental on-hit effects to an enemy."""
	if not AbilityManager:
		return

	# Chaotic Strikes - random elemental effect each hit
	if AbilityManager.has_chaotic_strikes:
		var chaos_element = AbilityManager.get_chaotic_element()
		match chaos_element:
			"fire":
				if enemy.has_method("apply_burn"):
					enemy.apply_burn(3.0)
				_spawn_elemental_text(enemy, "BURN", Color(1.0, 0.4, 0.2))
			"ice":
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(0.5, 2.0)
				_spawn_elemental_text(enemy, "CHILL", Color(0.4, 0.7, 1.0))
			"lightning":
				AbilityManager.trigger_lightning_at(enemy.global_position)
				_spawn_elemental_text(enemy, "ZAP", Color(1.0, 0.9, 0.4))
		return  # Chaotic strikes replaces other elemental effects

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

	# Assassin disappear animation (plays when entering stealth)
	if is_playing_disappear and row_disappear >= 0:
		target_row = row_disappear
		# Check if disappear animation finished
		if animation_frame >= frame_counts.get(row_disappear, 8) - 1:
			is_playing_disappear = false
	elif is_bladestorming:
		# Bladestorm rapid attack animation - use attack row and flip rapidly
		target_row = row_attack
		is_attacking = true  # Keep attacking state
		# Don't end attack animation during bladestorm - let it loop
	elif is_attacking:
		# Barbarian spin attack
		if is_spin_attacking and row_spin_attack >= 0:
			target_row = row_spin_attack
			# Check if spin animation finished
			if animation_frame >= frame_counts.get(row_spin_attack, 8) - 1:
				is_attacking = false
				is_spin_attacking = false
				melee_hitbox_active = false
		elif is_melee or (is_hybrid_attacker and current_attack_row == row_melee_attack):
			# Melee uses current attack animation (may be alternate for Beast, or assassin melee)
			target_row = current_attack_row
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
			is_spin_attacking = false
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

	# Clamp animation frame to valid range to prevent empty frames
	var clamped_frame = mini(int(animation_frame), max_frames - 1)

	# Set the sprite frame
	sprite.frame = current_row * cols_per_row + clamped_frame

	# Apply sprite offset (for off-center sprites like beast)
	# When sprite is flipped, we need to negate X offset to keep character centered
	# because flip_h mirrors around the sprite center, not the character center
	if base_sprite_offset.x != 0:
		if sprite.flip_h:
			sprite.offset = Vector2(-base_sprite_offset.x, base_sprite_offset.y)
		else:
			sprite.offset = base_sprite_offset
	else:
		sprite.offset = base_sprite_offset

func update_death_animation(delta: float) -> void:
	# Play death animation once, then hold on last frame
	if death_animation_finished:
		return

	animation_frame += animation_speed * delta

	# Handle Mage's special death animation (frame skipping across 2 rows)
	if death_spans_rows and death_row_2 >= 0:
		var total_frames = frame_counts.get(row_death, 4) + frames_death_row_2
		if animation_frame >= total_frames - 1:
			animation_frame = total_frames - 1
			death_animation_finished = true

		var frame_index = int(animation_frame)
		var first_row_frames = frame_counts.get(row_death, 4)

		if frame_index < first_row_frames:
			# First death row
			current_row = row_death
			sprite.frame = current_row * cols_per_row + (frame_index * death_frame_skip)
		else:
			# Second death row
			current_row = death_row_2
			var second_row_frame = frame_index - first_row_frames
			sprite.frame = current_row * cols_per_row + (second_row_frame * death_frame_skip)
	else:
		# Normal death animation
		current_row = row_death
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

	# No XP gain at max level
	if current_level >= MAX_LEVEL:
		return

	var final_amount = amount * xp_multiplier
	current_xp += final_amount
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

	while current_xp >= xp_to_next_level and current_level < MAX_LEVEL:
		current_xp -= xp_to_next_level
		current_level += 1
		# XP scaling: 1.5x for levels 1-10, then 1.15x after level 10
		# This allows faster progression in late game to reach ~level 20 by 20 mins
		if current_level <= 10:
			xp_to_next_level *= 1.5
		else:
			xp_to_next_level *= 1.15

		# Apply automatic level bonuses (5% damage and health per level)
		if AbilityManager:
			AbilityManager.add_level_bonus()
		# Increase max health by 5% and heal the same amount (rounded up)
		var health_increase = ceili(base_max_health * 0.05)
		base_max_health += health_increase
		max_health += health_increase
		current_health += health_increase
		if health_bar:
			health_bar.set_health(current_health, max_health)
		emit_signal("health_changed", current_health, max_health)

		# Play level up sound
		if SoundManager:
			SoundManager.play_levelup()
		# Haptic feedback on level up
		if HapticManager:
			HapticManager.level_up()
		# Epic level up celebration effects (#6)
		if JuiceManager:
			JuiceManager.trigger_level_up_celebration()
		# Spawn level up visual effect on player
		_spawn_level_up_effect()
		emit_signal("level_up", current_level)
		emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

	# At max level, set XP to full and stop
	if current_level >= MAX_LEVEL:
		current_xp = xp_to_next_level
		emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

func give_kill_xp(enemy_max_hp: float = 100.0) -> void:
	# XP based on enemy HP: 10-30 scaled by HP (100 HP = base, higher HP = more XP)
	var hp_factor = clamp(enemy_max_hp / 100.0, 0.5, 3.0)
	var xp_gain = randf_range(10.0, 30.0) * hp_factor
	add_xp(xp_gain)

# Ability system helper functions
func heal(amount: float, _play_sound: bool = true, show_particles: bool = false, show_text: bool = false) -> void:
	var actual_heal = min(amount, max_health - current_health)
	if actual_heal <= 0:
		return  # Already at full health

	current_health += actual_heal
	if health_bar:
		health_bar.set_health(current_health, max_health)
		# Show +HP text on health bar for potion heals or lifesteal
		if (show_particles or show_text) and health_bar.has_method("show_heal_text"):
			health_bar.show_heal_text(actual_heal)
	emit_signal("health_changed", current_health, max_health)

	# Update low HP vignette
	if JuiceManager:
		JuiceManager.update_player_health(current_health / max_health)

	# Spawn green heal particles for potion heals
	if show_particles:
		_spawn_heal_particles()

	# Accumulate heal for display - only show when >= 1
	accumulated_heal += actual_heal
	if accumulated_heal >= 1.0:
		var display_amount = floor(accumulated_heal)
		spawn_heal_number(display_amount)
		accumulated_heal -= display_amount

func _spawn_heal_particles() -> void:
	"""Spawn green healing particle effect around the player."""
	var particle_count = 8
	for i in range(particle_count):
		var particle = Node2D.new()
		particle.global_position = global_position
		get_parent().add_child(particle)

		# Create a small green circle
		var circle = Polygon2D.new()
		var points: Array[Vector2] = []
		var segments = 6
		var psize = randf_range(3, 6)
		for j in range(segments):
			var angle = (float(j) / segments) * TAU
			points.append(Vector2(cos(angle), sin(angle)) * psize)
		circle.polygon = points
		circle.color = Color(0.3, 1.0, 0.4, 0.9)  # Green
		particle.add_child(circle)

		# Random angle for this particle
		var pangle = randf() * TAU
		var start_offset = Vector2(cos(pangle), sin(pangle)) * randf_range(15, 30)
		particle.position = start_offset

		# Animate floating up and fading
		var tween = particle.create_tween()
		tween.set_parallel(true)
		var end_pos = start_offset + Vector2(randf_range(-10, 10), randf_range(-40, -60))
		tween.tween_property(particle, "position", end_pos, randf_range(0.6, 1.0))
		tween.tween_property(circle, "modulate:a", 0.0, randf_range(0.5, 0.8))
		tween.chain().tween_callback(particle.queue_free)

func _spawn_level_up_effect() -> void:
	"""Holy Heal level up effect with sprite animation and white screen flash."""
	var effect_container = Node2D.new()
	effect_container.position = Vector2.ZERO  # Local position relative to player
	add_child(effect_container)  # Add as child of player so it follows

	# === HOLY HEAL SPRITE ANIMATION ===
	var holy_heal_sprite = Sprite2D.new()
	holy_heal_sprite.scale = Vector2(3.75, 3.75)
	holy_heal_sprite.position = Vector2(0, -60)
	holy_heal_sprite.modulate.a = 0.0
	effect_container.add_child(holy_heal_sprite)

	# Load Holy Heal frames
	var holy_heal_frames: Array[Texture2D] = []
	for i in range(1, 9):
		var frame_path = "res://assets/sprites/effects/40/Other/Holy Heal/holy-heal%02d.png" % i
		if ResourceLoader.exists(frame_path):
			holy_heal_frames.append(load(frame_path))

	if holy_heal_frames.size() > 0:
		holy_heal_sprite.texture = holy_heal_frames[0]

		# Animate through frames
		var frame_tween = holy_heal_sprite.create_tween()
		frame_tween.tween_property(holy_heal_sprite, "modulate:a", 1.0, 0.05)
		for f in range(holy_heal_frames.size()):
			frame_tween.tween_callback(func(): holy_heal_sprite.texture = holy_heal_frames[f])
			frame_tween.tween_interval(0.08)
		frame_tween.tween_property(holy_heal_sprite, "modulate:a", 0.0, 0.2)

	# === WHITE SCREEN FLASH ===
	_spawn_level_up_screen_flash()

	# Cleanup
	var cleanup_tween = effect_container.create_tween()
	cleanup_tween.tween_interval(1.2)
	cleanup_tween.tween_callback(effect_container.queue_free)

	# Brief invulnerability on level up (0.3s)
	set_invulnerable(true, 0.3)

func _spawn_level_up_screen_flash() -> void:
	"""Create a white light pulse that flashes the entire screen."""
	# Create a CanvasLayer to render on top of everything
	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 100  # High layer to be on top
	get_tree().root.add_child(flash_layer)

	# White overlay covering the screen
	var flash_overlay = ColorRect.new()
	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash_overlay)

	# Animate the flash - quick pulse in, slower fade out
	var flash_tween = flash_overlay.create_tween()
	flash_tween.tween_property(flash_overlay, "color:a", 0.6, 0.08).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash_overlay, "color:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	flash_tween.tween_callback(flash_layer.queue_free)

	# Knock back nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < 120:
				var direction = (enemy.global_position - global_position).normalized()
				if enemy.has_method("apply_knockback"):
					enemy.apply_knockback(direction * 300)

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

	# Update max HP (add flat amount + percentage)
	var hp_flat = modifiers.get("max_hp", 0.0)
	var hp_percent = modifiers.get("max_hp_percent", 0.0)
	var old_max = max_health
	var new_max = (base_max_health + hp_flat) * (1.0 + hp_percent)

	# Ensure max HP never goes below 1
	new_max = maxf(new_max, 1.0)

	# When max HP increases, add the bonus to current health too
	# (so 10/25 + 50 max HP = 60/75, not 30/75)
	if new_max != old_max:
		var hp_difference = new_max - old_max
		max_health = new_max
		# Add the HP difference to current health (but cap at new max, floor at 1)
		current_health = clampf(current_health + hp_difference, 1.0, max_health)
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

func start_bladestorm_animation(duration: float) -> void:
	"""Start the bladestorm rapid attack animation."""
	is_bladestorming = true
	bladestorm_timer = duration
	bladestorm_flip_timer = 0.0
	is_attacking = true  # Keep in attack state

func stop_bladestorm_animation() -> void:
	"""Stop the bladestorm animation."""
	is_bladestorming = false
	bladestorm_timer = 0.0
	is_attacking = false

func get_elemental_tint() -> Color:
	"""Get tint color based on active elemental effects."""
	if not AbilityManager:
		return Color.WHITE

	var colors: Array[Color] = []

	# Check for chaotic strikes - random element each attack
	if AbilityManager.has_chaotic_strikes:
		var chaos_element = AbilityManager.get_chaotic_element()
		match chaos_element:
			"fire":
				return Color.WHITE.lerp(Color(1.0, 0.4, 0.2), 0.6)  # Fire - Orange/Red
			"ice":
				return Color.WHITE.lerp(Color(0.4, 0.7, 1.0), 0.6)  # Ice - Blue/Cyan
			"lightning":
				return Color.WHITE.lerp(Color(1.0, 0.9, 0.4), 0.6)  # Lightning - Yellow
			_:
				return Color.WHITE

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
	var dash_duration = 0.12  # Fast but smooth dash

	# Calculate end position
	var end_pos = global_position + direction * dash_distance

	# Clamp to dynamic arena bounds
	end_pos.x = clamp(end_pos.x, arena_bounds.position.x + arena_margin, arena_bounds.end.x - arena_margin)
	end_pos.y = clamp(end_pos.y, arena_bounds.position.y + arena_margin, arena_bounds.end.y - arena_margin)

	# Update facing direction
	if direction.x > 0:
		facing_right = true
		sprite.flip_h = false
	elif direction.x < 0:
		facing_right = false
		sprite.flip_h = true

	# Create tween for smooth dash movement
	var tween = create_tween()
	tween.tween_property(self, "global_position", end_pos, dash_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

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

	# Update Monk Flow timer
	if has_flow and flow_stacks > 0:
		flow_timer -= delta
		if flow_timer <= 0:
			_decay_flow_stacks()

	# Update Knight Retribution timer
	if has_retribution and retribution_ready:
		retribution_timer -= delta
		if active_buffs.has("retribution"):
			active_buffs["retribution"].timer = retribution_timer
		if retribution_timer <= 0:
			_consume_retribution()

	# Assassin Shadow Dance stealth - lasts until attack (no timer)
	# Stealth ends when _shadow_dance_strike completes

	# Update ultimate ability timers
	_update_ultimate_timers(delta)

# ============================================
# MONK FLOW SYSTEM (Flowing Strikes Passive)
# ============================================

func _add_flow_stack() -> void:
	"""Add a flow stack and reset the decay timer."""
	var prev_stacks = flow_stacks
	flow_stacks = min(flow_stacks + 1, flow_max_stacks)
	flow_timer = flow_decay_time

	# Update buff display
	_update_flow_buff()

	# Visual/audio feedback when reaching dash threshold
	if prev_stacks < flow_dash_threshold and flow_stacks >= flow_dash_threshold:
		if JuiceManager:
			JuiceManager.shake_small()

func _decay_flow_stacks() -> void:
	"""Decay all flow stacks when timer expires."""
	flow_stacks = 0
	flow_timer = 0.0
	if active_buffs.has("flow"):
		active_buffs.erase("flow")
		emit_signal("buff_changed", active_buffs)

func _update_flow_buff() -> void:
	"""Update the flow buff display."""
	if flow_stacks > 0:
		var dmg_bonus = int(flow_stacks * flow_damage_per_stack * 100)
		var spd_bonus = int(flow_stacks * flow_speed_per_stack * 100)
		var desc = "+" + str(dmg_bonus) + "% Damage, +" + str(spd_bonus) + "% Speed"
		if flow_stacks >= flow_dash_threshold:
			desc += " [DASH]"

		active_buffs["flow"] = {
			"timer": flow_timer,
			"duration": flow_decay_time,
			"name": "Flow x" + str(flow_stacks),
			"description": desc,
			"color": Color(0.6, 0.4, 1.0)  # Purple for Monk
		}
		emit_signal("buff_changed", active_buffs)

func _perform_flow_dash(target_pos: Vector2) -> void:
	"""Dash toward target position (Monk Flow at 3+ stacks)."""
	var direction = (target_pos - global_position).normalized()
	var dash_distance = 60.0  # Shorter dash for flow
	var dash_duration = 0.1  # Fast but smooth dash

	# Calculate end position
	var end_pos = global_position + direction * dash_distance

	# Clamp to dynamic arena bounds
	end_pos.x = clamp(end_pos.x, arena_bounds.position.x + arena_margin, arena_bounds.end.x - arena_margin)
	end_pos.y = clamp(end_pos.y, arena_bounds.position.y + arena_margin, arena_bounds.end.y - arena_margin)

	# Update facing direction
	if direction.x > 0:
		facing_right = true
		sprite.flip_h = false
	elif direction.x < 0:
		facing_right = false
		sprite.flip_h = true

	# Create tween for smooth dash movement
	var tween = create_tween()
	tween.tween_property(self, "global_position", end_pos, dash_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Spawn visual effect
	_spawn_dash_smoke()

	# Play dash sound
	if SoundManager:
		SoundManager.play_dash()

func get_flow_damage_multiplier() -> float:
	"""Get the current flow damage multiplier."""
	if not has_flow or flow_stacks <= 0:
		return 1.0
	return 1.0 + (flow_stacks * flow_damage_per_stack)

func get_flow_attack_speed_multiplier() -> float:
	"""Get the current flow attack speed multiplier."""
	if not has_flow or flow_stacks <= 0:
		return 1.0
	return 1.0 + (flow_stacks * flow_speed_per_stack)

# ============================================
# MAGE ARCANE FOCUS SYSTEM
# ============================================

func _update_arcane_focus(delta: float, is_standing_still: bool) -> void:
	"""Update Arcane Focus stacks based on movement state."""
	var prev_stacks = int(arcane_focus_stacks)

	if is_standing_still:
		# Build stacks: 1 stack per second while standing still
		arcane_focus_stacks = min(arcane_focus_stacks + delta, float(arcane_focus_max_stacks))
	else:
		# Decay stacks over 5 seconds when moving
		var decay_rate = float(arcane_focus_max_stacks) / arcane_focus_decay_time
		arcane_focus_stacks = max(arcane_focus_stacks - decay_rate * delta, 0.0)

	# Update buff display when stack count changes
	var current_stacks = int(arcane_focus_stacks)
	if current_stacks != prev_stacks or (current_stacks > 0 and not active_buffs.has("arcane_focus")):
		_update_arcane_focus_buff()

func _update_arcane_focus_buff() -> void:
	"""Update the Arcane Focus buff display."""
	var display_stacks = int(arcane_focus_stacks)
	if display_stacks > 0:
		var bonus_percent = int(arcane_focus_stacks * arcane_focus_per_stack * 100)
		active_buffs["arcane_focus"] = {
			"timer": -1,  # No timer, based on movement
			"duration": -1,
			"name": "Focus x" + str(display_stacks),
			"description": "+" + str(bonus_percent) + "% Damage dealt & taken",
			"color": Color(0.3, 0.5, 1.0)  # Blue for Mage
		}
		emit_signal("buff_changed", active_buffs)
	elif active_buffs.has("arcane_focus"):
		active_buffs.erase("arcane_focus")
		emit_signal("buff_changed", active_buffs)

func get_arcane_focus_multiplier() -> float:
	"""Get the current Arcane Focus damage multiplier (affects both dealt and taken)."""
	if not has_arcane_focus or arcane_focus_stacks <= 0:
		return 1.0
	return 1.0 + (arcane_focus_stacks * arcane_focus_per_stack)

# ============================================
# RANGER HEARTSEEKER SYSTEM
# ============================================

func on_arrow_hit_enemy(enemy: Node2D, is_crit: bool) -> void:
	"""Called when an arrow hits an enemy. Used for Heartseeker tracking."""
	if not has_heartseeker:
		return

	if not is_instance_valid(enemy):
		return

	# Check if same target as last hit (also check if last target is still valid)
	if is_instance_valid(heartseeker_last_target) and heartseeker_last_target == enemy:
		# Build stacks
		heartseeker_stacks = min(heartseeker_stacks + 1, heartseeker_max_stacks)
	else:
		# New target or previous target died, reset stacks to 1
		heartseeker_stacks = 1
		heartseeker_last_target = enemy

	_update_heartseeker_buff()

	# Beast passive: Lifesteal on crit (also applies to ranger arrows)
	if is_crit and CharacterManager:
		var bonuses = CharacterManager.get_passive_bonuses()
		if bonuses.get("lifesteal_on_crit", 0.0) > 0:
			# Estimate damage for lifesteal calculation
			var estimated_damage = 10.0 * base_damage
			if AbilityManager:
				estimated_damage *= AbilityManager.get_damage_multiplier()
			var heal_amount = estimated_damage * bonuses.get("lifesteal_on_crit", 0.0)
			heal(heal_amount, true, false, true)  # Show heal text

func get_heartseeker_damage_multiplier() -> float:
	"""Get the current Heartseeker damage multiplier."""
	if not has_heartseeker or heartseeker_stacks <= 0:
		return 1.0
	return 1.0 + (heartseeker_stacks * heartseeker_damage_per_stack)

func _update_heartseeker_buff() -> void:
	"""Update the Heartseeker buff display."""
	if heartseeker_stacks > 0:
		var bonus_percent = int(heartseeker_stacks * heartseeker_damage_per_stack * 100)
		active_buffs["heartseeker"] = {
			"timer": -1,  # No timer, based on target
			"duration": -1,
			"name": "Heartseeker x" + str(heartseeker_stacks),
			"description": "+" + str(bonus_percent) + "% Damage (same target)",
			"color": Color(0.2, 0.8, 0.4)  # Green for Ranger
		}
		emit_signal("buff_changed", active_buffs)
	elif active_buffs.has("heartseeker"):
		active_buffs.erase("heartseeker")
		emit_signal("buff_changed", active_buffs)

func reset_heartseeker() -> void:
	"""Reset Heartseeker stacks (called when target dies or changes)."""
	if not has_heartseeker:
		return
	heartseeker_stacks = 0
	heartseeker_last_target = null
	if active_buffs.has("heartseeker"):
		active_buffs.erase("heartseeker")
		emit_signal("buff_changed", active_buffs)

# ============================================
# KNIGHT RETRIBUTION SYSTEM
# ============================================

func _activate_retribution() -> void:
	"""Activate Retribution after taking damage."""
	retribution_ready = true
	retribution_timer = retribution_duration
	_update_retribution_buff()

	# Visual feedback - red glow on player
	_spawn_retribution_effect()

func _spawn_retribution_effect() -> void:
	"""Spawn a red glow effect around player to indicate Retribution is active."""
	var effect = Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)

	# Red pulsing aura
	var aura = Polygon2D.new()
	var aura_points: Array[Vector2] = []
	for i in range(16):
		var angle = (float(i) / 16) * TAU
		aura_points.append(Vector2(cos(angle), sin(angle)) * 35)
	aura.polygon = aura_points
	aura.color = Color(1.0, 0.2, 0.2, 0.0)
	effect.add_child(aura)

	# Animate aura appearing
	var tween = aura.create_tween()
	tween.tween_property(aura, "color:a", 0.5, 0.15)
	tween.tween_property(aura, "scale", Vector2(1.3, 1.3), 0.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(aura, "color:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

	# Red particles bursting outward
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(1.0, 0.3, 0.2, 0.9)
		particle.position = Vector2(-2, -2)
		effect.add_child(particle)

		var p_angle = (float(i) / 8) * TAU
		var end_pos = Vector2(cos(p_angle), sin(p_angle)) * 40

		var p_tween = particle.create_tween()
		p_tween.set_parallel(true)
		p_tween.tween_property(particle, "position", end_pos, 0.25).set_ease(Tween.EASE_OUT)
		p_tween.tween_property(particle, "modulate:a", 0.0, 0.2).set_delay(0.1)

func _consume_retribution() -> void:
	"""Consume Retribution after hitting enemies."""
	retribution_ready = false
	retribution_timer = 0.0
	if active_buffs.has("retribution"):
		active_buffs.erase("retribution")
		emit_signal("buff_changed", active_buffs)

func _update_retribution_buff() -> void:
	"""Update the Retribution buff display."""
	if retribution_ready:
		var bonus_percent = int(retribution_damage_bonus * 100)
		active_buffs["retribution"] = {
			"timer": retribution_timer,
			"duration": retribution_duration,
			"name": "Retribution",
			"description": "+" + str(bonus_percent) + "% Damage + Stun",
			"color": Color(1.0, 0.3, 0.3)  # Red for Knight
		}
		emit_signal("buff_changed", active_buffs)
	elif active_buffs.has("retribution"):
		active_buffs.erase("retribution")
		emit_signal("buff_changed", active_buffs)

# ============================================
# ULTIMATE ABILITY SUPPORT METHODS
# ============================================

# Damage reduction state
var damage_reduction_percent: float = 0.0
var damage_reduction_timer: float = 0.0

# Lifesteal state
var lifesteal_percent: float = 0.0
var lifesteal_timer: float = 0.0

# Unbreakable Will state (Knight ultimate - death prevention)
var has_unbreakable_will: bool = false
var unbreakable_will_duration: float = 10.0

# Feast of Carnage state (Beast ultimate - kill healing/damage stacking)
var has_feast_of_carnage: bool = false
var feast_of_carnage_timer: float = 0.0
var feast_of_carnage_stacks: int = 0

# Savage Instinct state (Beast ultimate - auto-execute low HP enemies)
var has_savage_instinct: bool = false
var savage_instinct_timer: float = 0.0
var savage_instinct_threshold: float = 0.30

# Apex Predator state (Beast ultimate - mark all enemies, dash through = big damage)
var has_apex_predator: bool = false
var apex_predator_timer: float = 0.0
var apex_predator_damage: float = 0.0

# Time Rewind state (Mage ultimate)
var time_rewind_active: bool = false
var time_rewind_position: Vector2 = Vector2.ZERO
var time_rewind_health: float = 0.0
var time_rewind_timer: float = 0.0
var time_rewind_triggered: bool = false

# Dragon's Awakening state (Monk ultimate - attacks create shockwaves)
var has_dragons_awakening: bool = false
var dragons_awakening_timer: float = 0.0
var dragons_awakening_range: float = 300.0
var dragons_awakening_damage: float = 0.0

# Perfect Harmony state (Monk ultimate - every 4th attack triggers all 3 animations)
var has_perfect_harmony: bool = false
var perfect_harmony_timer: float = 0.0
var perfect_harmony_attack_count: int = 0

func apply_speed_boost(multiplier: float, duration: float) -> void:
	"""Apply a speed boost (wrapper for ultimate abilities)."""
	apply_temporary_speed_boost(multiplier - 1.0, duration)

func apply_attack_speed_boost(multiplier: float, duration: float) -> void:
	"""Apply an attack speed boost (wrapper for ultimate abilities)."""
	apply_temporary_attack_speed_boost(multiplier - 1.0, duration)

func has_ability_boosted_attacks() -> bool:
	"""Check if an ability is actively boosting auto-attacks (e.g. Monster Energy)."""
	return temp_attack_speed_timer > 0

func apply_damage_reduction(percent: float, duration: float) -> void:
	"""Apply temporary damage reduction."""
	damage_reduction_percent = percent
	damage_reduction_timer = duration
	var reduction_display = int(percent * 100)
	active_buffs["damage_reduction"] = {
		"timer": duration,
		"duration": duration,
		"name": "Fortified",
		"description": str(reduction_display) + "% Damage Reduction",
		"color": Color(0.3, 0.6, 1.0)  # Blue
	}
	emit_signal("buff_changed", active_buffs)

func get_damage_reduction() -> float:
	"""Get current damage reduction from ultimate abilities."""
	if damage_reduction_timer > 0:
		return damage_reduction_percent
	return 0.0

func set_lifesteal(percent: float, duration: float) -> void:
	"""Set temporary lifesteal."""
	lifesteal_percent = percent
	lifesteal_timer = duration
	var lifesteal_display = int(percent * 100)
	active_buffs["lifesteal"] = {
		"timer": duration,
		"duration": duration,
		"name": "Vampiric",
		"description": str(lifesteal_display) + "% Lifesteal",
		"color": Color(0.8, 0.2, 0.3)  # Dark red
	}
	emit_signal("buff_changed", active_buffs)

func get_lifesteal_percent() -> float:
	"""Get current lifesteal percent."""
	if lifesteal_timer > 0:
		return lifesteal_percent
	return 0.0

func set_unbreakable_will(active: bool, duration: float = 10.0) -> void:
	"""Set Unbreakable Will state (prevents next death)."""
	has_unbreakable_will = active
	unbreakable_will_duration = duration
	if active:
		active_buffs["unbreakable_will"] = {
			"timer": -1,  # Passive effect
			"duration": -1,
			"name": "Unbreakable",
			"description": "Death prevented once",
			"color": Color(1.0, 0.84, 0.0)  # Gold
		}
	elif active_buffs.has("unbreakable_will"):
		active_buffs.erase("unbreakable_will")
	emit_signal("buff_changed", active_buffs)

func trigger_unbreakable_will() -> bool:
	"""Trigger Unbreakable Will if available. Returns true if triggered."""
	if has_unbreakable_will:
		has_unbreakable_will = false
		current_health = max_health
		if health_bar:
			health_bar.set_health(current_health, max_health)
		emit_signal("health_changed", current_health, max_health)

		# Apply damage reduction for duration
		apply_damage_reduction(0.50, unbreakable_will_duration)

		# Visual feedback
		if JuiceManager:
			JuiceManager.shake_large()
			JuiceManager.update_player_health(1.0)

		# Update buff
		if active_buffs.has("unbreakable_will"):
			active_buffs.erase("unbreakable_will")
			emit_signal("buff_changed", active_buffs)

		return true
	return false

func set_feast_of_carnage(active: bool, duration: float) -> void:
	"""Set Feast of Carnage state (kill = heal + damage stack)."""
	has_feast_of_carnage = active
	feast_of_carnage_timer = duration if active else 0.0
	feast_of_carnage_stacks = 0
	if active:
		active_buffs["feast_of_carnage"] = {
			"timer": duration,
			"duration": duration,
			"name": "Carnage",
			"description": "Kills heal 10% + stack damage",
			"color": Color(0.8, 0.1, 0.1)  # Blood red
		}
	elif active_buffs.has("feast_of_carnage"):
		active_buffs.erase("feast_of_carnage")
	emit_signal("buff_changed", active_buffs)

func trigger_feast_of_carnage_kill() -> void:
	"""Trigger Feast of Carnage on kill."""
	if not has_feast_of_carnage or feast_of_carnage_timer <= 0:
		return

	# Heal 10% of max HP
	heal(max_health * 0.10)

	# Add damage stack
	feast_of_carnage_stacks += 1
	var bonus = feast_of_carnage_stacks * 10

	# Update buff display
	active_buffs["feast_of_carnage"] = {
		"timer": feast_of_carnage_timer,
		"duration": 12.0,
		"name": "Carnage x" + str(feast_of_carnage_stacks),
		"description": "+" + str(bonus) + "% Damage, heal on kill",
		"color": Color(0.8, 0.1, 0.1)
	}
	emit_signal("buff_changed", active_buffs)

func get_feast_of_carnage_multiplier() -> float:
	"""Get damage multiplier from Feast of Carnage stacks."""
	if not has_feast_of_carnage or feast_of_carnage_timer <= 0:
		return 1.0
	return 1.0 + (feast_of_carnage_stacks * 0.10)

func set_savage_instinct(active: bool, duration: float) -> void:
	"""Set Savage Instinct state (auto-execute low HP enemies)."""
	has_savage_instinct = active
	savage_instinct_timer = duration if active else 0.0
	if active:
		active_buffs["savage_instinct"] = {
			"timer": duration,
			"duration": duration,
			"name": "Savage",
			"description": "Execute enemies <30% HP",
			"color": Color(0.9, 0.5, 0.1)  # Orange
		}
	elif active_buffs.has("savage_instinct"):
		active_buffs.erase("savage_instinct")
	emit_signal("buff_changed", active_buffs)

func extend_savage_instinct(seconds: float) -> void:
	"""Extend Savage Instinct duration (on kill)."""
	if has_savage_instinct and savage_instinct_timer > 0:
		savage_instinct_timer += seconds
		if active_buffs.has("savage_instinct"):
			active_buffs["savage_instinct"].timer = savage_instinct_timer

func should_execute_enemy(enemy_hp_percent: float) -> bool:
	"""Check if enemy should be executed."""
	if has_savage_instinct and savage_instinct_timer > 0:
		return enemy_hp_percent < savage_instinct_threshold
	return false

func set_apex_predator(active: bool, duration: float, damage: float = 0.0) -> void:
	"""Set Apex Predator state (dash through marked enemies = big damage)."""
	has_apex_predator = active
	apex_predator_timer = duration if active else 0.0
	apex_predator_damage = damage
	if active:
		active_buffs["apex_predator"] = {
			"timer": duration,
			"duration": duration,
			"name": "Apex",
			"description": "Dash through = 500% Damage",
			"color": Color(1.0, 0.3, 0.0)  # Bright orange
		}
	elif active_buffs.has("apex_predator"):
		active_buffs.erase("apex_predator")
	emit_signal("buff_changed", active_buffs)

func get_apex_predator_damage() -> float:
	"""Get Apex Predator dash-through damage."""
	if has_apex_predator and apex_predator_timer > 0:
		return apex_predator_damage
	return 0.0

func set_time_rewind_state(pos: Vector2, hp: float, duration: float) -> void:
	"""Set Time Rewind state (Mage ultimate)."""
	time_rewind_active = true
	time_rewind_position = pos
	time_rewind_health = hp
	time_rewind_timer = duration
	time_rewind_triggered = false
	active_buffs["time_rewind"] = {
		"timer": duration,
		"duration": duration,
		"name": "Time Mark",
		"description": "Will return to marked spot",
		"color": Color(0.5, 0.3, 1.0)  # Purple
	}
	emit_signal("buff_changed", active_buffs)

func trigger_time_rewind() -> bool:
	"""Manually trigger Time Rewind. Returns true if triggered."""
	if time_rewind_active and not time_rewind_triggered:
		time_rewind_triggered = true
		global_position = time_rewind_position

		# Heal back to recorded HP if higher
		if time_rewind_health > current_health:
			var heal_amount = time_rewind_health - current_health
			heal(heal_amount)

		time_rewind_active = false
		if active_buffs.has("time_rewind"):
			active_buffs.erase("time_rewind")
			emit_signal("buff_changed", active_buffs)

		return true
	return false

func get_time_rewind_triggered() -> bool:
	"""Check if Time Rewind was manually triggered."""
	return time_rewind_triggered

func set_dragons_awakening(active: bool, duration: float, attack_range: float = 300.0, damage: float = 0.0) -> void:
	"""Set Dragon's Awakening state (attacks create shockwaves)."""
	has_dragons_awakening = active
	dragons_awakening_timer = duration if active else 0.0
	dragons_awakening_range = attack_range
	dragons_awakening_damage = damage
	if active:
		active_buffs["dragons_awakening"] = {
			"timer": duration,
			"duration": duration,
			"name": "Dragon",
			"description": "Attacks create shockwaves",
			"color": Color(1.0, 0.6, 0.2)  # Golden orange
		}
	elif active_buffs.has("dragons_awakening"):
		active_buffs.erase("dragons_awakening")
	emit_signal("buff_changed", active_buffs)

func should_create_shockwave() -> bool:
	"""Check if attack should create a shockwave."""
	return has_dragons_awakening and dragons_awakening_timer > 0

func get_shockwave_params() -> Dictionary:
	"""Get shockwave parameters for Dragon's Awakening."""
	return {
		"range": dragons_awakening_range,
		"damage": dragons_awakening_damage
	}

func set_perfect_harmony(active: bool, duration: float) -> void:
	"""Set Perfect Harmony state (every 4th attack = triple strike)."""
	has_perfect_harmony = active
	perfect_harmony_timer = duration if active else 0.0
	perfect_harmony_attack_count = 0
	if active:
		active_buffs["perfect_harmony"] = {
			"timer": duration,
			"duration": duration,
			"name": "Harmony",
			"description": "Every 4th attack = triple",
			"color": Color(0.8, 0.6, 1.0)  # Light purple
		}
	elif active_buffs.has("perfect_harmony"):
		active_buffs.erase("perfect_harmony")
	emit_signal("buff_changed", active_buffs)

func check_perfect_harmony_attack() -> bool:
	"""Check if this attack should trigger Perfect Harmony triple strike."""
	if not has_perfect_harmony or perfect_harmony_timer <= 0:
		return false

	perfect_harmony_attack_count += 1
	if perfect_harmony_attack_count >= 4:
		perfect_harmony_attack_count = 0
		return true
	return false

func cleanse_debuffs() -> void:
	"""Remove all negative status effects."""
	# Clear any debuff-related states here
	# For now, just provide visual feedback
	if JuiceManager:
		JuiceManager.shake_small()

func _update_ultimate_timers(delta: float) -> void:
	"""Update all ultimate ability timers."""
	# Damage reduction timer
	if damage_reduction_timer > 0:
		damage_reduction_timer -= delta
		if active_buffs.has("damage_reduction"):
			active_buffs["damage_reduction"].timer = damage_reduction_timer
		if damage_reduction_timer <= 0:
			damage_reduction_percent = 0.0
			if active_buffs.has("damage_reduction"):
				active_buffs.erase("damage_reduction")
				emit_signal("buff_changed", active_buffs)

	# Lifesteal timer
	if lifesteal_timer > 0:
		lifesteal_timer -= delta
		if active_buffs.has("lifesteal"):
			active_buffs["lifesteal"].timer = lifesteal_timer
		if lifesteal_timer <= 0:
			lifesteal_percent = 0.0
			if active_buffs.has("lifesteal"):
				active_buffs.erase("lifesteal")
				emit_signal("buff_changed", active_buffs)

	# Feast of Carnage timer
	if feast_of_carnage_timer > 0:
		feast_of_carnage_timer -= delta
		if active_buffs.has("feast_of_carnage"):
			active_buffs["feast_of_carnage"].timer = feast_of_carnage_timer
		if feast_of_carnage_timer <= 0:
			has_feast_of_carnage = false
			feast_of_carnage_stacks = 0
			if active_buffs.has("feast_of_carnage"):
				active_buffs.erase("feast_of_carnage")
				emit_signal("buff_changed", active_buffs)

	# Savage Instinct timer
	if savage_instinct_timer > 0:
		savage_instinct_timer -= delta
		if active_buffs.has("savage_instinct"):
			active_buffs["savage_instinct"].timer = savage_instinct_timer
		if savage_instinct_timer <= 0:
			has_savage_instinct = false
			if active_buffs.has("savage_instinct"):
				active_buffs.erase("savage_instinct")
				emit_signal("buff_changed", active_buffs)

	# Apex Predator timer
	if apex_predator_timer > 0:
		apex_predator_timer -= delta
		if active_buffs.has("apex_predator"):
			active_buffs["apex_predator"].timer = apex_predator_timer
		if apex_predator_timer <= 0:
			has_apex_predator = false
			if active_buffs.has("apex_predator"):
				active_buffs.erase("apex_predator")
				emit_signal("buff_changed", active_buffs)

	# Time Rewind timer
	if time_rewind_timer > 0:
		time_rewind_timer -= delta
		if active_buffs.has("time_rewind"):
			active_buffs["time_rewind"].timer = time_rewind_timer
		if time_rewind_timer <= 0:
			time_rewind_active = false
			if active_buffs.has("time_rewind"):
				active_buffs.erase("time_rewind")
				emit_signal("buff_changed", active_buffs)

	# Dragon's Awakening timer
	if dragons_awakening_timer > 0:
		dragons_awakening_timer -= delta
		if active_buffs.has("dragons_awakening"):
			active_buffs["dragons_awakening"].timer = dragons_awakening_timer
		if dragons_awakening_timer <= 0:
			has_dragons_awakening = false
			if active_buffs.has("dragons_awakening"):
				active_buffs.erase("dragons_awakening")
				emit_signal("buff_changed", active_buffs)

	# Perfect Harmony timer
	if perfect_harmony_timer > 0:
		perfect_harmony_timer -= delta
		if active_buffs.has("perfect_harmony"):
			active_buffs["perfect_harmony"].timer = perfect_harmony_timer
		if perfect_harmony_timer <= 0:
			has_perfect_harmony = false
			if active_buffs.has("perfect_harmony"):
				active_buffs.erase("perfect_harmony")
				emit_signal("buff_changed", active_buffs)
