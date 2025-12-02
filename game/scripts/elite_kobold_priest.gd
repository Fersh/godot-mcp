extends EliteBase

# Elite Kobold Priest - "The Grand Poobah" - Supreme spiritual leader
# Three attack types:
# 1. Holy Smite - Powerful ranged magic attack
# 2. Mass Heal - Heals ALL nearby enemies significantly
# 3. Divine Shield - Grants temporary invulnerability to self
#
# Kobold Priest Sprite Sheet: 8 cols x 5 rows
# Row 0: Idle (4 frames)
# Row 1: Move (8 frames)
# Row 2: Attack (8 frames)
# Row 3: Hurt (4 frames)
# Row 4: Death (7 frames)

@export var spell_projectile_scene: PackedScene

# Attack-specific stats
@export var holy_smite_damage: float = 18.0
@export var holy_smite_range: float = 300.0
@export var holy_smite_speed: float = 180.0

@export var mass_heal_range: float = 350.0
@export var mass_heal_percent: float = 0.40  # Heal 40% of max HP
@export var mass_heal_telegraph_time: float = 1.5

@export var divine_shield_duration: float = 4.0
@export var divine_shield_telegraph_time: float = 0.8

# Preferred range for ranged combat
var preferred_range: float = 180.0

# Attack state
var holy_smite_active: bool = false
var holy_smite_windup_timer: float = 0.0
const HOLY_SMITE_WINDUP: float = 0.5

var mass_heal_telegraphing: bool = false
var mass_heal_telegraph_timer: float = 0.0
var mass_heal_warning_label: Label = null
var mass_heal_warning_tween: Tween = null
var mass_heal_indicator: Node2D = null
var mass_heal_indicator_tween: Tween = null

var divine_shield_active: bool = false
var divine_shield_timer: float = 0.0
var divine_shield_telegraphing: bool = false
var divine_shield_telegraph_timer: float = 0.0
var divine_shield_warning_label: Label = null
var divine_shield_warning_tween: Tween = null
var shield_visual: Node2D = null
var shield_visual_tween: Tween = null

func _setup_elite() -> void:
	elite_name = "The Grand Poobah"
	enemy_type = "kobold_priest_elite"

	# Stats - support caster
	speed = 45.0
	max_health = 600.0
	attack_damage = holy_smite_damage
	attack_cooldown = 1.5
	windup_duration = 0.5
	animation_speed = 10.0

	# Kobold Priest spritesheet: 8 cols x 5 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 3
	ROW_DEATH = 4
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,   # IDLE
		1: 8,   # MOVE
		2: 8,   # ATTACK
		3: 4,   # HURT/DAMAGE
		4: 7,   # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up the sprite for elite size
	if sprite:
		sprite.scale = Vector2(3.5, 3.5)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.RANGED,
			"name": "holy_smite",
			"range": holy_smite_range,
			"cooldown": 3.5,
			"priority": 4
		},
		{
			"type": AttackType.SPECIAL,
			"name": "mass_heal",
			"range": mass_heal_range,
			"cooldown": 12.0,
			"priority": 6
		},
		{
			"type": AttackType.SPECIAL,
			"name": "divine_shield",
			"range": 999.0,  # Self-cast, always in range
			"cooldown": 18.0,
			"priority": 5
		}
	]

