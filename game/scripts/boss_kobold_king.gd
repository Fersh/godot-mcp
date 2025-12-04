extends BossBase

# Kobold King Boss - "The Hoard Master"
# Inspired by Hogger (WoW) and Treasure Goblins (Diablo)
# Attacks: Claw swipe, Command (war cry), Frenzy (multi-hit), Gold Barrage
# Tier: Normal (4x Minotaur power)

@export var gold_projectile_scene: PackedScene

# Attack damage values (4x Minotaur base)
@export var melee_damage: float = 88.0  # 22 * 4
@export var frenzy_damage: float = 35.0  # Lower per hit, but multi-hit
@export var gold_barrage_damage: float = 30.0  # Per gold coin

# Attack ranges
@export var melee_range: float = 110.0
@export var frenzy_range: float = 120.0
@export var gold_range: float = 300.0

# Frenzy attack settings
@export var frenzy_hits: int = 5
var frenzy_hit_count: int = 0
var frenzy_interval: float = 0.15

# Spritesheet config: 128x64 frames, 8 cols x 6 rows
const SPRITE_COLS: int = 8
const SPRITE_ROWS: int = 6

# Animation rows
const ANIM_IDLE: int = 0
const ANIM_MOVE: int = 1
const ANIM_ATTACK: int = 2
const ANIM_COMMAND: int = 3
const ANIM_DAMAGE: int = 4
const ANIM_DEATH: int = 5

# Frame counts per animation
const FRAMES = {
	0: 8,   # Idle
	1: 8,   # Move
	2: 8,   # Attack
	3: 8,   # Command (war cry)
	4: 6,   # Damage
	5: 8,   # Death
}

# Attack state
var current_attack_type: int = 0
var attack_windup_timer: float = 0.0
const WINDUP_DURATION: float = 0.7
var is_attack_animating: bool = false

# Frenzy state
var is_frenzying: bool = false
var frenzy_timer: float = 0.0

# War cry buff
var war_cry_active: bool = false
var war_cry_timer: float = 0.0
const WAR_CRY_DURATION: float = 8.0
const WAR_CRY_SPEED_BONUS: float = 0.4  # +40% speed
const WAR_CRY_DAMAGE_BONUS: float = 0.25  # +25% damage

