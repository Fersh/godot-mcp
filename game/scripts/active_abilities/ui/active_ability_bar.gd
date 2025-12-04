extends CanvasLayer
class_name ActiveAbilityBar

# Vertical stack layout for landscape mode
# Abilities fill from bottom to top:
# Bottom-right: Ability 1 (larger, primary)
# Above Ability 1: Ability 2
# Above Ability 2: Ability 3
# Dodge on the left side, Ultimate above the stack

const BUTTON_SIZE := Vector2(101, 101)  # Standard button size (10% smaller than 112)
const ABILITY1_SIZE := Vector2(112, 112)  # Ability 1 is larger (reduced 10% more)
const ULTIMATE_SIZE := Vector2(120, 120)  # Ultimate button size
const GRID_SPACING := 8  # Space between buttons
const MARGIN_RIGHT := 80  # 20px more left
const MARGIN_BOTTOM := 80  # 20px more up
const ULTIMATE_OFFSET_Y := 20  # Space between ultimate button and grid

var ability_buttons: Array[ActiveAbilityButton] = []
var dodge_button: ActiveAbilityButton = null
var ultimate_button: UltimateAbilityButton = null
var grid_container: Control = null

func _ready() -> void:
	layer = 50  # Above game, below menus
	process_mode = Node.PROCESS_MODE_ALWAYS

	_create_ui()
	_connect_signals()

	# Initialize with dodge button active, ability slots empty
	_setup_initial_state()

func _create_ui() -> void:
	# Main container anchored to bottom-right
	grid_container = Control.new()
	grid_container.name = "GridContainer"

	# Get viewport size for positioning
	var viewport_size = get_viewport().get_visible_rect().size

	# Calculate grid dimensions for vertical stack layout
	# Width: Dodge button + spacing + Ability stack
	# Height: Ability 3 + Ability 2 + Ability 1 (stacked vertically)
	var grid_width = BUTTON_SIZE.x + GRID_SPACING + 32 + ABILITY1_SIZE.x
	var grid_height = BUTTON_SIZE.y * 2 + 12 * 2 + ABILITY1_SIZE.y  # 3 abilities stacked

	# Position container so grid is at bottom-right corner
	grid_container.position = Vector2(
		viewport_size.x - MARGIN_RIGHT - grid_width,
		viewport_size.y - MARGIN_BOTTOM - grid_height
	)

	add_child(grid_container)

	# Create buttons in vertical stack layout (bottom to top)
	# All buttons are circles

	# Calculate vertical spacing for stacked abilities
	var stack_spacing = 12  # Space between stacked buttons
	var stack_x = BUTTON_SIZE.x + GRID_SPACING + 32  # X position for ability stack

	# Bottom: Ability 1 (larger, primary ability)
	var btn0 = _create_ability_button(0, ABILITY1_SIZE)
	var ability1_y = BUTTON_SIZE.y * 2 + stack_spacing * 2  # Leave room for Ability 2 and 3 above
	btn0.position = Vector2(stack_x, ability1_y)
	ability_buttons.append(btn0)

	# Dodge: Left side, vertically centered with Ability 1
	dodge_button = _create_dodge_button(BUTTON_SIZE)
	var dodge_y = ability1_y + (ABILITY1_SIZE.y - BUTTON_SIZE.y) / 2
	dodge_button.position = Vector2(0, dodge_y)

	# Above Ability 1: Ability 2 (centered above Ability 1, moved up 20px)
	var btn1 = _create_ability_button(1, BUTTON_SIZE)
	var ability2_y = ability1_y - stack_spacing - BUTTON_SIZE.y - 20  # Moved up 20px
	btn1.position = Vector2(stack_x + (ABILITY1_SIZE.x - BUTTON_SIZE.x) / 2, ability2_y)
	ability_buttons.append(btn1)

	# Ability 3: Left of Ability 2, above Dodge, pulled slightly towards Ability 1
	var btn2 = _create_ability_button(2, BUTTON_SIZE)
	var ability3_y = dodge_y - stack_spacing - BUTTON_SIZE.y  # Above dodge
	var ability3_x = BUTTON_SIZE.x * 0.55 - 20  # Between dodge (0) and ability 2, moved 20px left
	btn2.position = Vector2(ability3_x, ability3_y)
	ability_buttons.append(btn2)

	# Full opacity for all ability buttons
	btn0.modulate.a = 1.0
	btn1.modulate.a = 1.0
	btn2.modulate.a = 1.0
	dodge_button.modulate.a = 1.0

	# Ultimate button - positioned centered above the grid
	ultimate_button = _create_ultimate_button()
	# Center it horizontally over the grid
	var grid_center_x = (BUTTON_SIZE.x + GRID_SPACING + 32 + ABILITY1_SIZE.x) / 2
	var ultimate_x = grid_center_x - ULTIMATE_SIZE.x / 2
	var ultimate_y = -ULTIMATE_SIZE.y - ULTIMATE_OFFSET_Y
	ultimate_button.position = Vector2(ultimate_x, ultimate_y)
	ultimate_button.modulate.a = 1.0  # Full opacity

