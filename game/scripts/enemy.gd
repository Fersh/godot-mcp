extends CharacterBody2D

@export var speed: float = 90.0  # 1.5 pixels/frame * 60fps
@export var attack_range: float = 50.0
@export var animation_speed: float = 10.0
@export var max_health: float = 20.0
@export var gold_coin_scene: PackedScene

var player: Node2D = null
var current_health: float
var is_dying: bool = false

# Animation rows (0-indexed)
const ROW_IDLE = 0       # 4 frames
const ROW_SLEEP = 1      # 8 frames
const ROW_MOVE = 2       # 8 frames
const ROW_CARRY = 3      # 8 frames
const ROW_CARRY2 = 4     # 8 frames
const ROW_ATTACK = 5     # 8 frames
const ROW_DAMAGE = 6     # 3 frames
const ROW_DEATH = 7      # 6 frames

const COLS_PER_ROW = 8

const FRAME_COUNTS = {
	ROW_IDLE: 4,
	ROW_SLEEP: 8,
	ROW_MOVE: 8,
	ROW_CARRY: 8,
	ROW_CARRY2: 8,
	ROW_ATTACK: 8,
	ROW_DAMAGE: 3,
	ROW_DEATH: 6,
}

var current_row: int = ROW_IDLE
var animation_frame: float = 0.0
@onready var sprite: Sprite2D = $Sprite
@onready var health_bar: Node2D = $HealthBar

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")

	# Set collision layer for enemy (layer 3)
	collision_layer = 4
	collision_mask = 1

	if health_bar:
		health_bar.set_health(current_health, max_health)

func _physics_process(delta: float) -> void:
	if is_dying:
		update_death_animation(delta)
		return

	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position)
		var distance = direction.length()

		if distance > attack_range:
			direction = direction.normalized()
			velocity = direction * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, direction)
		else:
			velocity = Vector2.ZERO
			update_animation(delta, ROW_ATTACK, direction)
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func take_damage(amount: float) -> void:
	if is_dying:
		return

	current_health -= amount
	if health_bar:
		health_bar.set_health(current_health, max_health)

	if current_health <= 0:
		die()

func die() -> void:
	is_dying = true
	current_row = ROW_DEATH
	animation_frame = 0.0
	velocity = Vector2.ZERO

	# Remove from enemies group so player stops targeting
	remove_from_group("enemies")

	# Give player kill XP
	if player and is_instance_valid(player) and player.has_method("give_kill_xp"):
		player.give_kill_xp()

func update_death_animation(delta: float) -> void:
	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(ROW_DEATH, 6)

	if animation_frame >= max_frames:
		# Death animation finished - spawn coin and remove
		spawn_gold_coin()
		queue_free()
	else:
		sprite.frame = ROW_DEATH * COLS_PER_ROW + int(animation_frame)

func spawn_gold_coin() -> void:
	if gold_coin_scene == null:
		return

	var coin = gold_coin_scene.instantiate()
	coin.global_position = global_position
	get_parent().add_child(coin)

func update_animation(delta: float, new_row: int, direction: Vector2) -> void:
	if current_row != new_row:
		current_row = new_row
		animation_frame = 0.0

	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0

	sprite.frame = current_row * COLS_PER_ROW + int(animation_frame)
