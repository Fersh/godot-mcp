extends CanvasLayer

# Missions Screen - Displays daily, challenges, and social missions

# UI References
var header: PanelContainer
var back_button: Button
var title_label: Label
var coin_label: Label
var tab_container: HBoxContainer
var scroll_container: ScrollContainer
var content_vbox: VBoxContainer

# Tabs
var tab_daily: Button
var tab_challenges: Button
var current_tab: int = 0  # 0=Daily, 1=Achievements

# Reward celebration modal
var reward_modal: Control = null

# Fonts
var pixel_font: Font = null
var pixelify_font: Font = null

const CONTAINER_WIDTH: float = 600.0
const PROGRESS_BAR_WIDTH: float = 200.0

# Tab colors
const TAB_COLORS = {
	0: Color(0.3, 0.7, 0.95),   # Daily - Blue
	1: Color(0.9, 0.7, 0.2),    # Achievements - Gold
}

# Hidden social missions (for now)
const HIDDEN_SOCIAL_MISSIONS = ["rate_game", "youtube_sub"]

func _ready() -> void:
	# Load fonts
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
	if ResourceLoader.exists("res://assets/fonts/Pixelify_Sans/static/PixelifySans-Bold.ttf"):
		pixelify_font = load("res://assets/fonts/Pixelify_Sans/static/PixelifySans-Bold.ttf")

	_build_ui()
	_show_tab(0)

	# Keep menu music playing
	if SoundManager:
		SoundManager.play_menu_music()

	# Connect to mission signals
	if MissionsManager:
		MissionsManager.mission_completed.connect(_on_mission_completed)
		MissionsManager.reward_claimed.connect(_on_reward_claimed)

func _build_ui() -> void:
	# Background image
	var background = TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/menu6.png"):
		background.texture = load("res://assets/menu6.png")
	add_child(background)

	# Dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.65)
	add_child(overlay)

	# Main VBox container
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)

	# Header panel
	header = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 95)
	_style_header()
	main_vbox.add_child(header)

	# Title centered in header
	title_label = Label.new()
	title_label.text = "MISSIONS"
	title_label.set_anchors_preset(Control.PRESET_CENTER)
	title_label.offset_left = -100
	title_label.offset_right = 100
	title_label.offset_top = 5
	title_label.offset_bottom = 35
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title_label)

	# Coin display (top right of screen, not inside header)
	var viewport_size = get_viewport().get_visible_rect().size
	var coin_container = HBoxContainer.new()
	coin_container.position = Vector2(viewport_size.x - 140, 30)
	coin_container.add_theme_constant_override("separation", 6)
	add_child(coin_container)

	var coin_icon = Label.new()
	coin_icon.text = "●"
	if pixel_font:
		coin_icon.add_theme_font_override("font", pixel_font)
	coin_icon.add_theme_font_size_override("font_size", 22)
	coin_icon.add_theme_color_override("font_color", Color(1, 0.84, 0))
	coin_icon.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	coin_icon.add_theme_constant_override("shadow_offset_x", 2)
	coin_icon.add_theme_constant_override("shadow_offset_y", 2)
	coin_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_container.add_child(coin_icon)

	coin_label = Label.new()
	coin_label.text = "0"
	if pixel_font:
		coin_label.add_theme_font_override("font", pixel_font)
	coin_label.add_theme_font_size_override("font_size", 18)
	coin_label.add_theme_color_override("font_color", Color.WHITE)
	coin_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	coin_label.add_theme_constant_override("shadow_offset_x", 2)
	coin_label.add_theme_constant_override("shadow_offset_y", 2)
	coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_container.add_child(coin_label)
	_update_coin_display()

	# Back button
	back_button = Button.new()
	back_button.text = "< BACK"
	back_button.offset_left = 100
	back_button.offset_top = 25
	back_button.offset_right = 190
	back_button.offset_bottom = 70
	back_button.pressed.connect(_on_back_pressed)
	_style_back_button(back_button)
	add_child(back_button)

	# Tab container
	tab_container = HBoxContainer.new()
	tab_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_container.add_theme_constant_override("separation", 10)
	main_vbox.add_child(tab_container)

	# Padding before tabs
	var tab_spacer = Control.new()
	tab_spacer.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(tab_spacer)

	# Create tabs (only Daily and Achievements now - Social moved into Daily)
	tab_daily = _create_tab_button("DAILY", 0)
	tab_challenges = _create_tab_button("ACHIEVEMENTS", 1)
	tab_container.add_child(tab_daily)
	tab_container.add_child(tab_challenges)

	# Scrollable content area
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll_container)

	# Content container
	content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 15)
	scroll_container.add_child(content_vbox)