func _create_ability_button(slot: int, size: Vector2) -> ActiveAbilityButton:
	var btn_script = load("res://scripts/active_abilities/ui/active_ability_button.gd")
	var button = Control.new()
	button.set_script(btn_script)
	button.name = "AbilityButton" + str(slot)
	button.button_size = size
	grid_container.add_child(button)

	# Will be configured as empty initially
	button.setup_empty(slot)

	return button

func _create_dodge_button(size: Vector2) -> ActiveAbilityButton:
	var btn_script = load("res://scripts/active_abilities/ui/active_ability_button.gd")
	var button = Control.new()
	button.set_script(btn_script)
	button.name = "DodgeButton"
	button.button_size = size
	grid_container.add_child(button)

	button.setup_dodge()

	return button

func _create_ultimate_button() -> UltimateAbilityButton:
	var btn_script = load("res://scripts/ultimate_abilities/ui/ultimate_ability_button.gd")
	var button = Control.new()
	button.set_script(btn_script)
	button.name = "UltimateButton"
	grid_container.add_child(button)

	return button

func _connect_signals() -> void:
	# Connect to ActiveAbilityManager signals
	if ActiveAbilityManager:
		ActiveAbilityManager.ability_acquired.connect(_on_ability_acquired)

func _setup_initial_state() -> void:
	# Start with empty ability slots - hide all until acquired
	# Player starts at level 0, first ability is selected at level 1
	for i in range(ability_buttons.size()):
		ability_buttons[i].setup_empty(i)
		ability_buttons[i].visible = false  # Hide all until ability is acquired

func _on_ability_acquired(slot: int, ability: ActiveAbilityData) -> void:
	"""Update the button when an ability is acquired."""
	if slot >= 0 and slot < ability_buttons.size():
		ability_buttons[slot].visible = true
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
	tween.tween_property(button, "modulate:a", 1.0, 0.2)  # Animate to full opacity

func update_position() -> void:
	"""Update position when viewport resizes."""
	if not grid_container:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var grid_width = BUTTON_SIZE.x + GRID_SPACING + 32 + ABILITY1_SIZE.x
	var grid_height = BUTTON_SIZE.y * 2 + 12 * 2 + ABILITY1_SIZE.y  # 3 abilities stacked

	grid_container.position = Vector2(
		viewport_size.x - MARGIN_RIGHT - grid_width,
		viewport_size.y - MARGIN_BOTTOM - grid_height
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
		ability_buttons[i].visible = false  # Hide all until ability is acquired
	dodge_button.setup_dodge()
	if ultimate_button:
		ultimate_button.reset_for_new_run()

func get_ultimate_button() -> UltimateAbilityButton:
	return ultimate_button
