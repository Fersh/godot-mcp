extends Sprite2D

# Animated torch - place in editor and position visually
# Sprite sheet: 80x16 = 10 frames of 8x16 each

const TORCH_FRAMES = 10
const TORCH_FPS = 8.0

var anim_timer: float = 0.0

func _ready() -> void:
	# Ensure hframes is set correctly
	hframes = TORCH_FRAMES
	frame = randi() % TORCH_FRAMES  # Random starting frame
	anim_timer = randf()  # Random offset so torches aren't in sync

func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer >= 1.0 / TORCH_FPS:
		anim_timer = fmod(anim_timer, 1.0 / TORCH_FPS)
		frame = (frame + 1) % TORCH_FRAMES
