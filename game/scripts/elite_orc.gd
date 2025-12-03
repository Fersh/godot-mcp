extends EliteBase

# Elite Orc - "The Supervisor" - A burly orc middle manager
# Three attack types:
# 1. Heavy Swing - Close range powerful melee sweep
# 2. Shield Bash - Charge forward and knock back player
# 3. War Cry - AOE damage + briefly stuns player, buffs nearby enemies
#
# Orc Sprite Sheet: 8 cols x 8 rows, 64x64 per frame
# Row 0: Idle (4 frames)
# Row 2: Move (8 frames)
# Row 5: Attack (8 frames)
# Row 6: Damage (3 frames)
# Row 7: Death (6 frames)

# Attack-specific stats
@export var heavy_swing_damage: float = 22.0
@export var heavy_swing_range: float = 90.0
@export var heavy_swing_aoe_radius: float = 110.0

@export var shield_bash_damage: float = 18.0
@export var shield_bash_range: float = 250.0
@export var charge_speed: float = 350.0

@export var war_cry_damage: float = 15.0
@export var war_cry_range: float = 200.0
@export var war_cry_telegraph_time: float = 1.0
@export var war_cry_buff_duration: float = 5.0
@export var war_cry_buff_range: float = 300.0

# Attack state
var heavy_swing_active: bool = false
var heavy_swing_windup_timer: float = 0.0
const HEAVY_SWING_WINDUP: float = 0.6

var shield_bash_active: bool = false
var shield_bash_charging: bool = false
var shield_bash_windup_timer: float = 0.0
const SHIELD_BASH_WINDUP: float = 0.4
var charge_direction: Vector2 = Vector2.ZERO
var charge_distance_traveled: float = 0.0
var max_charge_distance: float = 300.0

var war_cry_telegraphing: bool = false
var war_cry_telegraph_timer: float = 0.0
var war_cry_warning_label: Label = null
var war_cry_warning_tween: Tween = null
var war_cry_indicator: Node2D = null
var war_cry_indicator_tween: Tween = null

