extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var ability_selection: CanvasLayer = $AbilitySelection
@onready var item_pickup_ui: CanvasLayer = $ItemPickupUI

# Active ability UI components (untyped to allow script assignment)
var active_ability_bar = null
var active_ability_selection_ui = null
var buff_bar = null

# Ultimate ability UI components
var ultimate_selection_ui = null
var ultimate_activation_overlay = null

# Virtual joystick for movement
var virtual_joystick = null
var joystick_scene: PackedScene = preload("res://scenes/ui/virtual_joystick.tscn")

var game_over_scene: PackedScene = preload("res://scenes/game_over.tscn")
var continue_screen_script = preload("res://scripts/continue_screen.gd")
var game_time: float = 0.0
var kill_count: int = 0

# Continue system - once per run
var continue_used: bool = false

# Track dropped items for proximity detection
var nearby_item: Node2D = null

# Levels that grant active abilities (not passive)
const ACTIVE_ABILITY_LEVELS: Array[int] = [1, 5, 10]

# Level that grants ultimate ability
const ULTIMATE_ABILITY_LEVEL: int = 15

var kill_streak_ui = null

# Challenge mode controller
var challenge_controller = null
var challenge_controller_script = preload("res://scripts/challenge_mode_controller.gd")

# Challenge mode background texture
var challenge_bg_texture = preload("res://assets/enviro/diff_1.png")

# Tile-based background system
var tile_background = null
var tile_background_script = preload("res://scripts/tile_background.gd")
var use_tile_background: bool = true  # Toggle between tile-based and static background

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

	# Reset kill streak manager for this run
	if KillStreakManager:
		KillStreakManager.reset()

	# Setup active ability system
	_setup_active_ability_system()

	# Setup virtual joystick
	_setup_virtual_joystick()

	# Setup kill streak UI (#1)
	_setup_kill_streak_ui()

	# Setup tile-based background (if enabled and not in challenge mode)
	_setup_tile_background()

	# Setup challenge mode if selected
	_setup_challenge_mode()

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
	# Delay ability selection to let level up animation play (1.25s)
	await get_tree().create_timer(1.25).timeout

	# No abilities at max level (20)
	if player and new_level >= player.MAX_LEVEL:
		return

	# Check if this level grants the ultimate ability
	if new_level == ULTIMATE_ABILITY_LEVEL:
		_show_ultimate_ability_selection()
	# Check if this level grants an active ability
	elif new_level in ACTIVE_ABILITY_LEVELS:
		_show_active_ability_selection(new_level)
	else:
		# Regular passive ability selection
		var ability_count = CurseEffects.get_ability_choices() if CurseEffects else 3
		var choices = AbilityManager.get_random_abilities(ability_count)
		if choices.size() > 0:
			ability_selection.show_choices(choices)

func _on_player_died() -> void:
	# Wait for death animation
	await get_tree().create_timer(2.0).timeout

	# Check if continue is available (once per run)
	if not continue_used:
		_show_continue_screen()
	else:
		# Wait remaining time and show game over
		await get_tree().create_timer(1.5).timeout
		show_game_over()

func _show_continue_screen() -> void:
	"""Show the continue screen with archangel animation."""
	var continue_screen = CanvasLayer.new()
	continue_screen.set_script(continue_screen_script)
	continue_screen.name = "ContinueScreen"
	add_child(continue_screen)

	# Setup with player reference
	if continue_screen.has_method("setup"):
		continue_screen.setup(player)

	# Connect to the choice signal
	continue_screen.continue_chosen.connect(_on_continue_chosen)

func _on_continue_chosen(accepted: bool) -> void:
	"""Handle the player's continue choice."""
	continue_used = true  # Mark continue as used regardless of choice

	if accepted:
		# Revive the player at full HP
		_revive_player()
	else:
		# Proceed to game over
		show_game_over()

func _revive_player() -> void:
	"""Revive the player at full HP and show REVIVED effect."""
	# Unpause first
	get_tree().paused = false

	# Show REVIVED text effect (similar to phoenix)
	_show_revived_effect()

	# Revive player at full HP
	if player and is_instance_valid(player) and player.has_method("revive_with_percent"):
		player.revive_with_percent(1.0)  # Full HP

	# Knock back nearby enemies for safety
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < 200:
				var direction = (enemy.global_position - player.global_position).normalized()
				if enemy.has_method("apply_knockback"):
					enemy.apply_knockback(direction * 400)