# Override behavior for ranged combat - maintain distance
func _process_behavior(delta: float) -> void:
	# Handle divine shield
	if divine_shield_active:
		divine_shield_timer -= delta
		if divine_shield_timer <= 0:
			_end_divine_shield()

	if is_using_special or divine_shield_telegraphing:
		_process_special_attack(delta)
		return

	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position)
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# Select best attack based on distance and cooldowns
		var best_attack = _select_best_attack(distance)

		# Check if any enemies are hurt - prioritize mass heal
		var should_heal = _check_if_should_heal()
		if should_heal and attack_cooldowns.get("mass_heal", 0) <= 0:
			best_attack = available_attacks[1]  # Mass heal

		if best_attack.is_empty():
			# No attack available, maintain preferred range
			if distance < preferred_range * 0.6:
				velocity = -dir_normalized * speed
				move_and_slide()
				update_animation(delta, ROW_MOVE, -dir_normalized)
			elif distance > preferred_range * 1.5:
				velocity = dir_normalized * speed
				move_and_slide()
				update_animation(delta, ROW_MOVE, dir_normalized)
			else:
				velocity = Vector2.ZERO
				update_animation(delta, ROW_IDLE, dir_normalized)
		elif best_attack.name != "divine_shield" and distance > best_attack.range:
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			velocity = Vector2.ZERO
			if can_attack and attack_cooldowns[best_attack.name] <= 0:
				current_attack = best_attack
				_start_elite_attack(best_attack)
			else:
				update_animation(delta, ROW_IDLE, dir_normalized)
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func _check_if_should_heal() -> bool:
	# Check if there are hurt enemies nearby worth healing
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hurt_count = 0

	for enemy in enemies:
		if enemy == self:
			continue
		if not is_instance_valid(enemy):
			continue
		if enemy.is_dying:
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance > mass_heal_range:
			continue

		var health_percent = enemy.current_health / enemy.max_health
		if health_percent < 0.7:
			hurt_count += 1

	return hurt_count >= 2  # Heal if 2+ enemies are hurt

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"holy_smite":
			_start_holy_smite()
		"mass_heal":
			_start_mass_heal()
		"divine_shield":
			_start_divine_shield()

func _start_holy_smite() -> void:
	holy_smite_active = true
	holy_smite_windup_timer = HOLY_SMITE_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_mass_heal() -> void:
	show_warning()
	is_using_special = true

	mass_heal_telegraphing = true
	mass_heal_telegraph_timer = mass_heal_telegraph_time
	special_timer = mass_heal_telegraph_time + 0.5

	_show_mass_heal_warning()
	_show_mass_heal_indicator()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_divine_shield() -> void:
	show_warning()
	divine_shield_telegraphing = true
	divine_shield_telegraph_timer = divine_shield_telegraph_time

	_show_divine_shield_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_mass_heal() -> void:
	mass_heal_telegraphing = false
	_hide_mass_heal_warning()
	_clear_mass_heal_indicator()

	# Heal ALL nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	var healed_count = 0

	for enemy in enemies:
		if enemy == self:
			continue
		if not is_instance_valid(enemy):
			continue
		if enemy.is_dying:
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance > mass_heal_range:
			continue

		# Calculate heal amount
		var heal_amount = enemy.max_health * mass_heal_percent
		enemy.current_health = min(enemy.current_health + heal_amount, enemy.max_health)

		if enemy.health_bar:
			enemy.health_bar.set_health(enemy.current_health, enemy.max_health)

		# Visual effect on healed enemy
		_spawn_heal_effect(enemy)
		healed_count += 1

	# Also heal self
	var self_heal = max_health * mass_heal_percent * 0.5  # Less self-heal
	current_health = min(current_health + self_heal, max_health)
	elite_health_changed.emit(current_health, max_health)
	_spawn_heal_effect(self)

	if JuiceManager:
		JuiceManager.shake_small()

func _spawn_heal_effect(target: Node2D) -> void:
	# Green glow effect
	if target.has_node("Sprite"):
		var target_sprite = target.get_node("Sprite")
		var original_mod = target_sprite.modulate
		target_sprite.modulate = Color(0.5, 1.5, 0.5)
		var tween = create_tween()
		tween.tween_property(target_sprite, "modulate", original_mod, 0.4)

func _execute_divine_shield() -> void:
	divine_shield_telegraphing = false
	_hide_divine_shield_warning()
	hide_warning()

	divine_shield_active = true
	divine_shield_timer = divine_shield_duration

	_show_shield_visual()

	if JuiceManager:
		JuiceManager.shake_small()

func _end_divine_shield() -> void:
	divine_shield_active = false
	_hide_shield_visual()