func _setup_elite() -> void:
	elite_name = "The Supervisor"
	enemy_type = "orc_supervisor"

	# Stats - balanced bruiser
	speed = 55.0
	max_health = 700.0
	attack_damage = heavy_swing_damage
	attack_cooldown = 1.0
	windup_duration = 0.5
	animation_speed = 8.0

	# Orc spritesheet: 8 cols x 8 rows
	ROW_IDLE = 0
	ROW_MOVE = 2
	ROW_ATTACK = 5
	ROW_DAMAGE = 6
	ROW_DEATH = 7
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,   # IDLE
		2: 8,   # MOVE
		5: 8,   # ATTACK
		6: 3,   # DAMAGE
		7: 6,   # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up the sprite for elite size
	if sprite:
		sprite.scale = Vector2(3.0, 3.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "heavy_swing",
			"range": heavy_swing_range,
			"cooldown": 3.0,
			"priority": 5
		},
		{
			"type": AttackType.RANGED,
			"name": "shield_bash",
			"range": shield_bash_range,
			"cooldown": 5.0,
			"priority": 4
		},
		{
			"type": AttackType.SPECIAL,
			"name": "war_cry",
			"range": war_cry_range,
			"cooldown": 12.0,
			"priority": 6
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"heavy_swing":
			_start_heavy_swing()
		"shield_bash":
			_start_shield_bash()
		"war_cry":
			_start_war_cry()

func _start_heavy_swing() -> void:
	heavy_swing_active = true
	heavy_swing_windup_timer = HEAVY_SWING_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_shield_bash() -> void:
	shield_bash_active = true
	shield_bash_windup_timer = SHIELD_BASH_WINDUP
	charge_distance_traveled = 0.0
	if player and is_instance_valid(player):
		charge_direction = (player.global_position - global_position).normalized()
	update_animation(0, ROW_MOVE, charge_direction)
	animation_frame = 0

	# Show warning
	show_warning()

func _start_war_cry() -> void:
	show_warning()
	is_using_special = true

	war_cry_telegraphing = true
	war_cry_telegraph_timer = war_cry_telegraph_time
	special_timer = war_cry_telegraph_time + 0.5

	_show_war_cry_warning()
	_show_war_cry_indicator()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_war_cry() -> void:
	war_cry_telegraphing = false
	_hide_war_cry_warning()
	_clear_war_cry_indicator()

	# Deal AOE damage to player
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= war_cry_range:
			if player.has_method("take_damage"):
				player.take_damage(war_cry_damage)

	# Buff nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == self:
			continue
		if not is_instance_valid(enemy):
			continue
		if enemy.is_dying:
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance <= war_cry_buff_range:
			_apply_war_cry_buff(enemy)

	# Screen shake
	if JuiceManager:
		JuiceManager.shake_large()

func _apply_war_cry_buff(enemy: Node) -> void:
	# Temporarily increase enemy speed and damage
	if "speed" in enemy:
		var original_speed = enemy.speed
		enemy.speed *= 1.3
		# Create timer to restore speed
		var timer = get_tree().create_timer(war_cry_buff_duration)
		timer.timeout.connect(func():
			if is_instance_valid(enemy) and "speed" in enemy:
				enemy.speed = original_speed
		)

	# Visual feedback - brief red tint
	if enemy.has_node("Sprite"):
		var enemy_sprite = enemy.get_node("Sprite")
		var original_mod = enemy_sprite.modulate
		enemy_sprite.modulate = Color(1.5, 0.8, 0.8)
		var tween = create_tween()
		tween.tween_property(enemy_sprite, "modulate", original_mod, 0.5)

func _show_war_cry_warning() -> void:
	if war_cry_warning_label == null:
		war_cry_warning_label = Label.new()
		war_cry_warning_label.text = "WAR CRY!"
		war_cry_warning_label.add_theme_font_size_override("font_size", 16)
		war_cry_warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		war_cry_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		war_cry_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		war_cry_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		war_cry_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		war_cry_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			war_cry_warning_label.add_theme_font_override("font", pixel_font)

		add_child(war_cry_warning_label)

	war_cry_warning_label.position = Vector2(-40, -100)
	war_cry_warning_label.visible = true

	if war_cry_warning_tween and war_cry_warning_tween.is_valid():
		war_cry_warning_tween.kill()

	war_cry_warning_tween = create_tween().set_loops()
	war_cry_warning_tween.tween_property(war_cry_warning_label, "modulate:a", 0.5, 0.15)
	war_cry_warning_tween.tween_property(war_cry_warning_label, "modulate:a", 1.0, 0.15)

func _hide_war_cry_warning() -> void:
	if war_cry_warning_tween and war_cry_warning_tween.is_valid():
		war_cry_warning_tween.kill()
		war_cry_warning_tween = null
	if war_cry_warning_label:
		war_cry_warning_label.visible = false

func _show_war_cry_indicator() -> void:
	_clear_war_cry_indicator()

	war_cry_indicator = Node2D.new()
	war_cry_indicator.global_position = global_position
	war_cry_indicator.z_index = -1

	var circle = ColorRect.new()
	var size = war_cry_range * 2
	circle.size = Vector2(size, size)
	circle.position = Vector2(-war_cry_range, -war_cry_range)
	circle.color = Color(1.0, 0.3, 0.3, 0.3)
	war_cry_indicator.add_child(circle)

	get_parent().add_child(war_cry_indicator)

	if war_cry_indicator_tween and war_cry_indicator_tween.is_valid():
		war_cry_indicator_tween.kill()

	war_cry_indicator_tween = create_tween().set_loops()
	war_cry_indicator_tween.tween_property(circle, "color:a", 0.15, 0.2)
	war_cry_indicator_tween.tween_property(circle, "color:a", 0.4, 0.2)

func _clear_war_cry_indicator() -> void:
	if war_cry_indicator_tween and war_cry_indicator_tween.is_valid():
		war_cry_indicator_tween.kill()
		war_cry_indicator_tween = null

	if war_cry_indicator and is_instance_valid(war_cry_indicator):
		war_cry_indicator.queue_free()
	war_cry_indicator = null

func _physics_process(delta: float) -> void:
	# Handle heavy swing windup
	if heavy_swing_active:
		heavy_swing_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 8)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if heavy_swing_windup_timer <= 0:
			_execute_heavy_swing()
			heavy_swing_active = false
			can_attack = false
		return

	# Handle shield bash
	if shield_bash_active:
		shield_bash_windup_timer -= delta

		if shield_bash_windup_timer <= 0 and not shield_bash_charging:
			shield_bash_charging = true
			hide_warning()

		if shield_bash_charging:
			# Charge forward
			velocity = charge_direction * charge_speed
			move_and_slide()
			charge_distance_traveled += charge_speed * delta

			animation_frame += animation_speed * 1.5 * delta
			var max_frames = FRAME_COUNTS.get(ROW_MOVE, 8)
			sprite.frame = ROW_MOVE * COLS_PER_ROW + int(animation_frame) % max_frames
			if charge_direction.x != 0:
				sprite.flip_h = charge_direction.x < 0

			# Check if hit player
			if player and is_instance_valid(player):
				var dist = global_position.distance_to(player.global_position)
				if dist < 60:
					_execute_shield_bash_hit()
					shield_bash_active = false
					shield_bash_charging = false
					can_attack = false
					return

			# Check if charge complete
			if charge_distance_traveled >= max_charge_distance:
				shield_bash_active = false
				shield_bash_charging = false
				can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if war_cry_telegraphing:
		war_cry_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * 0.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 8)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		# Update indicator position
		if war_cry_indicator and is_instance_valid(war_cry_indicator):
			war_cry_indicator.global_position = global_position

		if war_cry_telegraph_timer <= 0:
			_execute_war_cry()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_war_cry()

func _end_war_cry() -> void:
	war_cry_telegraphing = false
	hide_warning()
	_hide_war_cry_warning()
	_clear_war_cry_indicator()

func _execute_heavy_swing() -> void:
	# AOE damage around orc
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= heavy_swing_aoe_radius:
			if player.has_method("take_damage"):
				player.take_damage(heavy_swing_damage)
				# Trigger vampiric healing if applicable
				_on_elite_attack_hit(heavy_swing_damage)

	if JuiceManager:
		JuiceManager.shake_medium()

func _execute_shield_bash_hit() -> void:
	if player and is_instance_valid(player):
		if player.has_method("take_damage"):
			player.take_damage(shield_bash_damage)
			_on_elite_attack_hit(shield_bash_damage)

		# Knockback player
		if player.has_method("apply_knockback"):
			player.apply_knockback(charge_direction * 200)

	if JuiceManager:
		JuiceManager.shake_large()

func die() -> void:
	_end_war_cry()
	super.die()