func _show_revived_effect() -> void:
	"""Show the REVIVED text effect on screen."""
	# Create overlay canvas layer
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	# Create centered label
	var label = Label.new()
	label.text = "REVIVED"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)

	# Load pixel font
	var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))  # Green/healing color

	# Shadow for visibility
	label.add_theme_color_override("font_shadow_color", Color(0.1, 0.4, 0.2, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)

	# Start invisible and scaled down
	label.modulate.a = 0.0
	label.scale = Vector2(0.5, 0.5)
	label.pivot_offset = label.size / 2

	canvas.add_child(label)

	# Animate: fade in, scale up, hold, then fade out
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(1.0)  # Hold
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): canvas.queue_free())

	# Screen effects
	if JuiceManager:
		JuiceManager.shake_medium()

	if HapticManager:
		HapticManager.medium()

func show_game_over(gave_up: bool = false) -> void:
	get_tree().paused = true

	var game_over = game_over_scene.instantiate()

	# Get stats
	var level = player.current_level if player else 1
	var stats_display = get_node_or_null("StatsDisplay")
	if stats_display and stats_display.has_method("get_kill_count"):
		kill_count = stats_display.get_kill_count()

	game_over.set_stats(level, game_time, kill_count)
	game_over.set_gave_up(gave_up)
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
	# Reset nearby_item if it's no longer valid (was picked up or freed)
	if nearby_item and not is_instance_valid(nearby_item):
		nearby_item = null

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

	# Reset UltimateAbilityManager for new run
	if UltimateAbilityManager:
		UltimateAbilityManager.reset_for_new_run()
		UltimateAbilityManager.register_player(player)

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

	# Create ultimate ability selection UI
	var ultimate_selection_script = load("res://scripts/ultimate_abilities/ui/ultimate_selection_ui.gd")
	if ultimate_selection_script:
		ultimate_selection_ui = CanvasLayer.new()
		ultimate_selection_ui.set_script(ultimate_selection_script)
		ultimate_selection_ui.name = "UltimateSelectionUI"
		add_child(ultimate_selection_ui)

	# Create ultimate activation overlay
	var activation_overlay_script = load("res://scripts/ultimate_abilities/ultimate_activation_overlay.gd")
	if activation_overlay_script:
		ultimate_activation_overlay = CanvasLayer.new()
		ultimate_activation_overlay.set_script(activation_overlay_script)
		ultimate_activation_overlay.name = "UltimateActivationOverlay"
		add_child(ultimate_activation_overlay)
		# Register with manager
		if UltimateAbilityManager:
			UltimateAbilityManager.register_activation_overlay(ultimate_activation_overlay)

func _show_initial_ability_selection() -> void:
	"""Show the level 1 active ability selection at game start."""
	_show_active_ability_selection(1)

func _show_active_ability_selection(level: int) -> void:
	"""Show the active ability selection UI for the given level."""
	if not active_ability_selection_ui:
		# Fallback to passive if UI not available
		var ability_count = CurseEffects.get_ability_choices() if CurseEffects else 3
		var choices = AbilityManager.get_random_abilities(ability_count)
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
	var ability_count = CurseEffects.get_ability_choices() if CurseEffects else 3
	var choices = ActiveAbilityManager.get_random_abilities_for_level(level, is_melee, ability_count)

	if choices.size() > 0:
		active_ability_selection_ui.show_choices(choices, level)
	else:
		# No active abilities available, fall back to passive
		var passive_choices = AbilityManager.get_random_abilities(ability_count)
		if passive_choices.size() > 0:
			ability_selection.show_choices(passive_choices)