func _setup_boss() -> void:
	boss_name = "KoboldKing"
	display_name = "THE HOARD MASTER"
	elite_name = "Kobold King"
	enemy_type = "kobold_king"

	# Boss stats (4x Minotaur: 1336.5 HP, 84 speed)
	speed = 120.0  # Fast and aggressive
	max_health = 5346.0  # 1336.5 * 4
	attack_damage = melee_damage
	base_damage = melee_damage
	attack_cooldown = 3.0
	windup_duration = WINDUP_DURATION
	animation_speed = 12.0  # Faster animations

	# Rewards (4x)
	xp_multiplier = 80.0
	coin_multiplier = 100.0  # Extra gold - he's the Hoard Master!
	guaranteed_drop = true

	# Enrage settings
	enrage_threshold = 0.30  # Earlier enrage
	enrage_damage_bonus = 0.35
	enrage_size_bonus = 0.15

	# Taunt settings
	taunt_on_spawn = true
	taunt_count = 1
	taunt_speed_multiplier = 1.5

	# Animation setup
	ROW_IDLE = ANIM_IDLE
	ROW_MOVE = ANIM_MOVE
	ROW_ATTACK = ANIM_ATTACK
	ROW_DAMAGE = ANIM_DAMAGE
	ROW_DEATH = ANIM_DEATH
	ROW_TAUNT = ANIM_COMMAND
	COLS_PER_ROW = SPRITE_COLS
	FRAMES_TAUNT = FRAMES[ANIM_COMMAND]

	FRAME_COUNTS = FRAMES.duplicate()

	current_health = max_health
	if health_bar:
		health_bar.visible = false

	# Define available attacks
	available_attacks = [
		{
			"type": AttackType.SPECIAL,
			"name": "war_cry",
			"range": 9999.0,  # Always available
			"cooldown": 12.0,
			"priority": 2
		},
		{
			"type": AttackType.SPECIAL,
			"name": "frenzy",
			"range": frenzy_range,
			"cooldown": 6.0,
			"priority": 4
		},
		{
			"type": AttackType.RANGED,
			"name": "gold_barrage",
			"range": gold_range,
			"cooldown": 5.0,
			"priority": 5
		},
		{
			"type": AttackType.MELEE,
			"name": "melee",
			"range": melee_range,
			"cooldown": 1.5,
			"priority": 8
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"war_cry":
			_start_war_cry()
		"frenzy":
			_start_frenzy()
		"gold_barrage":
			_start_gold_barrage()
		"melee":
			_start_melee_attack()

func _start_war_cry() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.8
	current_attack_type = ANIM_COMMAND
	animation_frame = 0.0
	current_row = ANIM_COMMAND

	# Face player
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _start_frenzy() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.5  # Quick start
	current_attack_type = ANIM_ATTACK
	animation_frame = 0.0
	current_row = ANIM_ATTACK
	frenzy_hit_count = 0

	show_warning()

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _start_gold_barrage() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.6
	current_attack_type = ANIM_ATTACK
	animation_frame = 0.0
	current_row = ANIM_ATTACK

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _start_melee_attack() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.6
	current_attack_type = ANIM_ATTACK
	animation_frame = 0.0
	current_row = ANIM_ATTACK

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _physics_process(delta: float) -> void:
	if is_dying:
		_process_death_animation(delta)
		return

	# Update war cry timer
	if war_cry_active:
		war_cry_timer -= delta
		if war_cry_timer <= 0:
			_end_war_cry()

	# Handle frenzy
	if is_frenzying:
		_process_frenzy(delta)
		return

	# Handle attack windup
	if is_winding_up:
		_process_windup(delta)
		return

	if is_attack_animating:
		return

	super._physics_process(delta)

func _process_windup(delta: float) -> void:
	attack_windup_timer -= delta

	animation_frame += animation_speed * 0.5 * delta
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var windup_frames = int(max_frames * 0.4)

	if animation_frame > windup_frames:
		animation_frame = float(windup_frames)

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = current_row * COLS_PER_ROW + frame_index

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

	if attack_windup_timer <= 0:
		is_winding_up = false
		_execute_current_attack()

func _execute_current_attack() -> void:
	hide_warning()

	# Check what attack we were winding up for
	# We need to track which attack triggered this
	if current_attack_type == ANIM_COMMAND:
		_execute_war_cry()
		_play_attack_followthrough()
	else:
		# Could be frenzy, gold_barrage, or melee - check context
		if frenzy_hit_count == 0 and _is_frenzy_attack():
			_begin_frenzy()
		elif _is_gold_attack():
			_execute_gold_barrage()
			_play_attack_followthrough()
		else:
			_execute_melee()
			_play_attack_followthrough()

var pending_attack_name: String = ""

func _is_frenzy_attack() -> bool:
	return pending_attack_name == "frenzy"

func _is_gold_attack() -> bool:
	return pending_attack_name == "gold_barrage"

# Override to track pending attack
func _select_attack() -> Dictionary:
	var attack = super._select_attack()
	if attack.size() > 0:
		pending_attack_name = attack.get("name", "")
	return attack

func _execute_war_cry() -> void:
	war_cry_active = true
	war_cry_timer = WAR_CRY_DURATION

	# Boost stats
	speed *= (1.0 + WAR_CRY_SPEED_BONUS)
	attack_damage = base_damage * (1.0 + WAR_CRY_DAMAGE_BONUS)
	if is_enraged:
		attack_damage *= (1.0 + enrage_damage_bonus)

	# Visual feedback - golden glow
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.5, 1.3, 0.8, 1.0), 0.2)

	# Screen shake
	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false

func _end_war_cry() -> void:
	war_cry_active = false

	# Reset stats
	speed = 120.0
	attack_damage = base_damage
	if is_enraged:
		attack_damage *= (1.0 + enrage_damage_bonus)

	# Reset visual
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)

func _begin_frenzy() -> void:
	is_frenzying = true
	frenzy_hit_count = 0
	frenzy_timer = 0.0

	# Rush toward player
	if player and is_instance_valid(player):
		velocity = (player.global_position - global_position).normalized() * speed * 1.5

