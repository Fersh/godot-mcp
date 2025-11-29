extends CanvasLayer

# Epic comic book activation overlay for Ultimate abilities
# Phases:
# 1. Time freeze (Engine.time_scale = 0)
# 2. Black overlay fades in
# 3. Character splash slides in from left (using character sprite, scaled up, with glow)
# 4. Ability name types out on right side with golden text
# 5. Flash + release (restore time scale, big screen shake)

# Configuration
const PHASE_DURATION_FREEZE: float = 0.1      # Initial pause before animation
const PHASE_DURATION_OVERLAY_IN: float = 0.15 # Black overlay fade in
const PHASE_DURATION_SPLASH_IN: float = 0.25  # Character slide in
const PHASE_DURATION_NAME_TYPE: float = 0.4   # Name typing
const PHASE_DURATION_HOLD: float = 0.3        # Hold at peak
const PHASE_DURATION_RELEASE: float = 0.1     # Flash and release

# UI Elements (created dynamically)
var black_overlay: ColorRect
var character_sprite: Sprite2D
var character_glow: Sprite2D
var ability_name_label: Label
var ability_desc_label: Label
var flash_overlay: ColorRect

# State
var is_playing: bool = false
var current_ability: UltimateAbilityData = null
var current_player: Node2D = null
var completion_callback: Callable
var original_time_scale: float = 1.0

# Character sprite paths for each class
const CHARACTER_SPRITES = {
	"archer": "res://assets/sprites/archer.png",
	"knight": "res://assets/sprites/knightwhite.png",
	"beast": "res://assets/sprites/The Beast Sprite Sheet v1.1 Fixed.png",
	"mage": "res://assets/sprites/BlueMage_Sprites.png",
	"monk": "res://assets/sprites/Monk Sprite Sheet.png"
}

# Frame configuration for extracting a good frame from each spritesheet
const CHARACTER_FRAME_CONFIG = {
	"archer": {"hframes": 8, "vframes": 8, "frame": 16, "size": Vector2(32, 32)},  # Attack row
	"knight": {"hframes": 8, "vframes": 7, "frame": 32, "size": Vector2(128, 64)},  # Attack row
	"beast": {"hframes": 11, "vframes": 9, "frame": 44, "size": Vector2(128, 128)},  # Attack row
	"mage": {"hframes": 12, "vframes": 12, "frame": 24, "size": Vector2(32, 32)},  # Cast row
	"monk": {"hframes": 16, "vframes": 8, "frame": 64, "size": Vector2(96, 96)}  # Attack row
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100  # Above everything
	visible = false
	_create_ui_elements()

func _create_ui_elements() -> void:
	# Black overlay
	black_overlay = ColorRect.new()
	black_overlay.color = Color(0, 0, 0, 0)
	black_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black_overlay)

	# Character glow (behind sprite)
	var glow_container = Control.new()
	glow_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow_container)

	character_glow = Sprite2D.new()
	character_glow.modulate = Color(1.0, 0.84, 0.0, 0.6)  # Golden glow
	character_glow.position = Vector2(-400, 376)  # Start off screen left
	glow_container.add_child(character_glow)

	# Character sprite
	var sprite_container = Control.new()
	sprite_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sprite_container)

	character_sprite = Sprite2D.new()
	character_sprite.position = Vector2(-400, 376)  # Start off screen left
	sprite_container.add_child(character_sprite)

	# Ability name label
	ability_name_label = Label.new()
	ability_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ability_name_label.add_theme_font_size_override("font_size", 64)
	ability_name_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # Golden
	ability_name_label.add_theme_color_override("font_outline_color", Color(0.3, 0.15, 0.0))
	ability_name_label.add_theme_constant_override("outline_size", 4)
	ability_name_label.position = Vector2(640, 320)
	ability_name_label.size = Vector2(600, 100)
	ability_name_label.pivot_offset = Vector2(300, 50)
	ability_name_label.modulate.a = 0
	ability_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ability_name_label)

	# Ability description label (smaller, below name)
	ability_desc_label = Label.new()
	ability_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ability_desc_label.add_theme_font_size_override("font_size", 24)
	ability_desc_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	ability_desc_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	ability_desc_label.add_theme_constant_override("outline_size", 2)
	ability_desc_label.position = Vector2(640, 420)
	ability_desc_label.size = Vector2(600, 80)
	ability_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_desc_label.modulate.a = 0
	ability_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ability_desc_label)

	# Flash overlay (for release)
	flash_overlay = ColorRect.new()
	flash_overlay.color = Color(1.0, 0.95, 0.8, 0)  # Golden white flash
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_overlay)

func play_activation(ability: UltimateAbilityData, player: Node2D, on_complete: Callable) -> void:
	"""Play the epic comic book activation sequence."""
	if is_playing:
		return

	is_playing = true
	visible = true
	current_ability = ability
	current_player = player
	completion_callback = on_complete

	# Store and freeze time
	original_time_scale = Engine.time_scale
	Engine.time_scale = 0.0

	# Setup character sprite based on class
	_setup_character_sprite(ability.character_class)

	# Setup ability text
	ability_name_label.text = ability.name
	ability_desc_label.text = ability.description

	# Reset positions
	var screen_center_y = 376.0
	character_sprite.position = Vector2(-400, screen_center_y)
	character_glow.position = Vector2(-400, screen_center_y)
	ability_name_label.modulate.a = 0
	ability_desc_label.modulate.a = 0
	black_overlay.color.a = 0
	flash_overlay.color.a = 0

	# Start the animation sequence
	_run_activation_sequence()

