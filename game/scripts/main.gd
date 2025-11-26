extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var ability_selection: CanvasLayer = $AbilitySelection
@onready var item_pickup_ui: CanvasLayer = $ItemPickupUI

# Active ability UI components (untyped to allow script assignment)
var active_ability_bar = null
var active_ability_selection_ui = null
var buff_bar = null

# Virtual joystick for movement
var virtual_joystick = null
var joystick_scene: PackedScene = preload("res://scenes/ui/virtual_joystick.tscn")

var game_over_scene: PackedScene = preload("res://scenes/game_over.tscn")
var game_time: float = 0.0
var kill_count: int = 0

# Track dropped items for proximity detection
var nearby_item: Node2D = null

# Levels that grant active abilities (not passive)
const ACTIVE_ABILITY_LEVELS: Array[int] = [1, 5, 10]

func _ready() -> void:
	add_to_group("main")

	# Connect player signals
	if player:
		player.level_up.connect(_on_player_level_up)
		player.player_died.connect(_on_player_died)

	# Start background music
	if SoundManager:
		SoundManager.play_music()

	# Reset equipment manager for this run
	if EquipmentManager:
		EquipmentManager.reset_run()

	# Apply equipment abilities at start of run
	if AbilityManager:
		AbilityManager.apply_equipment_abilities()

	# Setup active ability system
	_setup_active_ability_system()

	# Setup virtual joystick
	_setup_virtual_joystick()

	# Show level 1 active ability selection after a short delay
	# (allows UI to initialize first)
	get_tree().create_timer(0.1).timeout.connect(_show_initial_ability_selection)

func _process(delta: float) -> void:
	game_time += delta

	# Update equipment manager with current game time
	if EquipmentManager:
		EquipmentManager.update_game_time(game_time)

	# Check for nearby dropped items
	_check_nearby_items()

func _on_player_level_up(new_level: int) -> void:
	# Check if this level grants an active ability
	if new_level in ACTIVE_ABILITY_LEVELS:
		_show_active_ability_selection(new_level)
	else:
		# Regular passive ability selection
		var choices = AbilityManager.get_random_abilities(3)
		if choices.size() > 0:
			ability_selection.show_choices(choices)

func _on_player_died() -> void:
	# Wait for death animation then show game over
	await get_tree().create_timer(3.5).timeout
	show_game_over()

func show_game_over() -> void:
	get_tree().paused = true

	var game_over = game_over_scene.instantiate()

	# Get stats
	var level = player.current_level if player else 1
	var stats_display = get_node_or_null("StatsDisplay")
	if stats_display and stats_display.has_method("get_kill_count"):
		kill_count = stats_display.get_kill_count()

	game_over.set_stats(level, game_time, kill_count)
	add_child(game_over)

func add_kill() -> void:
	kill_count += 1

func _check_nearby_items() -> void:
	if not player or not is_instance_valid(player):
		return

	# Don't check if already showing UI
	if item_pickup_ui and item_pickup_ui.visible:
		return

	# Find closest dropped item within range
	var dropped_items = get_tree().get_nodes_in_group("dropped_items")
	var closest_item: Node2D = null
	var closest_distance: float = 80.0  # Pickup range

	for item in dropped_items:
		if is_instance_valid(item):
			var distance = player.global_position.distance_to(item.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_item = item

	# Show pickup UI if we found a nearby item
	if closest_item and closest_item != nearby_item:
		nearby_item = closest_item
		if item_pickup_ui and closest_item.has_method("get_item_data"):
			var item_data = closest_item.get_item_data()
			var character_id = CharacterManager.selected_character_id if CharacterManager else "archer"
			var equipped = EquipmentManager.get_equipped_item(character_id, item_data.slot) if EquipmentManager else null
			item_pickup_ui.show_item(closest_item, equipped != null)
	elif not closest_item:
		nearby_item = null

# ============================================
# VIRTUAL JOYSTICK
# ============================================

func _setup_virtual_joystick() -> void:
	"""Initialize the virtual joystick for player movement."""
	if joystick_scene:
		# Create a CanvasLayer for the joystick
		var joystick_layer = CanvasLayer.new()
		joystick_layer.layer = 10
		joystick_layer.name = "JoystickLayer"
		add_child(joystick_layer)

		# Instantiate the joystick
		virtual_joystick = joystick_scene.instantiate()
		joystick_layer.add_child(virtual_joystick)

		# Register with player
		if player and player.has_method("register_joystick"):
			player.register_joystick(virtual_joystick)

# ============================================
# ACTIVE ABILITY SYSTEM
# ============================================

func _setup_active_ability_system() -> void:
	"""Initialize the active ability UI and manager."""
	# Reset ActiveAbilityManager for new run
	if ActiveAbilityManager:
		ActiveAbilityManager.reset_for_new_run()
		ActiveAbilityManager.register_player(player)

	# Create the ability bar UI
	var bar_script = load("res://scripts/active_abilities/ui/active_ability_bar.gd")
	if bar_script:
		active_ability_bar = CanvasLayer.new()
		active_ability_bar.set_script(bar_script)
		active_ability_bar.name = "ActiveAbilityBar"
		add_child(active_ability_bar)

	# Create the selection UI
	var selection_script = load("res://scripts/active_abilities/ui/active_ability_selection_ui.gd")
	if selection_script:
		active_ability_selection_ui = CanvasLayer.new()
		active_ability_selection_ui.set_script(selection_script)
		active_ability_selection_ui.name = "ActiveAbilitySelectionUI"
		add_child(active_ability_selection_ui)

	# Create the buff bar UI
	var buff_script = load("res://scripts/ui/buff_bar.gd")
	if buff_script:
		buff_bar = CanvasLayer.new()
		buff_bar.set_script(buff_script)
		buff_bar.name = "BuffBar"
		add_child(buff_bar)

func _show_initial_ability_selection() -> void:
	"""Show the level 1 active ability selection at game start."""
	_show_active_ability_selection(1)

func _show_active_ability_selection(level: int) -> void:
	"""Show the active ability selection UI for the given level."""
	if not active_ability_selection_ui:
		# Fallback to passive if UI not available
		var choices = AbilityManager.get_random_abilities(3)
		if choices.size() > 0:
			ability_selection.show_choices(choices)
		return

	# Get character type for filtering abilities
	var is_melee = false
	if CharacterManager:
		var char_data = CharacterManager.get_selected_character()
		if char_data:
			is_melee = char_data.attack_type == CharacterData.AttackType.MELEE

	# Get random active abilities for this level
	var choices = ActiveAbilityManager.get_random_abilities_for_level(level, is_melee, 3)

	if choices.size() > 0:
		active_ability_selection_ui.show_choices(choices, level)
	else:
		# No active abilities available, fall back to passive
		var passive_choices = AbilityManager.get_random_abilities(3)
		if passive_choices.size() > 0:
			ability_selection.show_choices(passive_choices)