func _create_tab_button(text: String, tab_index: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(160, 45)  # Wider for more padding
	btn.pressed.connect(func(): _show_tab(tab_index))

	if pixel_font:
		btn.add_theme_font_override("font", pixel_font)
	btn.add_theme_font_size_override("font_size", 12)

	_style_tab_button(btn, tab_index, tab_index == current_tab)
	return btn

func _style_tab_button(button: Button, tab_index: int, is_active: bool) -> void:
	var color = TAB_COLORS[tab_index]

	var style_normal = StyleBoxFlat.new()
	if is_active:
		style_normal.bg_color = color
		style_normal.border_color = color.darkened(0.3)
	else:
		style_normal.bg_color = Color(0.2, 0.2, 0.25, 0.8)
		style_normal.border_color = Color(0.3, 0.3, 0.35, 1)
	style_normal.set_border_width_all(2)
	style_normal.border_width_bottom = 4
	style_normal.set_corner_radius_all(6)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = color.lightened(0.1) if is_active else Color(0.3, 0.3, 0.35, 0.9)
	style_hover.border_color = style_normal.border_color
	style_hover.set_border_width_all(2)
	style_hover.border_width_bottom = 4
	style_hover.set_corner_radius_all(6)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

	var font_color = Color.WHITE if is_active else Color(0.7, 0.7, 0.7)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)

func _show_tab(tab_index: int) -> void:
	current_tab = tab_index

	# Update tab button styles
	_style_tab_button(tab_daily, 0, tab_index == 0)
	_style_tab_button(tab_challenges, 1, tab_index == 1)

	# Clear content
	for child in content_vbox.get_children():
		child.queue_free()

	# Padding at top
	var top_pad = Control.new()
	top_pad.custom_minimum_size = Vector2(0, 15)
	content_vbox.add_child(top_pad)

	# Show relevant missions
	match tab_index:
		0:
			_show_daily_missions()
		1:
			_show_challenge_missions()

	# Bottom padding
	var bottom_pad = Control.new()
	bottom_pad.custom_minimum_size = Vector2(0, 40)
	content_vbox.add_child(bottom_pad)

	if SoundManager:
		SoundManager.play_click()

func _show_daily_missions() -> void:
	# Check for ANY claimable missions (daily or social) and show at top
	if MissionsManager:
		var claimable: Array = []
		for mission in MissionsManager.get_active_daily_missions():
			if mission.is_completed and not mission.is_claimed:
				claimable.append(mission)
		for mission in MissionsManager.get_all_social_missions():
			if mission.is_completed and not mission.is_claimed:
				claimable.append(mission)

		if claimable.size() > 0:
			var claim_header = _create_section_header("READY TO CLAIM (%d)" % claimable.size(), Color(0.3, 0.9, 0.4))
			content_vbox.add_child(claim_header)

			# Claim All button for daily tab
			if claimable.size() > 1:
				var claim_all_container = HBoxContainer.new()
				claim_all_container.alignment = BoxContainer.ALIGNMENT_CENTER
				content_vbox.add_child(claim_all_container)

				var claim_all_btn = Button.new()
				claim_all_btn.text = "CLAIM ALL"
				claim_all_btn.custom_minimum_size = Vector2(150, 45)
				_style_green_button(claim_all_btn)
				claim_all_btn.pressed.connect(_on_claim_all_pressed)
				claim_all_container.add_child(claim_all_btn)

				var sep_btn = Control.new()
				sep_btn.custom_minimum_size = Vector2(0, 10)
				content_vbox.add_child(sep_btn)

			for mission in claimable:
				_add_mission_card(mission)
			var sep0 = Control.new()
			sep0.custom_minimum_size = Vector2(0, 15)
			content_vbox.add_child(sep0)

	# Daily login section first
	_add_daily_login_section()

	# Separator
	var sep = Control.new()
	sep.custom_minimum_size = Vector2(0, 10)
	content_vbox.add_child(sep)

	# Daily missions header
	var header_label = _create_section_header("TODAY'S MISSIONS", TAB_COLORS[0])
	content_vbox.add_child(header_label)

	# Show active daily missions
	if MissionsManager:
		# Force refresh daily missions if none are active
		if MissionsManager.active_daily_missions.is_empty():
			MissionsManager._check_daily_refresh()

		var daily = MissionsManager.get_active_daily_missions()
		if daily.is_empty():
			_add_empty_message("No daily missions - try restarting the game")
		else:
			for mission in daily:
				_add_mission_card(mission)
	else:
		_add_empty_message("Missions system not loaded")

	# Social missions section (below daily)
	_add_social_section()

