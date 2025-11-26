extends CanvasLayer
class_name ActiveAbilityBar

# Arc layout for landscape mode
# Buttons arranged in a 90-degree arc from bottom-right corner
# Dodge is easiest to reach (closest to corner), abilities fan out

const BUTTON_SIZE := Vector2(120, 120)
const ARC_RADIUS := 180.0  # Distance from corner to button centers
const MARGIN_RIGHT := 20
const MARGIN_BOTTOM := 20

var ability_buttons: Array[ActiveAbilityButton] = []
var dodge_button: ActiveAbilityButton = null
var arc_container: Control = null

func _ready() -> void:
	layer = 50  # Above game, below menus
	process_mode = Node.PROCESS_MODE_ALWAYS

	_create_ui()
	_connect_signals()

	# Initialize with dodge button active, ability slots empty
	_setup_initial_state()

func _create_ui() -> void:
	# Main container anchored to bottom-right
	arc_container = Control.new()
	arc_container.name = "ArcContainer"

	# Get viewport size for positioning
	var viewport_size = get_viewport().get_visible_rect().size

	# Position container at bottom-right corner
	arc_container.position = Vector2(
		viewport_size.x - MARGIN_RIGHT,
		viewport_size.y - MARGIN_BOTTOM
	)

	add_child(arc_container)

	# Create buttons in arc layout
	# Arc spans from 180 degrees (left) to 270 degrees (up)
	# That's a 90-degree arc going counter-clockwise from left to up

	# Dodge: 200 degrees (bottom-right, easiest thumb reach)
	dodge_button = _create_dodge_button()
	_position_button_on_arc(dodge_button, deg_to_rad(200))

	# Ability 0: 220 degrees
	var btn0 = _create_ability_button(0)
	_position_button_on_arc(btn0, deg_to_rad(220))
	ability_buttons.append(btn0)

	# Ability 1: 245 degrees
	var btn1 = _create_ability_button(1)
	_position_button_on_arc(btn1, deg_to_rad(245))
	ability_buttons.append(btn1)

	# Ability 2: 270 degrees (top, ultimate ability)
	var btn2 = _create_ability_button(2)
	_position_button_on_arc(btn2, deg_to_rad(270))
	ability_buttons.append(btn2)

func _position_button_on_arc(button: Control, angle: float) -> void:
	# Calculate position on arc (relative to bottom-right corner)
	var x = cos(angle) * ARC_RADIUS - BUTTON_SIZE.x / 2
	var y = sin(angle) * ARC_RADIUS - BUTTON_SIZE.y / 2
	button.position = Vector2(x, y)

func _create_ability_button(slot: int) -> ActiveAbilityButton:
	var btn_script = load("res://scripts/active_abilities/ui/active_ability_button.gd")
	var button = Control.new()
	button.set_script(btn_script)
	button.name = "AbilityButton" + str(slot)
	button.button_size = BUTTON_SIZE
	arc_container.add_child(button)

	# Will be configured as empty initially
	button.setup_empty(slot)

	return button

func _create_dodge_button() -> ActiveAbilityButton:
	var btn_script = load("res://scripts/active_abilities/ui/active_ability_button.gd")
	var button = Control.new()
	button.set_script(btn_script)
	button.name = "DodgeButton"
	button.button_size = BUTTON_SIZE
	arc_container.add_child(button)

	button.setup_dodge()

	return button

func _connect_signals() -> void:
	# Connect to ActiveAbilityManager signals
	if ActiveAbilityManager:
		ActiveAbilityManager.ability_acquired.connect(_on_ability_acquired)

func _setup_initial_state() -> void:
	# Start with empty ability slots
	for i in range(ability_buttons.size()):
		ability_buttons[i].setup_empty(i)

func _on_ability_acquired(slot: int, ability: ActiveAbilityData) -> void:
	"""Update the button when an ability is acquired."""
	if slot >= 0 and slot < ability_buttons.size():
		ability_buttons[slot].setup_ability(ability, slot)
		_animate_button_appear(ability_buttons[slot])

func _animate_button_appear(button: ActiveAbilityButton) -> void:
	"""Animate a button appearing when ability is acquired."""
	button.scale = Vector2(0.5, 0.5)
	button.modulate.a = 0.0

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "modulate:a", 1.0, 0.2)

func update_position() -> void:
	"""Update position when viewport resizes."""
	if not arc_container:
		return

	var viewport_size = get_viewport().get_visible_rect().size

	arc_container.position = Vector2(
		viewport_size.x - MARGIN_RIGHT,
		viewport_size.y - MARGIN_BOTTOM
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		update_position()

func get_ability_button(slot: int) -> ActiveAbilityButton:
	"""Get button for a specific ability slot."""
	if slot >= 0 and slot < ability_buttons.size():
		return ability_buttons[slot]
	return null

func get_dodge_button() -> ActiveAbilityButton:
	return dodge_button

func show_bar() -> void:
	visible = true

func hide_bar() -> void:
	visible = false

func reset_for_new_run() -> void:
	"""Reset all buttons for a new game run."""
	for i in range(ability_buttons.size()):
		ability_buttons[i].setup_empty(i)
	dodge_button.setup_dodge()
