extends CanvasLayer
class_name ActiveAbilityBar

# 2x2 grid layout:
# [Ability 3] [Ability 2]
# [Dodge]     [Ability 1]

const BUTTON_SIZE := Vector2(160, 160)  # Doubled
const BUTTON_SPACING := 15
const MARGIN_RIGHT := 30
const MARGIN_BOTTOM := 30

var ability_buttons: Array[ActiveAbilityButton] = []
var dodge_button: ActiveAbilityButton = null
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

	# Calculate grid size
	var grid_width = BUTTON_SIZE.x * 2 + BUTTON_SPACING
	var grid_height = BUTTON_SIZE.y * 2 + BUTTON_SPACING

	# Get viewport size for positioning
	var viewport_size = get_viewport().get_visible_rect().size

	grid_container.position = Vector2(
		viewport_size.x - grid_width - MARGIN_RIGHT,
		viewport_size.y - grid_height - MARGIN_BOTTOM
	)
	grid_container.size = Vector2(grid_width, grid_height)

	add_child(grid_container)

	# Create buttons in grid layout
	# Bottom-right: Ability slot 0 (first ability acquired)
	var btn0 = _create_ability_button(0)
	btn0.position = Vector2(BUTTON_SIZE.x + BUTTON_SPACING, BUTTON_SIZE.y + BUTTON_SPACING)
	ability_buttons.append(btn0)

	# Top-right: Ability slot 1 (second ability acquired)
	var btn1 = _create_ability_button(1)
	btn1.position = Vector2(BUTTON_SIZE.x + BUTTON_SPACING, 0)
	ability_buttons.append(btn1)

	# Top-left: Ability slot 2 (third ability acquired)
	var btn2 = _create_ability_button(2)
	btn2.position = Vector2(0, 0)
	ability_buttons.append(btn2)

	# Bottom-left: Dodge
	dodge_button = _create_dodge_button()
	dodge_button.position = Vector2(0, BUTTON_SIZE.y + BUTTON_SPACING)

func _create_ability_button(slot: int) -> ActiveAbilityButton:
	var btn_script = load("res://scripts/active_abilities/ui/active_ability_button.gd")
	var button = Control.new()
	button.set_script(btn_script)
	button.name = "AbilityButton" + str(slot)
	grid_container.add_child(button)

	# Will be configured as empty initially
	button.setup_empty(slot)

	return button

func _create_dodge_button() -> ActiveAbilityButton:
	var btn_script = load("res://scripts/active_abilities/ui/active_ability_button.gd")
	var button = Control.new()
	button.set_script(btn_script)
	button.name = "DodgeButton"
	grid_container.add_child(button)

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
	if not grid_container:
		return

	var grid_width = BUTTON_SIZE.x * 2 + BUTTON_SPACING
	var grid_height = BUTTON_SIZE.y * 2 + BUTTON_SPACING
	var viewport_size = get_viewport().get_visible_rect().size

	grid_container.position = Vector2(
		viewport_size.x - grid_width - MARGIN_RIGHT,
		viewport_size.y - grid_height - MARGIN_BOTTOM
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