func _add_daily_login_section() -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(CONTAINER_WIDTH + 40, 0)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.25, 0.95)
	style.border_color = Color(0.3, 0.5, 0.8, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "DAILY LOGIN BONUS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	vbox.add_child(title)

	if DailyLoginManager:
		var can_claim = DailyLoginManager.can_claim_reward()
		var reward = DailyLoginManager.get_today_reward()
		var streak = DailyLoginManager.get_streak()

		# Streak info
		var streak_label = Label.new()
		streak_label.text = "Current Streak: %d day%s" % [streak, "s" if streak != 1 else ""]
		streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if pixel_font:
			streak_label.add_theme_font_override("font", pixel_font)
		streak_label.add_theme_font_size_override("font_size", 11)
		streak_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		vbox.add_child(streak_label)

		# Day indicator (7 dots)
		var day_container = HBoxContainer.new()
		day_container.alignment = BoxContainer.ALIGNMENT_CENTER
		day_container.add_theme_constant_override("separation", 8)
		vbox.add_child(day_container)

		var preview = DailyLoginManager.get_week_preview()
		for i in range(7):
			var day_data = preview[i]
			var dot = ColorRect.new()
			dot.custom_minimum_size = Vector2(24, 24)

			if day_data["is_claimed"]:
				dot.color = Color(0.3, 0.8, 0.4)  # Green - claimed
			elif day_data["is_today"]:
				dot.color = Color(1.0, 0.85, 0.2)  # Gold - today
			else:
				dot.color = Color(0.3, 0.3, 0.35)  # Gray - future

			day_container.add_child(dot)

		# Today's reward
		var reward_text = "Day %d: " % reward["day_in_cycle"]
		if reward["total_coins"] > 0:
			reward_text += "%d coins" % reward["total_coins"]
		if reward["special"] == "random_passive":
			reward_text += " + Random Ability"
		elif reward["special"] == "jackpot":
			reward_text += " JACKPOT!"

		var reward_label = Label.new()
		reward_label.text = reward_text
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if pixel_font:
			reward_label.add_theme_font_override("font", pixel_font)
		reward_label.add_theme_font_size_override("font_size", 12)
		reward_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		vbox.add_child(reward_label)

		# Claim button
		if can_claim:
			var claim_btn = Button.new()
			claim_btn.text = "CLAIM REWARD"
			claim_btn.custom_minimum_size = Vector2(200, 45)
			_style_golden_button(claim_btn)
			claim_btn.pressed.connect(_on_claim_daily_pressed)
			vbox.add_child(claim_btn)
		else:
			var claimed_label = Label.new()
			claimed_label.text = "Come back tomorrow!"
			claimed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if pixel_font:
				claimed_label.add_theme_font_override("font", pixel_font)
			claimed_label.add_theme_font_size_override("font_size", 11)
			claimed_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
			vbox.add_child(claimed_label)
	else:
		var error_label = Label.new()
		error_label.text = "Login system not loaded"
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if pixel_font:
			error_label.add_theme_font_override("font", pixel_font)
		error_label.add_theme_font_size_override("font_size", 11)
		error_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(error_label)

	content_vbox.add_child(panel)

func _show_challenge_missions() -> void:
	if not MissionsManager:
		_add_empty_message("Missions system not loaded")
		return

	# Progress header
	var completed = MissionsManager.get_completed_count()
	var total = MissionsManager.get_total_permanent_count()
	var progress_label = _create_section_header("PROGRESS: %d/%d" % [completed, total], TAB_COLORS[1])
	content_vbox.add_child(progress_label)

	# READY TO CLAIM section - show claimable missions at the top
	var claimable_missions: Array = []
	for mission in MissionsManager.get_all_permanent_missions():
		if mission.is_completed and not mission.is_claimed:
			claimable_missions.append(mission)

	if claimable_missions.size() > 0:
		var claim_header = _create_section_header("READY TO CLAIM (%d)" % claimable_missions.size(), Color(0.3, 0.9, 0.4))
		content_vbox.add_child(claim_header)

		# Claim All button for achievements tab
		if claimable_missions.size() > 1:
			var claim_all_container = HBoxContainer.new()
			claim_all_container.alignment = BoxContainer.ALIGNMENT_CENTER
			content_vbox.add_child(claim_all_container)

			var claim_all_btn = Button.new()
			claim_all_btn.text = "CLAIM ALL"
			claim_all_btn.custom_minimum_size = Vector2(150, 45)
			_style_green_button(claim_all_btn)
			claim_all_btn.pressed.connect(_on_claim_all_pressed)
			claim_all_container.add_child(claim_all_btn)

			var sep_btn = Control.new()
			sep_btn.custom_minimum_size = Vector2(0, 10)
			content_vbox.add_child(sep_btn)

		for mission in claimable_missions:
			_add_mission_card(mission)

		# Separator
		var sep = Control.new()
		sep.custom_minimum_size = Vector2(0, 20)
		content_vbox.add_child(sep)

	# Get all permanent missions grouped by type
	var missions_by_type: Dictionary = {}
	for mission in MissionsManager.get_all_permanent_missions():
		var type_name = _get_type_display_name(mission.type)
		if not missions_by_type.has(type_name):
			missions_by_type[type_name] = []
		missions_by_type[type_name].append(mission)

	# Display missions by category
	var type_order = ["Kill", "Elite", "Boss", "Enemy", "Difficulty", "Character", "Survival", "Economy", "Misc"]
	for type_name in type_order:
		if missions_by_type.has(type_name):
			var type_header = _create_subsection_header(type_name.to_upper())
			content_vbox.add_child(type_header)

			for mission in missions_by_type[type_name]:
				if not mission.is_secret or mission.is_completed:  # Hide secrets until completed
					_add_mission_card(mission)

func _add_social_section() -> void:
	"""Add social missions section below daily missions."""
	if not MissionsManager:
		return

	# Get visible social missions (filter out hidden ones, unless they're completed)
	var social_missions = []
	for mission in MissionsManager.get_all_social_missions():
		# Show if not hidden, or if completed (so it can be claimed)
		if mission.id not in HIDDEN_SOCIAL_MISSIONS or mission.is_completed:
			social_missions.append(mission)

	if social_missions.is_empty():
		return

	# Separator
	var sep = Control.new()
	sep.custom_minimum_size = Vector2(0, 15)
	content_vbox.add_child(sep)

	# Social header
	var header_label = _create_section_header("SOCIAL REWARDS", Color(0.95, 0.5, 0.7))
	content_vbox.add_child(header_label)

	var desc_label = Label.new()
	desc_label.text = "Follow us for bonus rewards!"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		desc_label.add_theme_font_override("font", pixel_font)
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	content_vbox.add_child(desc_label)

	# Show social missions
	for mission in social_missions:
		_add_social_mission_card(mission)

func _add_mission_card(mission: MissionData) -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(CONTAINER_WIDTH + 40, 0)

	var style = StyleBoxFlat.new()
	if mission.is_completed and not mission.is_claimed:
		style.bg_color = Color(0.15, 0.25, 0.15, 0.95)  # Green tint - ready to claim
		style.border_color = Color(0.3, 0.8, 0.4, 1)
	elif mission.is_claimed:
		style.bg_color = Color(0.1, 0.1, 0.12, 0.7)  # Darker - claimed
		style.border_color = Color(0.25, 0.25, 0.3, 1)
	else:
		style.bg_color = Color(0.1, 0.1, 0.15, 0.95)  # Normal
		style.border_color = Color(0.25, 0.25, 0.35, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Title row
	var title_row = HBoxContainer.new()
	vbox.add_child(title_row)

	var title = Label.new()
	title.text = mission.title
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color.WHITE if not mission.is_claimed else Color(0.6, 0.6, 0.6))
	title_row.add_child(title)

	# Status/reward
	var status = Label.new()
	if mission.is_claimed:
		status.text = "CLAIMED"
		status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	elif mission.is_completed:
		status.text = "COMPLETE!"
		status.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	else:
		status.text = "$%d" % mission.reward_coins if mission.reward_coins > 0 else ""
		status.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	if pixel_font:
		status.add_theme_font_override("font", pixel_font)
	status.add_theme_font_size_override("font_size", 11)
	title_row.add_child(status)

	# Description
	var desc = Label.new()
	desc.text = mission.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if pixel_font:
		desc.add_theme_font_override("font", pixel_font)
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if not mission.is_claimed else Color(0.4, 0.4, 0.4))
	vbox.add_child(desc)

	# Progress bar (if not instant)
	if mission.tracking_mode != MissionData.TrackingMode.INSTANT and not mission.is_claimed:
		var progress_row = HBoxContainer.new()
		progress_row.add_theme_constant_override("separation", 10)
		vbox.add_child(progress_row)

		var bar = _create_progress_bar(mission.get_progress_percent())
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_row.add_child(bar)

		var progress_text = Label.new()
		progress_text.text = mission.get_progress_text()
		progress_text.custom_minimum_size = Vector2(80, 0)
		progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if pixel_font:
			progress_text.add_theme_font_override("font", pixel_font)
		progress_text.add_theme_font_size_override("font_size", 10)
		progress_text.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		progress_row.add_child(progress_text)

	# Claim button if completed but not claimed
	if mission.is_completed and not mission.is_claimed:
		var claim_btn = Button.new()
		claim_btn.text = "CLAIM"
		claim_btn.custom_minimum_size = Vector2(120, 35)
		_style_green_button(claim_btn)
		claim_btn.pressed.connect(func(): _on_claim_mission_pressed(mission.id))
		vbox.add_child(claim_btn)

	content_vbox.add_child(panel)

