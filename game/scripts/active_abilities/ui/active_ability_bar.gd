extends CanvasLayer
class_name ActiveAbilityBar

# 2x2 Grid layout for landscape mode
# Bottom-left: Dodge, Bottom-right: Ability 1 (larger)
# Top-left: Ability 3, Top-right: Ability 2
# Ultimate button: centered above the 2x2 grid

const BUTTON_SIZE := Vector2(101, 101)  # Standard button size (10% smaller than 112)
const ABILITY1_SIZE := Vector2(138, 138)  # Ability 1 is larger (25% larger)
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

	# Calculate grid dimensions
	# Grid is 2x2, with ability 1 being larger
	# Total width: BUTTON_SIZE.x + GRID_SPACING + 32 (extra spacing) + ABILITY1_SIZE.x
	# Total height: BUTTON_SIZE.y + GRID_SPACING + 32 (extra spacing) + ABILITY1_SIZE.y
	var grid_width = BUTTON_SIZE.x + GRID_SPACING + 32 + ABILITY1_SIZE.x
	var grid_height = BUTTON_SIZE.y + GRID_SPACING + 32 + ABILITY1_SIZE.y

	# Position container so grid is at bottom-right corner
	grid_container.position = Vector2(
		viewport_size.x - MARGIN_RIGHT - grid_width,
		viewport_size.y - MARGIN_BOTTOM - grid_height
	)

	add_child(grid_container)

	# Create buttons in 2x2 grid layout
	# All buttons are circles

	# Bottom-right: Ability 1 (larger, primary ability)
	var btn0 = _create_ability_button(0, ABILITY1_SIZE)
	var ability1_x = BUTTON_SIZE.x + GRID_SPACING + 32  # Extra 32px left spacing (20px more)
	var ability1_y = BUTTON_SIZE.y + GRID_SPACING + 32  # Extra 32px top spacing (20px more)
	btn0.position = Vector2(ability1_x, ability1_y)
	ability_buttons.append(btn0)

	# Bottom-left: Dodge (vertically centered with Ability 1)
	dodge_button = _create_dodge_button(BUTTON_SIZE)
	var dodge_y = ability1_y + (ABILITY1_SIZE.y - BUTTON_SIZE.y) / 2
	dodge_button.position = Vector2(0, dodge_y)

	# Top-right: Ability 2 (centered above Ability 1)
	var btn1 = _create_ability_button(1, BUTTON_SIZE)
	btn1.position = Vector2(ability1_x + (ABILITY1_SIZE.x - BUTTON_SIZE.x) / 2, 0)
	ability_buttons.append(btn1)

	# Ability 3 - positioned between dodge and ability 2, closer to ability 1
	var btn2 = _create_ability_button(2, BUTTON_SIZE)
	# Move right and down to be almost between dodge area and top-left corner
	btn2.position = Vector2(60, 70)
	ability_buttons.append(btn2)

	# Apply 20% transparency to all ability buttons
	btn0.modulate.a = 0.8
	btn1.modulate.a = 0.8
	btn2.modulate.a = 0.8
	dodge_button.modulate.a = 0.8

	# Ultimate button - positioned centered above the grid
	ultimate_button = _create_ultimate_button()
	# Center it horizontally over the grid
	var grid_center_x = (BUTTON_SIZE.x + GRID_SPACING + 32 + ABILITY1_SIZE.x) / 2
	var ultimate_x = grid_center_x - ULTIMATE_SIZE.x / 2
	var ultimate_y = -ULTIMATE_SIZE.y - ULTIMATE_OFFSET_Y
	ultimate_button.position = Vector2(ultimate_x, ultimate_y)
	ultimate_button.modulate.a = 0.9  # Slightly more visible than other buttons

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
	# Start with empty ability slots
	# Hide ability 2 and 3 until unlocked (indices 1 and 2)
	for i in range(ability_buttons.size()):
		ability_buttons[i].setup_empty(i)
		if i > 0:  # Ability 2 and 3 (indices 1 and 2)
			ability_buttons[i].visible = false

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
	tween.tween_property(button, "modulate:a", 0.8, 0.2)  # Animate to 80% opacity

func update_position() -> void:
	"""Update position when viewport resizes."""
	if not grid_container:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var grid_width = BUTTON_SIZE.x + GRID_SPACING + 32 + ABILITY1_SIZE.x
	var grid_height = BUTTON_SIZE.y + GRID_SPACING + 32 + ABILITY1_SIZE.y

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
		if i > 0:  # Hide ability 2 and 3 again
			ability_buttons[i].visible = false
	dodge_button.setup_dodge()
	if ultimate_button:
		ultimate_button.reset_for_new_run()

func get_ultimate_button() -> UltimateAbilityButton:
	return ultimate_button
