extends CanvasLayer

signal item_equipped(item: ItemData)
signal item_picked_up(item: ItemData)

var current_dropped_item: DroppedItem = null
var current_item: ItemData = null

@onready var panel: PanelContainer = $Panel
@onready var item_display: VBoxContainer = $Panel/HBoxContainer/ItemDisplay
@onready var comparison_display: VBoxContainer = $Panel/HBoxContainer/ComparisonDisplay
@onready var equip_button: Button = $Panel/HBoxContainer/ItemDisplay/ButtonContainer/EquipButton
@onready var pickup_button: Button = $Panel/HBoxContainer/ItemDisplay/ButtonContainer/PickupButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	equip_button.pressed.connect(_on_equip_pressed)
	pickup_button.pressed.connect(_on_pickup_pressed)

func show_item(dropped_item: DroppedItem) -> void:
	current_dropped_item = dropped_item
	current_item = dropped_item.get_item_data()

	if current_item == null:
		return

	# Build the display
	_build_item_display()
	_build_comparison_display()

	# Update button states
	_update_buttons()

	# Show and pause
	visible = true
	get_tree().paused = true

func hide_ui() -> void:
	visible = false
	get_tree().paused = false
	current_dropped_item = null
	current_item = null

func _build_item_display() -> void:
	# Clear existing content (except buttons)
	for child in item_display.get_children():
		if child.name != "ButtonContainer":
			child.queue_free()

	# Wait for nodes to be freed
	await get_tree().process_frame

	# Create new content
	var content = _create_item_card(current_item, true)
	item_display.add_child(content)
	item_display.move_child(content, 0)

func _build_comparison_display() -> void:
	# Clear existing content
	for child in comparison_display.get_children():
		child.queue_free()

	# Get currently equipped item in this slot
	var character_id = CharacterManager.selected_character_id if CharacterManager else "archer"
	var equipped = EquipmentManager.get_equipped_item(character_id, current_item.slot) if EquipmentManager else null

	if equipped == null:
		# No item equipped - show "Empty Slot"
		var empty_label = Label.new()
		empty_label.text = "Empty Slot"
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		comparison_display.add_child(empty_label)
	else:
		# Show equipped item with comparison
		var equipped_card = _create_item_card(equipped, false)
		comparison_display.add_child(equipped_card)

		# Add comparison stats
		var comparison = EquipmentManager.compare_items(current_item, equipped)
		var comparison_card = _create_comparison_card(comparison)
		comparison_display.add_child(comparison_card)

func _create_item_card(item: ItemData, is_new: bool) -> Control:
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)

	# Header with "NEW!" or "EQUIPPED"
	var header_label = Label.new()
	header_label.text = "NEW ITEM!" if is_new else "CURRENTLY EQUIPPED"
	header_label.add_theme_font_size_override("font_size", 14)
	header_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(header_label)

	# Item icon container
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(80, 80)

	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		icon_container.add_child(icon)

	card.add_child(icon_container)

	# Item name with rarity color
	var name_label = Label.new()
	name_label.text = item.get_full_name()
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(name_label)

	# Rarity and slot
	var info_label = Label.new()
	info_label.text = "%s %s" % [item.get_rarity_name(), item.get_slot_name()]
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", item.get_rarity_color())
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(info_label)

	# Separator
	var separator = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = item.get_rarity_color()
	sep_style.thickness = 2
	separator.add_theme_stylebox_override("separator", sep_style)
	card.add_child(separator)

	# Stats
	var stats_label = Label.new()
	stats_label.text = item.get_stat_description()
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(stats_label)

	# Description (if any)
	if item.description != "":
		var desc_label = Label.new()
		desc_label.text = "\"%s\"" % item.description
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(desc_label)

	return card

func _create_comparison_card(comparison: Dictionary) -> Control:
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)

	var header = Label.new()
	header.text = "STAT CHANGES"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(header)

	for stat in comparison:
		var data = comparison[stat]
		var diff = data.diff

		if abs(diff) < 0.001:
			continue  # Skip unchanged stats

		var stat_container = HBoxContainer.new()

		# Stat name
		var stat_name = Label.new()
		stat_name.text = stat.replace("_", " ").capitalize()
		stat_name.add_theme_font_size_override("font_size", 14)
		stat_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_container.add_child(stat_name)

		# Arrow and value
		var arrow_label = Label.new()
		var arrow = "^" if diff > 0 else "v"
		var color = Color(0.3, 0.9, 0.3) if diff > 0 else Color(0.9, 0.3, 0.3)

		# Format value
		var value_str = ""
		if stat in ["crit_chance", "dodge_chance", "block_chance", "attack_speed",
					"move_speed", "damage", "max_hp", "xp_gain", "luck", "damage_reduction"]:
			value_str = "%s%d%%" % ["+" if diff > 0 else "", int(diff * 100)]
		else:
			value_str = "%s%d" % ["+" if diff > 0 else "", int(diff)]

		arrow_label.text = "%s %s" % [arrow, value_str]
		arrow_label.add_theme_font_size_override("font_size", 14)
		arrow_label.add_theme_color_override("font_color", color)
		stat_container.add_child(arrow_label)

		card.add_child(stat_container)

	return card

func _update_buttons() -> void:
	if current_item == null:
		return

	# Check if item can be equipped by current character
	var character_id = CharacterManager.selected_character_id if CharacterManager else "archer"
	var can_equip = current_item.can_be_equipped_by(character_id)

	equip_button.disabled = not can_equip

	if not can_equip:
		equip_button.text = "Wrong Class"
		equip_button.tooltip_text = "This item cannot be used by your current character"
	else:
		equip_button.text = "Equip"
		equip_button.tooltip_text = ""

func _on_equip_pressed() -> void:
	if current_dropped_item == null or current_item == null:
		return

	var character_id = CharacterManager.selected_character_id if CharacterManager else "archer"

	# Add to pending and equip
	EquipmentManager.add_pending_item(current_item)
	EquipmentManager.equip_item(current_item.id, character_id, current_item.slot)

	# Play sound
	if SoundManager:
		SoundManager.play_buff()

	# Remove the world item
	current_dropped_item.queue_free()

	emit_signal("item_equipped", current_item)
	hide_ui()

func _on_pickup_pressed() -> void:
	if current_dropped_item == null or current_item == null:
		return

	# Just add to pending inventory
	EquipmentManager.add_pending_item(current_item)

	# Play sound
	if SoundManager:
		SoundManager.play_xp()

	# Remove the world item
	current_dropped_item.queue_free()

	emit_signal("item_picked_up", current_item)
	hide_ui()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# ESC to close without picking up
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			hide_ui()
		elif event.keycode == KEY_E:
			if not equip_button.disabled:
				_on_equip_pressed()
		elif event.keycode == KEY_P or event.keycode == KEY_SPACE:
			_on_pickup_pressed()