func _add_social_mission_card(mission: MissionData) -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(CONTAINER_WIDTH + 40, 0)

	var style = StyleBoxFlat.new()
	if mission.is_completed and not mission.is_claimed:
		style.bg_color = Color(0.15, 0.25, 0.15, 0.95)
		style.border_color = Color(0.3, 0.8, 0.4, 1)
	elif mission.is_claimed:
		style.bg_color = Color(0.1, 0.1, 0.12, 0.7)
		style.border_color = Color(0.25, 0.25, 0.3, 1)
	else:
		style.bg_color = Color(0.15, 0.1, 0.18, 0.95)
		style.border_color = Color(0.4, 0.25, 0.45, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	# Info column
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(info_vbox)

	var title = Label.new()
	title.text = mission.title
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color.WHITE if not mission.is_claimed else Color(0.5, 0.5, 0.5))
	info_vbox.add_child(title)

	var desc = Label.new()
	desc.text = mission.description
	if pixel_font:
		desc.add_theme_font_override("font", pixel_font)
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_vbox.add_child(desc)

	var reward = Label.new()
	reward.text = "Reward: $%d" % mission.reward_coins
	if pixel_font:
		reward.add_theme_font_override("font", pixel_font)
	reward.add_theme_font_size_override("font_size", 10)
	reward.add_theme_color_override("font_color", Color(1, 0.85, 0.2) if not mission.is_claimed else Color(0.4, 0.4, 0.3))
	info_vbox.add_child(reward)

	# Button column
	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(btn_vbox)

	if mission.is_claimed:
		var claimed_label = Label.new()
		claimed_label.text = "DONE"
		if pixel_font:
			claimed_label.add_theme_font_override("font", pixel_font)
		claimed_label.add_theme_font_size_override("font_size", 11)
		claimed_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		btn_vbox.add_child(claimed_label)
	elif mission.is_completed:
		var claim_btn = Button.new()
		claim_btn.text = "CLAIM"
		claim_btn.custom_minimum_size = Vector2(100, 40)
		_style_green_button(claim_btn)
		claim_btn.pressed.connect(func(): _on_claim_mission_pressed(mission.id))
		btn_vbox.add_child(claim_btn)
	else:
		# Link button
		var link_btn = Button.new()
		link_btn.text = "OPEN"
		link_btn.custom_minimum_size = Vector2(100, 40)
		_style_pink_button(link_btn)
		link_btn.pressed.connect(func(): _on_social_link_pressed(mission.id))
		btn_vbox.add_child(link_btn)

	content_vbox.add_child(panel)

