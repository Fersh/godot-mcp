extends Node2D

# Elite Portal Effect
# Plays emerge animation, spawns the elite/boss, then plays disappear animation

signal spawn_ready  # Emitted when it's time to spawn the entity
signal portal_finished  # Emitted when the portal has fully closed

@onready var sprite: Sprite2D = $Sprite

var portal_texture: Texture2D = null

# Animation configuration
const COLS: int = 8
const ROWS: int = 3
const ROW_IDLE: int = 0
const ROW_EMERGE: int = 1
const ROW_DISAPPEAR: int = 2

const FRAME_COUNTS = {
	ROW_IDLE: 8,
	ROW_EMERGE: 8,
	ROW_DISAPPEAR: 6,
}

const ANIMATION_SPEED: float = 12.0  # Frames per second

var current_row: int = ROW_EMERGE
var animation_frame: float = 0.0
var frame_width: float = 0.0
var frame_height: float = 0.0

var state: int = 0  # 0 = emerging, 1 = idle (waiting), 2 = disappearing, 3 = done
var idle_duration: float = 0.5  # How long to stay idle after emerge
var idle_timer: float = 0.0
var has_emitted_spawn: bool = false

func _ready() -> void:
	# Load the portal texture
	portal_texture = load("res://assets/sprites/Purple Portal Sprite Sheet.png")

	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)

	sprite.texture = portal_texture
	sprite.hframes = COLS
	sprite.vframes = ROWS
	sprite.frame = ROW_EMERGE * COLS  # Start at first frame of emerge

	# Calculate frame dimensions
	if portal_texture:
		frame_width = portal_texture.get_width() / float(COLS)
		frame_height = portal_texture.get_height() / float(ROWS)

	# Scale up the portal to be more visible
	scale = Vector2(2.5, 2.5)

	# Start with emerge animation
	state = 0
	current_row = ROW_EMERGE
	animation_frame = 0.0

func _process(delta: float) -> void:
	match state:
		0:  # Emerging
			_animate(delta)
			var max_frames = FRAME_COUNTS[ROW_EMERGE]

			# Emit spawn signal when we're about 60% through emerge
			if not has_emitted_spawn and animation_frame >= max_frames * 0.6:
				has_emitted_spawn = true
				spawn_ready.emit()

			if animation_frame >= max_frames:
				# Switch to idle
				state = 1
				current_row = ROW_IDLE
				animation_frame = 0.0
				idle_timer = 0.0

		1:  # Idle (looping)
			_animate(delta)
			var max_frames = FRAME_COUNTS[ROW_IDLE]
			if animation_frame >= max_frames:
				animation_frame = 0.0  # Loop idle

			idle_timer += delta
			if idle_timer >= idle_duration:
				# Switch to disappear
				state = 2
				current_row = ROW_DISAPPEAR
				animation_frame = 0.0

		2:  # Disappearing
			_animate(delta)
			var max_frames = FRAME_COUNTS[ROW_DISAPPEAR]
			if animation_frame >= max_frames:
				state = 3
				portal_finished.emit()
				queue_free()

		3:  # Done
			pass

func _animate(delta: float) -> void:
	animation_frame += ANIMATION_SPEED * delta
	var max_frames = FRAME_COUNTS.get(current_row, 8)
	var frame_index = int(animation_frame) % max_frames
	sprite.frame = current_row * COLS + frame_index

func set_idle_duration(duration: float) -> void:
	"""Set how long the portal stays open after emerging."""
	idle_duration = duration

func skip_to_disappear() -> void:
	"""Force the portal to start disappearing immediately."""
	state = 2
	current_row = ROW_DISAPPEAR
	animation_frame = 0.0