func _process_frenzy(delta: float) -> void:
	frenzy_timer += delta

	# Animate rapidly
	animation_frame += animation_speed * 2.0 * delta
	var max_frames = FRAME_COUNTS.get(ANIM_ATTACK, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ANIM_ATTACK * COLS_PER_ROW + frame_index

	# Deal damage at intervals
	if frenzy_timer >= frenzy_interval:
		frenzy_timer = 0.0
		_frenzy_hit()
		frenzy_hit_count += 1

		if frenzy_hit_count >= frenzy_hits:
			_end_frenzy()
			return

	# Keep moving toward player
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed * 1.5
		sprite.flip_h = dir.x < 0
		move_and_slide()

func _frenzy_hit() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= frenzy_range:
			var damage = frenzy_damage
			if war_cry_active:
				damage *= (1.0 + WAR_CRY_DAMAGE_BONUS)
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

			if JuiceManager:
				JuiceManager.shake_small()

func _end_frenzy() -> void:
	is_frenzying = false
	velocity = Vector2.ZERO
	can_attack = false
	current_row = ROW_IDLE

	if JuiceManager:
		JuiceManager.shake_medium()

func _execute_gold_barrage() -> void:
	# Fire multiple gold projectiles
	if player and is_instance_valid(player):
		var base_dir = (player.global_position - global_position).normalized()

		for i in range(5):  # 5 gold coins
			var angle_offset = (i - 2) * 0.2  # Spread pattern
			var dir = base_dir.rotated(angle_offset)
			_spawn_gold_projectile(dir)

	if JuiceManager:
		JuiceManager.shake_small()

	can_attack = false

func _spawn_gold_projectile(direction: Vector2) -> void:
	var projectile_scene = gold_projectile_scene
	if projectile_scene == null:
		projectile_scene = load("res://scenes/enemy_projectile.tscn")

	if projectile_scene == null:
		# Fallback: direct damage if close enough
		return

	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position + direction * 30
	projectile.direction = direction
	if projectile.has_method("set_damage"):
		var damage = gold_barrage_damage
		if war_cry_active:
			damage *= (1.0 + WAR_CRY_DAMAGE_BONUS)
		if is_enraged:
			damage *= (1.0 + enrage_damage_bonus)
		projectile.set_damage(damage)

	# Make it golden colored
	if projectile.has_node("Sprite2D"):
		projectile.get_node("Sprite2D").modulate = Color(1.0, 0.85, 0.2, 1.0)

	get_parent().add_child(projectile)

func _execute_melee() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= melee_range:
			var damage = melee_damage
			if war_cry_active:
				damage *= (1.0 + WAR_CRY_DAMAGE_BONUS)
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false

func _play_attack_followthrough() -> void:
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var start_frame = int(max_frames * 0.4)
	animation_frame = start_frame

	is_attack_animating = true

	var tween = create_tween()
	var remaining_frames = max_frames - start_frame
	var duration = remaining_frames / animation_speed

	tween.tween_method(_update_attack_frame, float(start_frame), float(max_frames - 1), duration)
	tween.tween_callback(_on_attack_complete)

func _update_attack_frame(frame: float) -> void:
	var max_frames = FRAME_COUNTS.get(current_attack_type, 8)
	var frame_index = clampi(int(frame), 0, max_frames - 1)
	sprite.frame = current_row * COLS_PER_ROW + frame_index

func _on_attack_complete() -> void:
	is_attack_animating = false
	can_attack = false
	current_row = ROW_IDLE

func _process_death_animation(delta: float) -> void:
	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(ROW_DEATH, 8)

	if animation_frame >= max_frames - 1:
		animation_frame = float(max_frames - 1)
		if not death_processed:
			death_processed = true
			spawn_gold_coin()
			queue_free()

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ROW_DEATH * COLS_PER_ROW + frame_index

var death_processed: bool = false

func update_animation(delta: float, new_row: int, direction: Vector2) -> void:
	if current_row != new_row:
		current_row = new_row
		animation_frame = 0.0

	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = fmod(animation_frame, float(max_frames))

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = current_row * COLS_PER_ROW + frame_index

func _process_taunt(delta: float) -> void:
	animation_frame += animation_speed * taunt_speed_multiplier * delta
	var max_frames = FRAMES_TAUNT

	if animation_frame >= max_frames:
		animation_frame = fmod(animation_frame, float(max_frames))
		taunt_plays_remaining -= 1

		if taunt_plays_remaining <= 0:
			is_taunting = false
			can_attack = true
			return

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ROW_TAUNT * COLS_PER_ROW + frame_index

# Override to drop extra gold
func spawn_gold_coin() -> void:
	if gold_coin_scene == null:
		return

	# Kobold King drops LOTS of gold
	var drop_mult = 1.0
	if CurseEffects:
		drop_mult = CurseEffects.get_gold_drop_multiplier()

	var coin_count = int(coin_multiplier * 3 * drop_mult)  # 3x normal boss drops
	for i in range(max(5, coin_count)):
		var coin = gold_coin_scene.instantiate()
		var offset = Vector2(randf_range(-80, 80), randf_range(-80, 80))
		coin.global_position = global_position + offset
		get_parent().add_child(coin)

	if guaranteed_drop:
		_drop_boss_item()