func _setup_character_sprite(character_class: UltimateAbilityData.CharacterClass) -> void:
	"""Load and configure the character sprite for the splash."""
	var class_id = _get_class_id(character_class)
	var sprite_path = CHARACTER_SPRITES.get(class_id, CHARACTER_SPRITES["archer"])
	var frame_config = CHARACTER_FRAME_CONFIG.get(class_id, CHARACTER_FRAME_CONFIG["archer"])

	var texture = load(sprite_path)
	if texture:
		character_sprite.texture = texture
		character_sprite.hframes = frame_config["hframes"]
		character_sprite.vframes = frame_config["vframes"]
		character_sprite.frame = frame_config["frame"]

		# Scale up for epic effect
		var base_size = frame_config["size"]
		var target_height = 400.0
		var scale_factor = target_height / base_size.y
		character_sprite.scale = Vector2(scale_factor, scale_factor)

		# Setup glow sprite (same but bigger and blurred)
		character_glow.texture = texture
		character_glow.hframes = frame_config["hframes"]
		character_glow.vframes = frame_config["vframes"]
		character_glow.frame = frame_config["frame"]
		character_glow.scale = Vector2(scale_factor * 1.15, scale_factor * 1.15)

func _get_class_id(character_class: UltimateAbilityData.CharacterClass) -> String:
	match character_class:
		UltimateAbilityData.CharacterClass.ARCHER:
			return "archer"
		UltimateAbilityData.CharacterClass.KNIGHT:
			return "knight"
		UltimateAbilityData.CharacterClass.BEAST:
			return "beast"
		UltimateAbilityData.CharacterClass.MAGE:
			return "mage"
		UltimateAbilityData.CharacterClass.MONK:
			return "monk"
	return "archer"

func _run_activation_sequence() -> void:
	"""Run the full activation sequence using tweens."""
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)  # Runs during pause

	# Safety: ensure time is restored even if tween fails
	tween.finished.connect(func():
		if Engine.time_scale == 0.0:
			Engine.time_scale = original_time_scale
	)

	var screen_center_y = 376.0
	var sprite_target_x = 280.0  # Left side of screen

	# Phase 1: Brief pause (dramatic effect)
	tween.tween_interval(PHASE_DURATION_FREEZE)

	# Phase 2: Black overlay fades in
	tween.tween_property(black_overlay, "color:a", 0.85, PHASE_DURATION_OVERLAY_IN)

	# Phase 3: Character slides in from left with glow pulsing
	tween.tween_property(character_sprite, "position:x", sprite_target_x, PHASE_DURATION_SPLASH_IN)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(character_glow, "position:x", sprite_target_x, PHASE_DURATION_SPLASH_IN)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Phase 4: Ability name fades in and scales up slightly
	tween.tween_property(ability_name_label, "modulate:a", 1.0, PHASE_DURATION_NAME_TYPE * 0.3)
	tween.parallel().tween_property(ability_name_label, "scale", Vector2(1.1, 1.1), PHASE_DURATION_NAME_TYPE * 0.3)\
		.from(Vector2(0.8, 0.8)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(ability_name_label, "scale", Vector2(1.0, 1.0), PHASE_DURATION_NAME_TYPE * 0.2)

	# Description fades in
	tween.parallel().tween_property(ability_desc_label, "modulate:a", 1.0, PHASE_DURATION_NAME_TYPE * 0.4)

	# Glow pulse during hold
	tween.tween_property(character_glow, "modulate:a", 0.9, PHASE_DURATION_HOLD * 0.5)
	tween.tween_property(character_glow, "modulate:a", 0.5, PHASE_DURATION_HOLD * 0.5)

	# Phase 5: Flash and release
	tween.tween_property(flash_overlay, "color:a", 0.8, PHASE_DURATION_RELEASE * 0.3)
	tween.tween_callback(_on_sequence_peak)
	tween.tween_property(flash_overlay, "color:a", 0.0, PHASE_DURATION_RELEASE * 0.7)
	tween.parallel().tween_property(black_overlay, "color:a", 0.0, PHASE_DURATION_RELEASE * 0.7)
	tween.parallel().tween_property(character_sprite, "modulate:a", 0.0, PHASE_DURATION_RELEASE * 0.5)
	tween.parallel().tween_property(character_glow, "modulate:a", 0.0, PHASE_DURATION_RELEASE * 0.5)
	tween.parallel().tween_property(ability_name_label, "modulate:a", 0.0, PHASE_DURATION_RELEASE * 0.5)
	tween.parallel().tween_property(ability_desc_label, "modulate:a", 0.0, PHASE_DURATION_RELEASE * 0.5)

	# Cleanup
	tween.tween_callback(_on_sequence_complete)

func _on_sequence_peak() -> void:
	"""Called at the peak moment - restore time and trigger effects."""
	Engine.time_scale = original_time_scale

	# Big screen shake at release
	if JuiceManager and JuiceManager.has_method("shake_ultimate"):
		JuiceManager.shake_ultimate()
	elif JuiceManager:
		JuiceManager.shake_large()

	# Heavy haptic feedback
	if HapticManager and HapticManager.has_method("ultimate_release"):
		HapticManager.ultimate_release()
	elif HapticManager:
		HapticManager.heavy()

func _on_sequence_complete() -> void:
	"""Called when the entire sequence finishes."""
	is_playing = false
	visible = false

	# Reset sprite alpha for next use
	character_sprite.modulate.a = 1.0
	character_glow.modulate.a = 0.6

	# Call completion callback
	if completion_callback.is_valid():
		completion_callback.call()

func skip_animation() -> void:
	"""Skip to the end of the activation (for impatient players)."""
	if not is_playing:
		return

	# Kill any running tweens
	var tweens = get_tree().get_processed_tweens()
	for t in tweens:
		if t.is_valid():
			t.kill()

	# Restore time and complete
	Engine.time_scale = original_time_scale
	_on_sequence_peak()
	_on_sequence_complete()
