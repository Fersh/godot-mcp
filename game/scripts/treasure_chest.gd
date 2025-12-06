extends Area2D

## Treasure Chest - Spawns once per map with random loot

signal opened(reward_type: String, reward_data: Dictionary)

@export var chest_textures: Array[String] = [
	"res://assets/enviro/gowl/Rocks and Chest/Chest/IronChest/1.png",
	"res://assets/enviro/gowl/Rocks and Chest/Chest/IronChest/2.png",
	"res://assets/enviro/gowl/Rocks and Chest/Chest/IronChest/3.png"
]

var is_opened: bool = false
var sprite: Sprite2D = null
var current_frame: int = 0

# Reward chances
const COIN_CHANCE: float = 0.4      # 40% coins
const ITEM_CHANCE: float = 0.35     # 35% equipment item
const ABILITY_CHANCE: float = 0.25  # 25% random ability

func _ready() -> void:
	add_to_group("chests")

	# Setup collision
	collision_layer = 0
	collision_mask = 1  # Detect player

	# Use absolute z_index (not relative to parent TileBackground which has z_index = -10)
	z_as_relative = false

	# Create sprite
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(2.5, 2.5)  # Scale up to match game art style
	if ResourceLoader.exists(chest_textures[0]):
		sprite.texture = load(chest_textures[0])
		print("TreasureChest: Loaded texture successfully")
	else:
		push_error("TreasureChest: Could not find texture at " + chest_textures[0])
	add_child(sprite)

	# Create collision shape (scaled to match sprite)
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 40)  # Larger collision to match scaled sprite
	collision.shape = shape
	collision.position = Vector2(0, 4)
	add_child(collision)

	# Connect body entered signal
	body_entered.connect(_on_body_entered)

	# Set z-index based on Y position
	z_index = int(global_position.y / 10)

func _on_body_entered(body: Node2D) -> void:
	if is_opened:
		return

	if not body.is_in_group("player"):
		return

	# Open the chest!
	open_chest()

func open_chest() -> void:
	if is_opened:
		return
	is_opened = true

	# Play opening animation
	_play_open_animation()

func _play_open_animation() -> void:
	# Animate through chest frames
	var tween = create_tween()

	# Frame 1 -> 2
	tween.tween_callback(_set_frame.bind(1)).set_delay(0.1)
	# Frame 2 -> 3
	tween.tween_callback(_set_frame.bind(2)).set_delay(0.15)
	# Give reward after animation
	tween.tween_callback(_give_reward).set_delay(0.2)

func _set_frame(frame_index: int) -> void:
	if sprite and frame_index < chest_textures.size():
		if ResourceLoader.exists(chest_textures[frame_index]):
			sprite.texture = load(chest_textures[frame_index])
		current_frame = frame_index

func _give_reward() -> void:
	# Determine reward type
	var roll = randf()
	var reward_type: String
	var reward_data: Dictionary = {}

	if roll < COIN_CHANCE:
		# Coin reward
		reward_type = "coins"
		reward_data = _generate_coin_reward()
	elif roll < COIN_CHANCE + ITEM_CHANCE:
		# Equipment item
		reward_type = "item"
		reward_data = _generate_item_reward()
	else:
		# Random ability
		reward_type = "ability"
		reward_data = _generate_ability_reward()

	# Emit signal for popup
	opened.emit(reward_type, reward_data)

	# Show treasure popup
	_show_treasure_popup(reward_type, reward_data)

func _generate_coin_reward() -> Dictionary:
	# Generate 50-200 coins
	var amount = randi_range(50, 200)
	return {"amount": amount}

func _generate_item_reward() -> Dictionary:
	# Use EquipmentManager to generate an item
	if EquipmentManager:
		var item = EquipmentManager.generate_item("elite")  # Elite tier loot
		return {"item": item}
	return {"item": null}

func _generate_ability_reward() -> Dictionary:
	# Get a random passive ability
	if AbilityManager:
		var available = AbilityManager.get_available_abilities()
		if available.size() > 0:
			var random_ability = available[randi() % available.size()]
			return {"ability_id": random_ability.id, "ability_name": random_ability.name}
	return {"ability_id": "", "ability_name": ""}

func _show_treasure_popup(reward_type: String, reward_data: Dictionary) -> void:
	# Pause the game
	get_tree().paused = true

	# Create popup
	var popup = _create_treasure_popup(reward_type, reward_data)

	# Add to scene tree (CanvasLayer ignores pause)
	get_tree().root.add_child(popup)