func _create_section_header(text: String, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _create_subsection_header(text: String) -> Label:
	var label = Label.new()
	label.text = "-- " + text + " --"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label

func _add_empty_message(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	content_vbox.add_child(label)

func _create_progress_bar(progress: float) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.max_value = 1.0
	bar.value = progress
	bar.show_percentage = false

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.2, 1)
	bg_style.border_color = Color(0.25, 0.25, 0.3, 1)
	bg_style.set_border_width_all(1)
	bg_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.3, 0.7, 0.95, 1)
	fill_style.border_color = Color(0.2, 0.5, 0.7, 1)
	fill_style.set_border_width_all(1)
	fill_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill_style)

	return bar

func _get_type_display_name(type: MissionData.MissionType) -> String:
	match type:
		MissionData.MissionType.KILL: return "Kill"
		MissionData.MissionType.ELITE_KILL: return "Elite"
		MissionData.MissionType.BOSS_KILL: return "Boss"
		MissionData.MissionType.SPECIFIC_ENEMY: return "Enemy"
		MissionData.MissionType.DIFFICULTY: return "Difficulty"
		MissionData.MissionType.CHARACTER: return "Character"
		MissionData.MissionType.SURVIVAL: return "Survival"
		MissionData.MissionType.ABILITY: return "Ability"
		MissionData.MissionType.EQUIPMENT: return "Equipment"
		MissionData.MissionType.ECONOMY: return "Economy"
		MissionData.MissionType.SCORE: return "Score"
		MissionData.MissionType.CURSE: return "Curse"
		MissionData.MissionType.SOCIAL: return "Social"
		MissionData.MissionType.MISC: return "Misc"
		MissionData.MissionType.SECRET: return "Secret"
	return "Other"