func _show_shield_visual() -> void:
	_hide_shield_visual()

	shield_visual = Node2D.new()
	shield_visual.z_index = 10

	# Create golden shield circle
	var shield_circle = ColorRect.new()
	shield_circle.size = Vector2(100, 100)
	shield_circle.position = Vector2(-50, -50)
	shield_circle.color = Color(1.0, 0.9, 0.3, 0.4)
	shield_visual.add_child(shield_circle)

	add_child(shield_visual)

	# Pulsing effect
	if shield_visual_tween and shield_visual_tween.is_valid():
		shield_visual_tween.kill()

	shield_visual_tween = create_tween().set_loops()
	shield_visual_tween.tween_property(shield_circle, "color:a", 0.2, 0.3)
	shield_visual_tween.tween_property(shield_circle, "color:a", 0.5, 0.3)

func _hide_shield_visual() -> void:
	if shield_visual_tween and shield_visual_tween.is_valid():
		shield_visual_tween.kill()
		shield_visual_tween = null

	if shield_visual and is_instance_valid(shield_visual):
		shield_visual.queue_free()
	shield_visual = null

func _show_mass_heal_warning() -> void:
	if mass_heal_warning_label == null:
		mass_heal_warning_label = Label.new()
		mass_heal_warning_label.text = "MASS HEAL!"
		mass_heal_warning_label.add_theme_font_size_override("font_size", 14)
		mass_heal_warning_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))
		mass_heal_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		mass_heal_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		mass_heal_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		mass_heal_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mass_heal_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			mass_heal_warning_label.add_theme_font_override("font", pixel_font)

		add_child(mass_heal_warning_label)

	mass_heal_warning_label.position = Vector2(-50, -90)
	mass_heal_warning_label.visible = true

	if mass_heal_warning_tween and mass_heal_warning_tween.is_valid():
		mass_heal_warning_tween.kill()

	mass_heal_warning_tween = create_tween().set_loops()
	mass_heal_warning_tween.tween_property(mass_heal_warning_label, "modulate:a", 0.5, 0.15)
	mass_heal_warning_tween.tween_property(mass_heal_warning_label, "modulate:a", 1.0, 0.15)

func _hide_mass_heal_warning() -> void:
	if mass_heal_warning_tween and mass_heal_warning_tween.is_valid():
		mass_heal_warning_tween.kill()
		mass_heal_warning_tween = null
	if mass_heal_warning_label:
		mass_heal_warning_label.visible = false

func _show_mass_heal_indicator() -> void:
	_clear_mass_heal_indicator()

	mass_heal_indicator = Node2D.new()
	mass_heal_indicator.global_position = global_position
	mass_heal_indicator.z_index = -1

	var circle = ColorRect.new()
	var size = mass_heal_range * 2
	circle.size = Vector2(size, size)
	circle.position = Vector2(-mass_heal_range, -mass_heal_range)
	circle.color = Color(0.3, 1.0, 0.5, 0.2)
	mass_heal_indicator.add_child(circle)

	get_parent().add_child(mass_heal_indicator)

	if mass_heal_indicator_tween and mass_heal_indicator_tween.is_valid():
		mass_heal_indicator_tween.kill()

	mass_heal_indicator_tween = create_tween().set_loops()
	mass_heal_indicator_tween.tween_property(circle, "color:a", 0.1, 0.25)
	mass_heal_indicator_tween.tween_property(circle, "color:a", 0.3, 0.25)

func _clear_mass_heal_indicator() -> void:
	if mass_heal_indicator_tween and mass_heal_indicator_tween.is_valid():
		mass_heal_indicator_tween.kill()
		mass_heal_indicator_tween = null

	if mass_heal_indicator and is_instance_valid(mass_heal_indicator):
		mass_heal_indicator.queue_free()
	mass_heal_indicator = null