func _show_ultimate_ability_selection() -> void:
	"""Show the ultimate ability selection UI at level 5 (swapped for testing)."""
	print("DEBUG: _show_ultimate_ability_selection called")
	print("DEBUG: ultimate_selection_ui = ", ultimate_selection_ui)

	var ability_count = CurseEffects.get_ability_choices() if CurseEffects else 3

	if not ultimate_selection_ui:
		print("DEBUG: No ultimate_selection_ui, falling back to passive")
		# Fallback to passive if UI not available
		var choices = AbilityManager.get_random_abilities(ability_count)
		if choices.size() > 0:
			ability_selection.show_choices(choices)
		return

	# Get character ID for class-specific ultimates
	var character_id = "archer"
	if CharacterManager:
		character_id = CharacterManager.selected_character_id
	print("DEBUG: character_id = ", character_id)

	# Get random ultimate abilities for this character
	var choices = UltimateAbilityManager.get_random_ultimates_for_selection(character_id, ability_count) if UltimateAbilityManager else []
	print("DEBUG: choices.size() = ", choices.size())

	if choices.size() > 0:
		print("DEBUG: Showing ultimate selection UI")
		ultimate_selection_ui.show_choices(choices, character_id)
	else:
		print("DEBUG: No ultimates available, falling back to passive")
		# No ultimates available, fall back to passive
		var passive_choices = AbilityManager.get_random_abilities(ability_count)
		if passive_choices.size() > 0:
			ability_selection.show_choices(passive_choices)

# ============================================
# KILL STREAK UI SETUP (#1)
# ============================================

func _setup_kill_streak_ui() -> void:
	"""Initialize the kill streak UI display."""
	var ui_script = load("res://scripts/ui/kill_streak_ui.gd")
	if ui_script:
		kill_streak_ui = CanvasLayer.new()
		kill_streak_ui.set_script(ui_script)
		kill_streak_ui.name = "KillStreakUI"
		add_child(kill_streak_ui)

# ============================================
# TILE BACKGROUND SETUP
# ============================================

func _setup_tile_background() -> void:
	"""Initialize tile-based background if enabled (skipped in challenge mode)."""
	# Skip if disabled or in challenge mode (challenge mode has its own background)
	if not use_tile_background:
		return
	if DifficultyManager and DifficultyManager.is_challenge_mode():
		return

	# Hide the original static background
	var background = get_node_or_null("Background")
	if background:
		background.visible = false

	# Create tile background
	tile_background = Node2D.new()
	tile_background.set_script(tile_background_script)
	tile_background.name = "TileBackground"
	add_child(tile_background)
	move_child(tile_background, 0)  # Move to back of scene

func toggle_tile_background(enabled: bool) -> void:
	"""Toggle between tile-based and static background at runtime."""
	use_tile_background = enabled

	var background = get_node_or_null("Background")

	if enabled:
		# Hide static, show tiles
		if background:
			background.visible = false
		if tile_background:
			tile_background.set_visible_tiles(true)
		elif tile_background_script:
			_setup_tile_background()
	else:
		# Show static, hide tiles
		if background:
			background.visible = true
		if tile_background:
			tile_background.set_visible_tiles(false)

func regenerate_tile_background(new_seed: int = 0) -> void:
	"""Regenerate the tile background with a new random layout."""
	if tile_background and tile_background.has_method("regenerate"):
		tile_background.regenerate(new_seed)

# ============================================
# CHALLENGE MODE SETUP
# ============================================

func _setup_challenge_mode() -> void:
	"""Initialize challenge mode controller if in challenge mode."""
	if not DifficultyManager or not DifficultyManager.is_challenge_mode():
		return

	# Swap background texture for challenge mode
	var background = get_node_or_null("Background")
	if background and background is Sprite2D and challenge_bg_texture:
		background.texture = challenge_bg_texture

	# Find the spawners
	var enemy_spawner = get_node_or_null("EnemySpawner")
	var elite_spawner = get_node_or_null("EliteSpawner")

	if not enemy_spawner or not elite_spawner:
		push_warning("Challenge mode: Could not find spawners")
		return

	# Create the challenge controller
	challenge_controller = Node.new()
	challenge_controller.set_script(challenge_controller_script)
	challenge_controller.name = "ChallengeController"
	add_child(challenge_controller)

	# Setup with references
	if challenge_controller.has_method("setup"):
		challenge_controller.setup(enemy_spawner, elite_spawner, player)
