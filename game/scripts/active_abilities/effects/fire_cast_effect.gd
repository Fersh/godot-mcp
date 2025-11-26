extends Node2D

# Fire cast/burst effect using FireCast and FireBurst sprites
# Used for avatar_of_war, fire aura effects

enum FireType { CAST, BURST, AURA }

var sprite: AnimatedSprite2D
var effect_scale: float = 1.5
var fire_type: FireType = FireType.CAST
var duration: float = 3.0
var is_looping: bool = false
var _setup_done: bool = false

func _ready() -> void:
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	if _setup_done:
		return
	_setup_done = true
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 18.0)

	var source_path: String
	var frame_size: int
	var is_grid: bool = false
	var grid_cols: int = 8
	var grid_rows: int = 8

	match fire_type:
		FireType.CAST:
			source_path = "res://assets/sprites/effects/pack2/FireCast_96x96.png"
			frame_size = 96
			frames.set_animation_loop("default", false)
		FireType.BURST:
			source_path = "res://assets/sprites/effects/pack2/FireBurst_64x64.png"
			frame_size = 64
			frames.set_animation_loop("default", false)
		FireType.AURA:
			source_path = "res://assets/sprites/effects/Free Pixel Effects Pack/11_fire_spritesheet.png"
			is_grid = true
			frames.set_animation_loop("default", true)
			is_looping = true

	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var total_height = img.get_height()

			if is_grid:
				var frame_width = total_width / grid_cols
				var frame_height = total_height / grid_rows
				for row in range(grid_rows):
					for col in range(grid_cols):
						var frame_img = Image.create(frame_width, frame_height, false, img.get_format())
						frame_img.blit_rect(img, Rect2i(col * frame_width, row * frame_height, frame_width, frame_height), Vector2i.ZERO)
						frames.add_frame("default", ImageTexture.create_from_image(frame_img))
			else:
				var frame_count = total_width / frame_size
				for i in range(frame_count):
					var frame_img = Image.create(frame_size, frame_size, false, img.get_format())
					frame_img.blit_rect(img, Rect2i(i * frame_size, 0, frame_size, frame_size), Vector2i.ZERO)
					frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames

	if is_looping:
		sprite.play("default")
		get_tree().create_timer(duration).timeout.connect(_on_duration_finished)
	else:
		sprite.animation_finished.connect(_on_animation_finished)
		sprite.play("default")

func _on_animation_finished() -> void:
	queue_free()

func _on_duration_finished() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func set_fire_type(type: FireType) -> void:
	fire_type = type

func setup(ability_duration: float, ability_scale: float = 1.5) -> void:
	duration = ability_duration
	effect_scale = ability_scale
	is_looping = true
	# If setup is called before _ready completes, mark as done and setup now
	if not _setup_done:
		_setup_done = true
		_setup_sprite()
	elif sprite:
		sprite.scale = Vector2(effect_scale, effect_scale)
