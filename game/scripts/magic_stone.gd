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

# Pulsing border
var border_nodes: Array[ColorRect] = []
var border_pulse_time: float = 0.0

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

	# Create pulsing border
	_create_pulsing_border()

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
	if sprite:
		sprite.position.y = -16 + sin(pulse_time * 0.7) * 3
	if glow_sprite:
		glow_sprite.position.y = -16 + sin(pulse_time * 0.7) * 3

	# Animate pulsing border
	border_pulse_time += delta * 3.0
	var border_pulse = (sin(border_pulse_time) + 1.0) * 0.5
	var border_color = Color(0.3, 0.8, 1.0, 0.4 + border_pulse * 0.5)
	var border_scale = 1.0 + border_pulse * 0.1

	for border in border_nodes:
		if is_instance_valid(border):
			border.modulate = border_color
			# Scale border slightly with pulse
			var base_size = border.get_meta("base_size", border.size)
			var base_pos = border.get_meta("base_pos", border.position)
			border.size = base_size * border_scale
			border.position = base_pos - (base_size * (border_scale - 1.0) * 0.5)

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

func _create_pulsing_border() -> void:
	# Create a glowing border around the stone using ColorRects
	if not sprite or not sprite.texture:
		return

	var tex_size = sprite.texture.get_size() * sprite.scale
	var border_thickness = 4.0
	var padding = 8.0  # Extra space around the sprite

	var total_width = tex_size.x + padding * 2
	var total_height = tex_size.y + padding * 2
	var offset_y = sprite.position.y - tex_size.y * 0.5 - padding

	var border_color = Color(0.3, 0.8, 1.0, 0.6)

	# Create container for border
	var border_container = Node2D.new()
	border_container.name = "BorderContainer"
	border_container.z_index = -2
	add_child(border_container)

	# Top border
	var top = ColorRect.new()
	top.size = Vector2(total_width, border_thickness)
	top.position = Vector2(-total_width / 2, offset_y)
	top.color = border_color
	top.set_meta("base_size", top.size)
	top.set_meta("base_pos", top.position)
	border_container.add_child(top)
	border_nodes.append(top)

	# Bottom border
	var bottom = ColorRect.new()
	bottom.size = Vector2(total_width, border_thickness)
	bottom.position = Vector2(-total_width / 2, offset_y + total_height - border_thickness)
	bottom.color = border_color
	bottom.set_meta("base_size", bottom.size)
	bottom.set_meta("base_pos", bottom.position)
	border_container.add_child(bottom)
	border_nodes.append(bottom)

	# Left border
	var left = ColorRect.new()
	left.size = Vector2(border_thickness, total_height)
	left.position = Vector2(-total_width / 2, offset_y)
	left.color = border_color
	left.set_meta("base_size", left.size)
	left.set_meta("base_pos", left.position)
	border_container.add_child(left)
	border_nodes.append(left)

	# Right border
	var right = ColorRect.new()
	right.size = Vector2(border_thickness, total_height)
	right.position = Vector2(total_width / 2 - border_thickness, offset_y)
	right.color = border_color
	right.set_meta("base_size", right.size)
	right.set_meta("base_pos", right.position)
	border_container.add_child(right)
	border_nodes.append(right)

	# Corner accents (brighter)
	var corner_size = border_thickness * 2
	var corner_color = Color(0.5, 0.9, 1.0, 0.8)

	# Top-left corner
	var tl = ColorRect.new()
	tl.size = Vector2(corner_size, corner_size)
	tl.position = Vector2(-total_width / 2, offset_y)
	tl.color = corner_color
	tl.set_meta("base_size", tl.size)
	tl.set_meta("base_pos", tl.position)
	border_container.add_child(tl)
	border_nodes.append(tl)

	# Top-right corner
	var tr = ColorRect.new()
	tr.size = Vector2(corner_size, corner_size)
	tr.position = Vector2(total_width / 2 - corner_size, offset_y)
	tr.color = corner_color
	tr.set_meta("base_size", tr.size)
	tr.set_meta("base_pos", tr.position)
	border_container.add_child(tr)
	border_nodes.append(tr)

	# Bottom-left corner
	var bl = ColorRect.new()
	bl.size = Vector2(corner_size, corner_size)
	bl.position = Vector2(-total_width / 2, offset_y + total_height - corner_size)
	bl.color = corner_color
	bl.set_meta("base_size", bl.size)
	bl.set_meta("base_pos", bl.position)
	border_container.add_child(bl)
	border_nodes.append(bl)

	# Bottom-right corner
	var br = ColorRect.new()
	br.size = Vector2(corner_size, corner_size)
	br.position = Vector2(total_width / 2 - corner_size, offset_y + total_height - corner_size)
	br.color = corner_color
	br.set_meta("base_size", br.size)
	br.set_meta("base_pos", br.position)
	border_container.add_child(br)
	border_nodes.append(br)
