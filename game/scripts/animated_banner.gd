extends Sprite2D

# Animated banner - place in editor and position visually

const BANNER_TEXTURE_PATH = "res://assets/enviro/Banner.png"
const BANNER_HFRAMES = 4
const BANNER_VFRAMES = 2
const BANNER_TOTAL_FRAMES = 8
const BANNER_FPS = 6.0

var anim_timer: float = 0.0

func _ready() -> void:
	if texture == null and ResourceLoader.exists(BANNER_TEXTURE_PATH):
		texture = load(BANNER_TEXTURE_PATH)

	hframes = BANNER_HFRAMES
	vframes = BANNER_VFRAMES
	frame = randi() % BANNER_TOTAL_FRAMES
	anim_timer = randf() * 0.5  # Random offset

func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer >= 1.0 / BANNER_FPS:
		anim_timer = fmod(anim_timer, 1.0 / BANNER_FPS)
		frame = (frame + 1) % BANNER_TOTAL_FRAMES