# ============================================
# BUTTON HANDLERS
# ============================================

func _on_back_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_claim_daily_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.medium()

	if DailyLoginManager:
		var reward = DailyLoginManager.claim_daily_reward()
		if reward.size() > 0:
			if JuiceManager:
				JuiceManager.shake_medium()
			_update_coin_display()
			_show_tab(0)  # Refresh daily tab

func _on_claim_all_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.heavy()

	if MissionsManager:
		var claimed = MissionsManager.claim_all_unclaimed()
		if claimed > 0:
			if JuiceManager:
				JuiceManager.shake_medium()
			_update_coin_display()
			# Rebuild UI to remove the Claim All button
			get_tree().reload_current_scene()

func _on_claim_mission_pressed(mission_id: String) -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.medium()

	if MissionsManager:
		var mission = MissionsManager.get_mission(mission_id)
		if mission and MissionsManager.claim_reward(mission_id):
			if JuiceManager:
				JuiceManager.shake_medium()
			_update_coin_display()
			_show_reward_celebration(mission)
			_show_tab(current_tab)  # Refresh current tab

func _on_social_link_pressed(mission_id: String) -> void:
	if SoundManager:
		SoundManager.play_click()

	# Open the appropriate URL
	var url = ""
	match mission_id:
		"twitter_follow":
			url = "https://x.com/markfersh"
		"discord_join":
			url = "https://discord.gg/p7pCwc5yJs"
		"rate_game":
			url = "https://apps.apple.com/app/rogue-arena"  # Replace with actual URL
		"youtube_sub":
			url = "https://youtube.com/@RogueArena"  # Replace with actual URL

	if url != "":
		OS.shell_open(url)

	# Mark as completed (honor system)
	if MissionsManager:
		MissionsManager.track_social_action(mission_id)
		_show_tab(current_tab)  # Refresh to show claim button

func _on_mission_completed(_mission: MissionData) -> void:
	# Could show a notification here
	pass

func _on_reward_claimed(_mission: MissionData) -> void:
	_update_coin_display()

func _update_coin_display() -> void:
	if StatsManager and coin_label:
		coin_label.text = _format_number(StatsManager.spendable_coins)

func _format_number(num: int) -> String:
	var str_num = str(num)
	var result = ""
	var count = 0
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	return result

# ============================================
# STYLING
# ============================================

func _style_header() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.content_margin_left = 60
	style.content_margin_right = 60
	header.add_theme_stylebox_override("panel", style)

func _style_back_button(button: Button) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.25, 0.25, 0.3, 1)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 4
	style_normal.border_color = Color(0.15, 0.15, 0.2, 1)
	style_normal.set_corner_radius_all(6)
	style_normal.content_margin_left = 16
	style_normal.content_margin_right = 16

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.35, 0.35, 0.4, 1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 4
	style_hover.border_color = Color(0.2, 0.2, 0.25, 1)
	style_hover.set_corner_radius_all(6)
	style_hover.content_margin_left = 16
	style_hover.content_margin_right = 16

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 14)

func _style_golden_button(button: Button) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.85, 0.65, 0.2, 1)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 4
	style_normal.border_color = Color(0.45, 0.3, 0.15, 1)
	style_normal.set_corner_radius_all(6)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.92, 0.72, 0.25, 1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 4
	style_hover.border_color = Color(0.5, 0.35, 0.18, 1)
	style_hover.set_corner_radius_all(6)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color.WHITE)

func _style_green_button(button: Button) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.7, 0.35, 1)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 4
	style_normal.border_color = Color(0.1, 0.4, 0.2, 1)
	style_normal.set_corner_radius_all(6)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.8, 0.45, 1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 4
	style_hover.border_color = Color(0.15, 0.45, 0.25, 1)
	style_hover.set_corner_radius_all(6)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color.WHITE)

