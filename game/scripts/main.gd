extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var ability_selection: CanvasLayer = $AbilitySelection
@onready var item_pickup_ui: CanvasLayer = $ItemPickupUI

var game_over_scene: PackedScene = preload("res://scenes/game_over.tscn")
var game_time: float = 0.0
var kill_count: int = 0

# Track dropped items for proximity detection
var nearby_item: Node2D = null

func _ready() -> void:
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

func _process(delta: float) -> void:
	game_time += delta

	# Update equipment manager with current game time
	if EquipmentManager:
		EquipmentManager.update_game_time(game_time)

	# Check for nearby dropped items
	_check_nearby_items()

func _on_player_level_up(new_level: int) -> void:
	# Get random abilities and show selection
	var choices = AbilityManager.get_random_abilities(3)
	if choices.size() > 0:
		ability_selection.show_choices(choices)

func _on_player_died() -> void:
	# Wait for death animation then show game over
	await get_tree().create_timer(2.5).timeout
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
