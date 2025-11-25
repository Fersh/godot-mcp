extends CharacterBody2D

@export var speed: float = 150.0
@export var attack_range: float = 50.0
@export var animation_speed: float = 10.0

var player: Node2D = null

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

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position)
		var distance = direction.length()

		if distance > attack_range:
			# Move towards player
			direction = direction.normalized()
			velocity = direction * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, direction)
		else:
			# Attack when close
			velocity = Vector2.ZERO
			update_animation(delta, ROW_ATTACK, direction)
	else:
		# Idle if no player
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func update_animation(delta: float, new_row: int, direction: Vector2) -> void:
	# Reset frame when animation changes
	if current_row != new_row:
		current_row = new_row
		animation_frame = 0.0

	# Flip sprite based on horizontal direction
	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	# Advance animation frame
	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0

	# Set the sprite frame
	sprite.frame = current_row * COLS_PER_ROW + int(animation_frame)