func _style_pink_button(button: Button) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.75, 0.4, 0.6, 1)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 4
	style_normal.border_color = Color(0.4, 0.2, 0.35, 1)
	style_normal.set_corner_radius_all(6)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.85, 0.5, 0.7, 1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 4
	style_hover.border_color = Color(0.45, 0.25, 0.4, 1)
	style_hover.set_corner_radius_all(6)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color.WHITE)

# ============================================
# REWARD CELEBRATION MODAL
# ============================================

func _show_reward_celebration(mission: MissionData) -> void:
	"""Show a juicy celebration modal when claiming a reward."""
	# Remove existing modal if any
	if reward_modal:
		reward_modal.queue_free()

	reward_modal = Control.new()
	reward_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	reward_modal.z_index = 100
	add_child(reward_modal)

	# Play celebration sound and haptic
	if SoundManager:
		SoundManager.play_player_join()
	if HapticManager:
		HapticManager.heavy()

	# Dark overlay with fade in
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	reward_modal.add_child(overlay)

	# Animate overlay fade in
	var overlay_tween = create_tween()
	overlay_tween.tween_property(overlay, "color", Color(0, 0, 0, 0.85), 0.2)

	# Main celebration container
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	reward_modal.add_child(center_container)

	# Panel with glow effect
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 320)
	panel.scale = Vector2(0.5, 0.5)
	panel.pivot_offset = Vector2(190, 160)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	panel_style.border_color = Color(1.0, 0.85, 0.3, 1.0)
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(1.0, 0.8, 0.2, 0.4)
	panel_style.shadow_size = 20
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", panel_style)
	center_container.add_child(panel)

	# Animate panel pop in with bounce
	var panel_tween = create_tween()
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.set_trans(Tween.TRANS_BACK)
	panel_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4)

	# Content VBox
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	# Celebration text with animated entrance
	var congrats = Label.new()
	congrats.text = "REWARD CLAIMED!"
	congrats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		congrats.add_theme_font_override("font", pixel_font)
	congrats.add_theme_font_size_override("font_size", 20)
	congrats.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	congrats.add_theme_color_override("font_shadow_color", Color(0.5, 0.3, 0, 1))
	congrats.add_theme_constant_override("shadow_offset_x", 2)
	congrats.add_theme_constant_override("shadow_offset_y", 2)
	congrats.modulate.a = 0
	vbox.add_child(congrats)

	# Animate congrats text
	var congrats_tween = create_tween()
	congrats_tween.tween_interval(0.2)
	congrats_tween.tween_property(congrats, "modulate:a", 1.0, 0.3)

	# Mission title
	var title = Label.new()
	title.text = mission.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.modulate.a = 0
	vbox.add_child(title)

	var title_tween = create_tween()
	title_tween.tween_interval(0.3)
	title_tween.tween_property(title, "modulate:a", 1.0, 0.2)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Reward display with coin animation
	if mission.reward_coins > 0:
		var coin_container = HBoxContainer.new()
		coin_container.alignment = BoxContainer.ALIGNMENT_CENTER
		coin_container.add_theme_constant_override("separation", 12)
		coin_container.modulate.a = 0
		coin_container.scale = Vector2(0.5, 0.5)
		coin_container.pivot_offset = Vector2(100, 20)
		vbox.add_child(coin_container)

		var coin_icon = Label.new()
		coin_icon.text = "$"
		if pixel_font:
			coin_icon.add_theme_font_override("font", pixel_font)
		coin_icon.add_theme_font_size_override("font_size", 32)
		coin_icon.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		coin_container.add_child(coin_icon)

		var coin_amount = Label.new()
		coin_amount.text = "+%s" % _format_number(mission.reward_coins)
		if pixel_font:
			coin_amount.add_theme_font_override("font", pixel_font)
		coin_amount.add_theme_font_size_override("font_size", 28)
		coin_amount.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
		coin_amount.add_theme_color_override("font_shadow_color", Color(0.4, 0.3, 0, 1))
		coin_amount.add_theme_constant_override("shadow_offset_x", 2)
		coin_amount.add_theme_constant_override("shadow_offset_y", 2)
		coin_container.add_child(coin_amount)

		# Animate coin pop
		var coin_tween = create_tween()
		coin_tween.set_ease(Tween.EASE_OUT)
		coin_tween.set_trans(Tween.TRANS_ELASTIC)
		coin_tween.tween_interval(0.4)
		coin_tween.tween_property(coin_container, "modulate:a", 1.0, 0.1)
		coin_tween.parallel().tween_property(coin_container, "scale", Vector2(1.0, 1.0), 0.5)

		# Pulse the coin amount
		_start_coin_pulse(coin_amount)

	# Unlock reward if any
	if mission.reward_unlock_id != "":
		var unlock_label = Label.new()
		unlock_label.text = "UNLOCKED: %s" % mission.reward_unlock_id.to_upper().replace("_", " ")
		unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if pixel_font:
			unlock_label.add_theme_font_override("font", pixel_font)
		unlock_label.add_theme_font_size_override("font_size", 12)
		unlock_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
		unlock_label.modulate.a = 0
		vbox.add_child(unlock_label)

		var unlock_tween = create_tween()
		unlock_tween.tween_interval(0.6)
		unlock_tween.tween_property(unlock_label, "modulate:a", 1.0, 0.3)

	# Spacer before button
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer2)

	# OK Button
	var ok_button = Button.new()
	ok_button.text = "AWESOME!"
	ok_button.custom_minimum_size = Vector2(180, 55)
	ok_button.modulate.a = 0
	_style_celebration_button(ok_button)
	ok_button.pressed.connect(_close_reward_celebration)
	vbox.add_child(ok_button)

	var btn_tween = create_tween()
	btn_tween.tween_interval(0.6)
	btn_tween.tween_property(ok_button, "modulate:a", 1.0, 0.2)

	# Create sparkle particles around the panel
	_spawn_celebration_particles(reward_modal)

	# Screen shake for extra juice
	if JuiceManager:
		JuiceManager.shake_small()

	# Haptic feedback
	if HapticManager:
		HapticManager.heavy()

