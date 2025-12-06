extends Node2D

# Skeleton minion for Summoner's Aid ability
# Uses the same animation system as enemy_skeleton.gd

var owner_player: Node2D = null
var health: float = 30.0
var damage: float = 10.0
var speed: float = 150.0
var attack_range: float = 40.0
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var lifetime: float = 5.0  # 5 second duration
var current_target: Node2D = null

var sprite: Sprite2D = null

# Animation system (matching enemy_skeleton.gd)
var animation_speed: float = 10.0
var animation_frame: float = 0.0
var current_row: int = 0
var is_dying: bool = false
var is_attacking: bool = false
var attack_anim_timer: float = 0.0

# Sprite sheet layout (same as SkeletalWarrior_Sprites.png)
# Row 0: Idle (10 frames)
# Row 1: Walk (5 frames)
# Row 2: Attack (10 frames)
# Row 3: Damaged (5 frames)
# Row 4: Death (10 frames)
const ROW_IDLE = 0
const ROW_MOVE = 1
const ROW_ATTACK = 2
const ROW_DAMAGE = 3
const ROW_DEATH = 4
const COLS_PER_ROW = 10

const FRAME_COUNTS = {
	0: 10,  # IDLE
	1: 5,   # MOVE/WALK
	2: 10,  # ATTACK
	3: 5,   # DAMAGE
	4: 10,  # DEATH
}

func _ready() -> void:
	# Use the skeleton enemy sprite
	sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/SkeletalWarrior_Sprites.png"):
		sprite.texture = load("res://assets/sprites/SkeletalWarrior_Sprites.png")
		sprite.hframes = 10
		sprite.vframes = 10
		sprite.frame = 0
		sprite.scale = Vector2(2.0, 2.0)
		# Add a green tint to distinguish from enemy skeletons
		sprite.modulate = Color(0.7, 1.0, 0.7, 1.0)
	add_child(sprite)

func _process(delta: float) -> void:
	if is_dying:
		update_death_animation(delta)
		return

	lifetime -= delta
	if lifetime <= 0 or health <= 0:
		die()
		return

	attack_timer -= delta

	# Handle attack animation timing
	if is_attacking:
		attack_anim_timer -= delta
		if attack_anim_timer <= 0:
			is_attacking = false

	# Find target
	find_target()

	var direction := Vector2.ZERO

	if current_target and is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		direction = (current_target.global_position - global_position).normalized()

		if dist <= attack_range:
			# Attack
			if attack_timer <= 0 and not is_attacking:
				attack()
			update_animation(delta, ROW_ATTACK, direction)
		else:
			# Move toward target
			global_position += direction * speed * delta
			update_animation(delta, ROW_MOVE, direction)
	elif owner_player and is_instance_valid(owner_player):
		# Follow player if no target
		var dist_to_player = global_position.distance_to(owner_player.global_position)
		if dist_to_player > 100.0:
			direction = (owner_player.global_position - global_position).normalized()
			global_position += direction * speed * delta
			update_animation(delta, ROW_MOVE, direction)
		else:
			update_animation(delta, ROW_IDLE, direction)
	else:
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func update_animation(delta: float, new_row: int, direction: Vector2) -> void:
	if not sprite:
		return

	# Don't interrupt attack animation
	if is_attacking and new_row != ROW_ATTACK:
		new_row = ROW_ATTACK

	if current_row != new_row:
		current_row = new_row
		animation_frame = 0.0

	# Flip sprite based on movement direction
	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0

	sprite.frame = current_row * COLS_PER_ROW + int(animation_frame)

func update_death_animation(delta: float) -> void:
	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(ROW_DEATH, 10)

	if animation_frame >= max_frames:
		spawn_death_particles()
		queue_free()
	elif sprite:
		sprite.frame = ROW_DEATH * COLS_PER_ROW + int(animation_frame)

func find_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = 300.0  # Detection range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	current_target = closest

func attack() -> void:
	attack_timer = attack_cooldown
	is_attacking = true
	attack_anim_timer = 0.5  # Duration to show attack animation

	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(damage)

	# Attack visual - bone slash
	var slash = Line2D.new()
	slash.add_point(global_position)
	slash.add_point(current_target.global_position)
	slash.width = 3.0
	slash.default_color = Color(0.9, 0.9, 0.8, 0.8)
	get_tree().current_scene.add_child(slash)

	var tween = create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(slash.queue_free)

func take_damage(amount: float) -> void:
	health -= amount

	# Flash red on damage
	if sprite:
		sprite.modulate = Color(1, 0.5, 0.5, 1)
		var tween = create_tween()
		# Reset to green tint (friendly skeleton)
		tween.tween_property(sprite, "modulate", Color(0.7, 1.0, 0.7, 1.0), 0.1)

	if health <= 0:
		die()

func die() -> void:
	if is_dying:
		return

	is_dying = true
	current_row = ROW_DEATH
	animation_frame = 0.0

func spawn_death_particles() -> void:
	# Death effect - bone fragments
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.5
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2(0, 200)
	particles.color = Color(0.9, 0.9, 0.8, 1.0)
	get_tree().current_scene.add_child(particles)

	# Auto-cleanup particles
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)
