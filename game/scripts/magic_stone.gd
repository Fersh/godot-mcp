extends StaticBody2D

## Magic Stone - rare findable that grants ability selection when activated.
## Has a glowing highlight effect to show it's special.

signal stone_activated(stone: Node2D)

@export var glow_color: Color = Color(0.4, 0.7, 1.0, 1.0)  # Blue magical glow
@export var interaction_range: float = 50.0

var is_activated: bool = false
var player: Node2D = null
var glow_intensity: float = 0.0
var pulse_time: float = 0.0

# Pulsing outline (duplicate sprite behind main one)
var outline_sprite: Sprite2D = null
var outline_pulse_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var glow_sprite: Sprite2D = $GlowSprite
@onready var interaction_area: Area2D = $InteractionArea
@onready var point_light: PointLight2D = $PointLight2D
@onready var prompt_label: Label = null

func _ready() -> void:
	add_to_group("magic_stones")

	# Setup collision - layer 8 for obstacles
	collision_layer = 8
	collision_mask = 0

	# Find player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# Setup interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)

	# Create prompt label
	_create_prompt_label()

	# Start glow animation
	_setup_glow()

	# Create pulsing outline (duplicate sprite)
	_create_outline_effect()

func _process(delta: float) -> void:
	if is_activated:
		return

	# Pulse the glow effect
	pulse_time += delta * 2.0
	var pulse = (sin(pulse_time) + 1.0) * 0.5  # 0 to 1

	if glow_sprite:
		glow_sprite.modulate.a = 0.3 + pulse * 0.4

	if point_light:
		point_light.energy = 0.6 + pulse * 0.4

	# Subtle float animation
	var float_offset = sin(pulse_time * 0.7) * 3
	if sprite:
		sprite.position.y = -16 + float_offset
	if glow_sprite:
		glow_sprite.position.y = -16 + float_offset

	# Animate pulsing outline sprite
	outline_pulse_time += delta * 3.0
	var outline_pulse = (sin(outline_pulse_time) + 1.0) * 0.5

	if outline_sprite and is_instance_valid(outline_sprite):
		# Pulse the outline color between cyan and white
		var outline_color = Color(
			0.3 + outline_pulse * 0.4,   # R: 0.3-0.7
			0.7 + outline_pulse * 0.3,   # G: 0.7-1.0
			1.0,                          # B: always 1.0
			0.6 + outline_pulse * 0.4    # A: 0.6-1.0
		)
		outline_sprite.modulate = outline_color

		# Pulse the scale slightly
		var base_scale = sprite.scale * 1.15  # 15% larger than main sprite
		var scale_pulse = 1.0 + outline_pulse * 0.08
		outline_sprite.scale = base_scale * scale_pulse

		# Match the float position
		outline_sprite.position.y = -16 + float_offset

	# Check for interaction input when player is nearby
	if prompt_label and prompt_label.visible:
		if Input.is_action_just_pressed("ui_accept") or _is_touch_tap():
			_activate()

func _is_touch_tap() -> bool:
	# Check for touch/click on mobile
	if Input.is_action_just_pressed("click"):
		return true
	return false

func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_activated:
		if prompt_label:
			prompt_label.visible = true
		# Also allow tap interaction
		_activate()

func _on_player_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if prompt_label:
			prompt_label.visible = false

func _activate() -> void:
	if is_activated:
		return
	is_activated = true

	# Hide prompt
	if prompt_label:
		prompt_label.visible = false

	# Play activation effect
	_play_activation_effect()

	# Trigger ability selection
	_trigger_ability_selection()

func _play_activation_effect() -> void:
	# Flash bright
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.1)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.5), 0.3)

	# Expand and fade glow
	if glow_sprite:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(glow_sprite, "scale", glow_sprite.scale * 3.0, 0.5)
		tween.tween_property(glow_sprite, "modulate:a", 0.0, 0.5)

	# Expand and fade outline
	if outline_sprite and is_instance_valid(outline_sprite):
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(outline_sprite, "scale", outline_sprite.scale * 2.5, 0.5)
		tween.tween_property(outline_sprite, "modulate:a", 0.0, 0.5)

	# Fade out light
	if point_light:
		var tween = create_tween()
		tween.tween_property(point_light, "energy", 0.0, 0.5)

	# Screen effects
	if JuiceManager:
		JuiceManager.shake_medium()

	if HapticManager:
		HapticManager.medium()

	# Emit signal
	emit_signal("stone_activated", self)

func _trigger_ability_selection() -> void:
	# Find main node and trigger ability selection
	var main_nodes = get_tree().get_nodes_in_group("main")
	if main_nodes.size() > 0:
		var main = main_nodes[0]
		if main.has_node("AbilitySelection"):
			var ability_selection = main.get_node("AbilitySelection")
			# Get 3 random abilities
			if AbilityManager:
				var choices = AbilityManager.get_random_abilities(3)
				if choices.size() > 0 and ability_selection.has_method("show_choices"):
					ability_selection.show_choices(choices)

	# Queue free after a delay (after ability selection is done)
	await get_tree().create_timer(1.0).timeout
	_fade_out_and_remove()

func _fade_out_and_remove() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _setup_glow() -> void:
	# Create glow sprite if not exists
	if not glow_sprite and sprite and sprite.texture:
		glow_sprite = Sprite2D.new()
		glow_sprite.name = "GlowSprite"
		glow_sprite.texture = sprite.texture
		glow_sprite.modulate = glow_color
		glow_sprite.modulate.a = 0.5
		glow_sprite.scale = sprite.scale * 1.3
		glow_sprite.z_index = sprite.z_index - 1
		glow_sprite.position = sprite.position
		add_child(glow_sprite)

func _create_prompt_label() -> void:
	prompt_label = Label.new()
	prompt_label.text = "Tap to activate"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-50, -60)
	prompt_label.size = Vector2(100, 20)
	prompt_label.visible = false

	# Style
	prompt_label.add_theme_font_size_override("font_size", 10)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)

	add_child(prompt_label)

func _create_outline_effect() -> void:
	# Create a duplicate sprite behind the main one for the outline glow effect
	# This way the glow follows the actual shape of the stone (not a rectangle)
	if not sprite or not sprite.texture:
		return

	# Create the outline sprite as a duplicate of the main sprite
	outline_sprite = Sprite2D.new()
	outline_sprite.name = "OutlineSprite"
	outline_sprite.texture = sprite.texture
	outline_sprite.position = sprite.position
	outline_sprite.scale = sprite.scale * 1.15  # Slightly larger for outline effect

	# Color it with the glow color
	outline_sprite.modulate = Color(0.3, 0.8, 1.0, 0.8)

	# Place it behind the main sprite
	outline_sprite.z_index = sprite.z_index - 1

	# Add before the sprite so it renders behind
	add_child(outline_sprite)
	move_child(outline_sprite, 0)  # Move to back
