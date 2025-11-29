extends Node2D

# Arena Decorations - Animated banners and torches

const BANNER_TEXTURE_PATH = "res://assets/enviro/Banner.png"
const TORCH_TEXTURE_PATH = "res://assets/enviro/Torch.png"

# Arena dimensions
const ARENA_WIDTH = 1536
const ARENA_HEIGHT = 1382

# Banner settings (128x64 sprite sheet = 4x2 grid of 32x32 frames)
const BANNER_HFRAMES = 4
const BANNER_VFRAMES = 2
const BANNER_TOTAL_FRAMES = 8
const BANNER_FPS = 6.0  # Gentle waving speed
const BANNER_SCALE = 2.5

# Torch settings (80x16 sprite sheet = 4 frames of 20x16)
const TORCH_FRAMES = 4
const TORCH_FPS = 8.0
const TORCH_SCALE = 2.5

var banner_texture: Texture2D = null
var torch_texture: Texture2D = null
var banners: Array[Sprite2D] = []
var torches: Array[Sprite2D] = []

func _ready() -> void:
	z_index = -5  # Behind player but in front of background

	# Load textures
	if ResourceLoader.exists(BANNER_TEXTURE_PATH):
		banner_texture = load(BANNER_TEXTURE_PATH)
	if ResourceLoader.exists(TORCH_TEXTURE_PATH):
		torch_texture = load(TORCH_TEXTURE_PATH)

	_spawn_decorations()

func _spawn_decorations() -> void:
	if banner_texture == null or torch_texture == null:
		return

	# Top area banners - positioned across the top wall area
	var banner_positions = [
		Vector2(250, 200),
		Vector2(550, 200),
		Vector2(768, 200),  # Center
		Vector2(986, 200),
		Vector2(1286, 200),
	]

	# Torches between banners at top
	var top_torch_positions = [
		Vector2(400, 220),
		Vector2(659, 220),
		Vector2(877, 220),
		Vector2(1136, 220),
	]

	# Torches along left wall (very close to edge)
	var left_torch_positions = [
		Vector2(15, 450),
		Vector2(15, 700),
		Vector2(15, 950),
		Vector2(15, 1200),
	]

	# Torches along right wall (very close to edge)
	var right_torch_positions = [
		Vector2(ARENA_WIDTH - 15, 450),
		Vector2(ARENA_WIDTH - 15, 700),
		Vector2(ARENA_WIDTH - 15, 950),
		Vector2(ARENA_WIDTH - 15, 1200),
	]

	# Spawn banners
	for i in range(banner_positions.size()):
		var banner = _create_banner(banner_positions[i], i)
		banners.append(banner)
		add_child(banner)

	# Spawn top torches
	for pos in top_torch_positions:
		var torch = _create_torch(pos)
		torches.append(torch)
		add_child(torch)

	# Spawn left wall torches
	for pos in left_torch_positions:
		var torch = _create_torch(pos)
		torches.append(torch)
		add_child(torch)

	# Spawn right wall torches (flipped horizontally)
	for pos in right_torch_positions:
		var torch = _create_torch(pos, true)
		torches.append(torch)
		add_child(torch)

func _create_banner(pos: Vector2, index: int) -> Sprite2D:
	var banner = Sprite2D.new()
	banner.texture = banner_texture
	banner.position = pos
	banner.scale = Vector2(BANNER_SCALE, BANNER_SCALE)
	# Set up as 4x2 grid sprite sheet (8 frames of 32x32)
	banner.hframes = BANNER_HFRAMES
	banner.vframes = BANNER_VFRAMES
	banner.frame = randi() % BANNER_TOTAL_FRAMES  # Random starting frame
	# Store animation timer with offset so banners wave at different phases
	banner.set_meta("anim_timer", index * 0.15)
	return banner

func _create_torch(pos: Vector2, flip_h: bool = false) -> Sprite2D:
	var torch = Sprite2D.new()
	torch.texture = torch_texture
	torch.position = pos
	torch.scale = Vector2(TORCH_SCALE, TORCH_SCALE)
	torch.flip_h = flip_h
	# Set up as horizontal sprite sheet (5 frames of 16x16)
	torch.hframes = TORCH_FRAMES
	torch.frame = randi() % TORCH_FRAMES  # Random starting frame
	# Store animation timer with random offset
	torch.set_meta("anim_timer", randf())
	return torch

func _process(delta: float) -> void:
	# Animate banners (frame animation - sprite sheet already has wave animation)
	for banner in banners:
		if is_instance_valid(banner):
			var anim_timer = banner.get_meta("anim_timer") + delta
			if anim_timer >= 1.0 / BANNER_FPS:
				anim_timer = fmod(anim_timer, 1.0 / BANNER_FPS)
				banner.frame = (banner.frame + 1) % BANNER_TOTAL_FRAMES
			banner.set_meta("anim_timer", anim_timer)

	# Animate torches (frame animation)
	for torch in torches:
		if is_instance_valid(torch):
			var anim_timer = torch.get_meta("anim_timer") + delta
			if anim_timer >= 1.0 / TORCH_FPS:
				anim_timer = fmod(anim_timer, 1.0 / TORCH_FPS)
				torch.frame = (torch.frame + 1) % TORCH_FRAMES
			torch.set_meta("anim_timer", anim_timer)