func _show_divine_shield_warning() -> void:
	if divine_shield_warning_label == null:
		divine_shield_warning_label = Label.new()
		divine_shield_warning_label.text = "SHIELD!"
		divine_shield_warning_label.add_theme_font_size_override("font_size", 14)
		divine_shield_warning_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
		divine_shield_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		divine_shield_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		divine_shield_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		divine_shield_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		divine_shield_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			divine_shield_warning_label.add_theme_font_override("font", pixel_font)

		add_child(divine_shield_warning_label)

	divine_shield_warning_label.position = Vector2(-35, -90)
	divine_shield_warning_label.visible = true

	if divine_shield_warning_tween and divine_shield_warning_tween.is_valid():
		divine_shield_warning_tween.kill()

	divine_shield_warning_tween = create_tween().set_loops()
	divine_shield_warning_tween.tween_property(divine_shield_warning_label, "modulate:a", 0.5, 0.12)
	divine_shield_warning_tween.tween_property(divine_shield_warning_label, "modulate:a", 1.0, 0.12)

func _hide_divine_shield_warning() -> void:
	if divine_shield_warning_tween and divine_shield_warning_tween.is_valid():
		divine_shield_warning_tween.kill()
		divine_shield_warning_tween = null
	if divine_shield_warning_label:
		divine_shield_warning_label.visible = false

func _physics_process(delta: float) -> void:
	# Handle holy smite windup
	if holy_smite_active:
		holy_smite_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 8)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if holy_smite_windup_timer <= 0:
			_execute_holy_smite()
			holy_smite_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	# Handle mass heal telegraph
	if mass_heal_telegraphing:
		mass_heal_telegraph_timer -= delta

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
		if mass_heal_indicator and is_instance_valid(mass_heal_indicator):
			mass_heal_indicator.global_position = global_position

		if mass_heal_telegraph_timer <= 0:
			_execute_mass_heal()
		return

	# Handle divine shield telegraph
	if divine_shield_telegraphing:
		divine_shield_telegraph_timer -= delta

		# Golden glow during telegraph
		if sprite:
			var pulse = 0.7 + sin(Time.get_ticks_msec() * 0.02) * 0.3
			sprite.modulate = Color(1.0 + pulse * 0.3, 0.9 + pulse * 0.2, 0.3 + pulse * 0.3)

		if divine_shield_telegraph_timer <= 0:
			if sprite:
				sprite.modulate = Color(1, 1, 1)
			_execute_divine_shield()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_mass_heal()

func _end_mass_heal() -> void:
	mass_heal_telegraphing = false
	hide_warning()
	_hide_mass_heal_warning()
	_clear_mass_heal_indicator()

func _execute_holy_smite() -> void:
	if not player or not is_instance_valid(player):
		return

	var direction = (player.global_position - global_position).normalized()

	# Use spell projectile scene or fall back to kobold spell
	var proj_scene = spell_projectile_scene
	if proj_scene == null:
		proj_scene = load("res://scenes/kobold_spell.tscn")
	if proj_scene == null:
		proj_scene = load("res://scenes/enemy_projectile.tscn")

	if proj_scene:
		var proj = proj_scene.instantiate()
		proj.global_position = global_position + direction * 40
		if "direction" in proj:
			proj.direction = direction
		if "speed" in proj:
			proj.speed = holy_smite_speed
		if "damage" in proj:
			proj.damage = holy_smite_damage

		# Golden holy tint
		if proj.has_node("Sprite2D"):
			proj.get_node("Sprite2D").modulate = Color(1.0, 0.9, 0.4)

		get_parent().add_child(proj)

# Override take_damage for divine shield
func take_damage(amount: float, is_critical: bool = false) -> void:
	if divine_shield_active:
		# Immune during divine shield - show visual feedback
		if sprite:
			var original_mod = sprite.modulate
			sprite.modulate = Color(1.5, 1.3, 0.5)
			var tween = create_tween()
			tween.tween_property(sprite, "modulate", original_mod, 0.15)
		return

	super.take_damage(amount, is_critical)

func die() -> void:
	_end_mass_heal()
	_end_divine_shield()
	_hide_divine_shield_warning()
	super.die()