func _create_treasure_popup(reward_type: String, reward_data: Dictionary) -> CanvasLayer:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS  # Ignore pause

	var pixel_font: Font = null
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Main container
	var panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.add_child(panel)

	# Dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.85)
	panel.add_child(overlay)

	# Dialog container
	var dialog = PanelContainer.new()
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.custom_minimum_size = Vector2(400, 350)
	dialog.offset_left = -200
	dialog.offset_right = 200
	dialog.offset_top = -175
	dialog.offset_bottom = 175

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.2, 0.98)
	style.border_color = Color(0.9, 0.7, 0.2, 1)  # Gold border
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	dialog.add_theme_stylebox_override("panel", style)
	panel.add_child(dialog)

	# Content VBox
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	dialog.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "TREASURE FOUND!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.add_theme_color_override("font_shadow_color", Color(0.4, 0.3, 0, 1))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title)

	# Reward content based on type
	match reward_type:
		"coins":
			# Coins display with icon
			var coins_container = HBoxContainer.new()
			coins_container.alignment = BoxContainer.ALIGNMENT_CENTER
			coins_container.add_theme_constant_override("separation", 15)
			vbox.add_child(coins_container)

			# Coin icon (use the same gold coin sprite enemies drop)
			var coin_icon = TextureRect.new()
			if ResourceLoader.exists("res://assets/sprites/icons/raven/32x32/fb171.png"):
				var coin_tex = load("res://assets/sprites/icons/raven/32x32/fb171.png")
				coin_icon.texture = coin_tex
			coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			coin_icon.custom_minimum_size = Vector2(64, 64)
			coins_container.add_child(coin_icon)

			# Coin amount label
			var coin_label = Label.new()
			coin_label.text = "%d" % reward_data.get("amount", 0)
			if pixel_font:
				coin_label.add_theme_font_override("font", pixel_font)
			coin_label.add_theme_font_size_override("font_size", 28)
			coin_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
			coins_container.add_child(coin_label)

			_give_coins(reward_data.get("amount", 0))

		"item":
			var item = reward_data.get("item")
			if item:
				# Item icon
				if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
					var item_icon = TextureRect.new()
					item_icon.texture = load(item.icon_path)
					item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					item_icon.custom_minimum_size = Vector2(80, 80)
					var icon_container = CenterContainer.new()
					icon_container.add_child(item_icon)
					vbox.add_child(icon_container)

				# Item name
				var item_name = item.get_full_name() if item.has_method("get_full_name") else item.display_name
				var name_label = Label.new()
				name_label.text = item_name
				name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				if pixel_font:
					name_label.add_theme_font_override("font", pixel_font)
				name_label.add_theme_font_size_override("font_size", 16)
				name_label.add_theme_color_override("font_color", item.get_rarity_color() if item.has_method("get_rarity_color") else Color.WHITE)
				vbox.add_child(name_label)

				# Item stats in a scroll container
				var stats_scroll = ScrollContainer.new()
				stats_scroll.custom_minimum_size = Vector2(340, 80)
				stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
				vbox.add_child(stats_scroll)

				var stats_label = Label.new()
				stats_label.text = item.get_stat_description() if item.has_method("get_stat_description") else ""
				stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				if pixel_font:
					stats_label.add_theme_font_override("font", pixel_font)
				stats_label.add_theme_font_size_override("font_size", 10)
				stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				stats_scroll.add_child(stats_label)

				canvas.set_meta("pending_item", item)
			else:
				# Fallback to coins
				var fallback_label = Label.new()
				fallback_label.text = "50 GOLD COINS!"
				fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				if pixel_font:
					fallback_label.add_theme_font_override("font", pixel_font)
				fallback_label.add_theme_font_size_override("font_size", 14)
				fallback_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
				vbox.add_child(fallback_label)
				_give_coins(50)

		"ability":
			var ability_name = reward_data.get("ability_name", "")
			var ability_label = Label.new()
			ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if pixel_font:
				ability_label.add_theme_font_override("font", pixel_font)
			ability_label.add_theme_font_size_override("font_size", 14)

			if ability_name != "":
				ability_label.text = "NEW ABILITY:\n%s" % ability_name
				ability_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
				var ability_id = reward_data.get("ability_id", "")
				if ability_id != "" and AbilityManager:
					AbilityManager.acquire_ability(ability_id)
			else:
				ability_label.text = "75 GOLD COINS!"
				ability_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
				_give_coins(75)
			vbox.add_child(ability_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Sweet button
	var sweet_btn = Button.new()
	sweet_btn.text = "Sweet!"
	sweet_btn.custom_minimum_size = Vector2(180, 55)
	_style_golden_button(sweet_btn, pixel_font)
	sweet_btn.pressed.connect(_on_sweet_pressed.bind(canvas))
	vbox.add_child(sweet_btn)

	return canvas

func _give_coins(amount: int) -> void:
	# Give coins to player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_gold"):
		player.add_gold(amount)

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.7, 0.7, 0.7)
		"uncommon": return Color(0.3, 0.9, 0.3)
		"rare": return Color(0.3, 0.5, 1.0)
		"epic": return Color(0.7, 0.3, 0.9)
		"legendary": return Color(1.0, 0.7, 0.2)
		_: return Color.WHITE

func _on_sweet_pressed(popup: CanvasLayer) -> void:
	if SoundManager:
		SoundManager.play_click()

	# Check for pending item
	if popup.has_meta("pending_item"):
		var item = popup.get_meta("pending_item")
		if item and EquipmentManager:
			# Add to inventory or equip
			EquipmentManager.add_pending_item(item)

	# Resume game
	get_tree().paused = false

	# Remove popup
	popup.queue_free()

func _style_golden_button(button: Button, pixel_font: Font) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.85, 0.65, 0.2, 1)
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 6
	style_normal.border_color = Color(0.45, 0.3, 0.15, 1)
	style_normal.set_corner_radius_all(8)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.92, 0.72, 0.25, 1)
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 6
	style_hover.border_color = Color(0.5, 0.35, 0.18, 1)
	style_hover.set_corner_radius_all(8)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