func _start_coin_pulse(label: Label) -> void:
	"""Create a pulsing glow effect on the coin amount."""
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(label, "modulate", Color(1.2, 1.1, 0.8, 1.0), 0.5)
	pulse_tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

func _spawn_celebration_particles(parent: Control) -> void:
	"""Spawn sparkle/confetti particles for celebration."""
	var colors = [
		Color(1, 0.85, 0.2),   # Gold
		Color(1, 1, 1),         # White
		Color(0.5, 1, 0.6),     # Green
		Color(0.5, 0.8, 1),     # Blue
		Color(1, 0.5, 0.7),     # Pink
	]

	# Create multiple sparkles
	for i in range(20):
		var sparkle = ColorRect.new()
		sparkle.custom_minimum_size = Vector2(8, 8)
		sparkle.size = Vector2(8, 8)
		sparkle.color = colors[randi() % colors.size()]

		# Random position around center
		var viewport_size = get_viewport().get_visible_rect().size
		var center = viewport_size / 2
		var angle = randf() * TAU
		var distance = randf_range(50, 200)
		sparkle.position = center + Vector2(cos(angle), sin(angle)) * distance

		sparkle.modulate.a = 0
		parent.add_child(sparkle)

		# Animate sparkle
		var delay = randf() * 0.3
		var sparkle_tween = create_tween()
		sparkle_tween.tween_interval(delay)
		sparkle_tween.tween_property(sparkle, "modulate:a", 1.0, 0.1)
		sparkle_tween.parallel().tween_property(sparkle, "scale", Vector2(1.5, 1.5), 0.2)
		sparkle_tween.tween_property(sparkle, "modulate:a", 0.0, 0.4)
		sparkle_tween.parallel().tween_property(sparkle, "position", sparkle.position + Vector2(0, -50), 0.6)
		sparkle_tween.tween_callback(sparkle.queue_free)

func _style_celebration_button(button: Button) -> void:
	"""Style the celebration OK button with extra flair."""
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.75, 0.4, 1)
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 6
	style_normal.border_color = Color(0.1, 0.4, 0.2, 1)
	style_normal.set_corner_radius_all(10)
	style_normal.shadow_color = Color(0.1, 0.5, 0.2, 0.5)
	style_normal.shadow_size = 8

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.85, 0.5, 1)
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 6
	style_hover.border_color = Color(0.15, 0.5, 0.25, 1)
	style_hover.set_corner_radius_all(10)
	style_hover.shadow_color = Color(0.2, 0.6, 0.3, 0.6)
	style_hover.shadow_size = 12

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_shadow_color", Color(0, 0.2, 0, 1))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

func _close_reward_celebration() -> void:
	"""Close the reward celebration modal with animation."""
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	if reward_modal:
		# Animate out
		var tween = create_tween()
		tween.tween_property(reward_modal, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func():
			if reward_modal:
				reward_modal.queue_free()
				reward_modal = null
		)
