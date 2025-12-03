extends CanvasLayer

# Unlocks Screen - Shows player progress and stats

# UI References
var header: PanelContainer
var back_button: Button
var title_label: Label
var scroll_container: ScrollContainer
var content_vbox: VBoxContainer

# Fonts
var pixel_font: Font = null
var pixelify_font: Font = null

func _ready() -> void:
	# Load fonts
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
	if ResourceLoader.exists("res://assets/fonts/Pixelify_Sans/static/PixelifySans-Bold.ttf"):
		pixelify_font = load("res://assets/fonts/Pixelify_Sans/static/PixelifySans-Bold.ttf")

	_build_ui()

	# Keep menu music playing
	if SoundManager:
		SoundManager.play_menu_music()

func _build_ui() -> void:
	# Background - dark gradient
	var background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.05, 0.05, 0.08, 1.0)
	add_child(background)

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
	title_label.text = "UNLOCKS & STATS"
	title_label.set_anchors_preset(Control.PRESET_CENTER)
	title_label.offset_left = -150
	title_label.offset_right = 150
	title_label.offset_top = 5
	title_label.offset_bottom = 35
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title_label)

	# Back button
	back_button = Button.new()
	back_button.text = "< BACK"
	back_button.custom_minimum_size = Vector2(100, 40)
	back_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_button.offset_left = 60
	back_button.offset_top = 50
	back_button.offset_right = 160
	back_button.offset_bottom = 90
	back_button.pressed.connect(_on_back_pressed)
	_style_back_button(back_button)
	header.add_child(back_button)

	# Scrollable content area
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll_container)

	# Content container
	content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 20)
	scroll_container.add_child(content_vbox)

	# Padding at top
	var top_pad = Control.new()
	top_pad.custom_minimum_size = Vector2(0, 20)
	content_vbox.add_child(top_pad)

	# Overall Progress Section
	_add_overall_progress_section()

	# Progress Categories Section
	_add_progress_categories_section()

	# Combat Stats Section
	_add_combat_stats_section()

	# Achievement Stats Section
	_add_achievement_stats_section()

	# Game Mode Stats Section
	_add_game_mode_stats_section()

	# Bottom padding
	var bottom_pad = Control.new()
	bottom_pad.custom_minimum_size = Vector2(0, 40)
	content_vbox.add_child(bottom_pad)

func _add_overall_progress_section() -> void:
	var section = _create_section_panel("OVERALL PROGRESS")

	var progress = UnlocksManager.get_overall_unlock_progress() if UnlocksManager else 0.0
	var progress_bar = _create_progress_bar(progress, Color(0.4, 0.8, 0.4))

	var progress_label = Label.new()
	progress_label.text = "%d%% Complete" % int(progress * 100)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		progress_label.add_theme_font_override("font", pixel_font)
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))

	section.get_child(0).add_child(progress_bar)
	section.get_child(0).add_child(progress_label)
	content_vbox.add_child(section)

func _add_progress_categories_section() -> void:
	var section = _create_section_panel("UNLOCK PROGRESS")
	var vbox = section.get_child(0)

	# Princesses
	var princess_count = PrincessManager.get_unlocked_princess_count() if PrincessManager else 0
	var princess_total = 21
	_add_progress_row(vbox, "Princesses", princess_count, princess_total, Color(0.95, 0.6, 0.8))

	# Difficulties
	var diff_count = DifficultyManager.completed_difficulties.size() if DifficultyManager else 0
	var diff_total = 7
	_add_progress_row(vbox, "Difficulties", diff_count, diff_total, Color(0.8, 0.6, 0.2))

	# Characters
	var char_count = UnlocksManager._count_unlocked_characters() if UnlocksManager else 7
	var char_total = 7
	_add_progress_row(vbox, "Characters", char_count, char_total, Color(0.6, 0.8, 1.0))

	# Passive Abilities
	var passive_count = UnlocksManager.get_unlocked_passive_count() if UnlocksManager else 0
	var passive_total = UnlocksManager.get_total_locked_passives() if UnlocksManager else 24
	_add_progress_row(vbox, "Passive Abilities", passive_count, passive_total, Color(0.6, 1.0, 0.6))

	# Active Abilities
	var active_count = UnlocksManager.get_unlocked_active_count() if UnlocksManager else 0
	var active_total = UnlocksManager.get_total_locked_actives() if UnlocksManager else 12
	_add_progress_row(vbox, "Active Abilities", active_count, active_total, Color(0.8, 0.6, 1.0))

	# Ultimate Abilities
	var ult_count = UnlocksManager.get_unlocked_ultimate_count() if UnlocksManager else 0
	var ult_total = UnlocksManager.get_total_locked_ultimates() if UnlocksManager else 6
	_add_progress_row(vbox, "Ultimate Abilities", ult_count, ult_total, Color(1.0, 0.8, 0.4))

	content_vbox.add_child(section)

func _add_combat_stats_section() -> void:
	var section = _create_section_panel("COMBAT STATS")
	var vbox = section.get_child(0)

	var stats = UnlocksManager.get_stats_dictionary() if UnlocksManager else {}

	_add_stat_row(vbox, "Monsters Killed", _format_number(stats.get("total_monsters_killed", 0)))
	_add_stat_row(vbox, "Elites Killed", _format_number(stats.get("total_elites_killed", 0)))
	_add_stat_row(vbox, "Bosses Killed", _format_number(stats.get("total_bosses_killed", 0)))
	_add_stat_row(vbox, "Games Completed", _format_number(stats.get("games_completed", 0)))

	content_vbox.add_child(section)

func _add_achievement_stats_section() -> void:
	var section = _create_section_panel("ACHIEVEMENTS")
	var vbox = section.get_child(0)

	var stats = UnlocksManager.get_stats_dictionary() if UnlocksManager else {}

	# Hardest difficulty beaten
	var hardest = stats.get("hardest_difficulty_beaten", -1)
	var hardest_name = "None"
	if hardest >= 0 and DifficultyManager:
		hardest_name = DifficultyManager.get_difficulty_name(hardest)
	_add_stat_row(vbox, "Hardest Difficulty", hardest_name)

	# Highest curses used
	var curses_dict = stats.get("hardest_with_curses", {})
	var max_curses = 0
	for diff in curses_dict:
		if curses_dict[diff] > max_curses:
			max_curses = curses_dict[diff]
	_add_stat_row(vbox, "Most Curses Active", str(max_curses))

	content_vbox.add_child(section)

func _add_game_mode_stats_section() -> void:
	var section = _create_section_panel("GAME MODE RECORDS")
	var vbox = section.get_child(0)

	var stats = UnlocksManager.get_stats_dictionary() if UnlocksManager else {}

	# Endless mode stats
	var endless_header = Label.new()
	endless_header.text = "ENDLESS MODE"
	endless_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		endless_header.add_theme_font_override("font", pixel_font)
	endless_header.add_theme_font_size_override("font_size", 12)
	endless_header.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(endless_header)

	_add_stat_row(vbox, "Longest Survival", _format_time(stats.get("longest_endless_time", 0.0)))
	_add_stat_row(vbox, "Highest Wave", str(stats.get("highest_endless_wave", 0)))
	_add_stat_row(vbox, "Best Points", _format_number(stats.get("highest_endless_points", 0)))

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Challenge mode stats
	var challenge_header = Label.new()
	challenge_header.text = "CHALLENGE MODE"
	challenge_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		challenge_header.add_theme_font_override("font", pixel_font)
	challenge_header.add_theme_font_size_override("font_size", 12)
	challenge_header.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
	vbox.add_child(challenge_header)

	var fastest = stats.get("fastest_challenge_time", 999999.0)
	var fastest_str = _format_time(fastest) if fastest < 999999.0 else "--:--"
	_add_stat_row(vbox, "Fastest Clear", fastest_str)
	_add_stat_row(vbox, "Best Points", _format_number(stats.get("highest_challenge_points", 0)))

	# General stats from StatsManager
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)

	var general_header = Label.new()
	general_header.text = "LIFETIME"
	general_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		general_header.add_theme_font_override("font", pixel_font)
	general_header.add_theme_font_size_override("font_size", 12)
	general_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(general_header)

	if StatsManager:
		var lifetime = StatsManager.get_lifetime_stats()
		_add_stat_row(vbox, "Total Runs", _format_number(lifetime.get("total_runs", 0)))
		_add_stat_row(vbox, "Total Time Played", _format_time(lifetime.get("total_time_played", 0.0)))
		_add_stat_row(vbox, "Total Kills", _format_number(lifetime.get("total_kills", 0)))
		_add_stat_row(vbox, "Highest Level", str(lifetime.get("best_level", 0)))

	content_vbox.add_child(section)

func _create_section_panel(title: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = Color(0.2, 0.2, 0.3, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(350, 0)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Section title
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title_label)

	# Separator
	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxLine.new())
	vbox.add_child(sep)

	return panel

func _add_progress_row(container: VBoxContainer, label_text: String, current: int, total: int, color: Color) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hbox.add_child(label)

	var progress = float(current) / float(total) if total > 0 else 0.0
	var bar = _create_progress_bar(progress, color)
	bar.custom_minimum_size = Vector2(100, 16)
	hbox.add_child(bar)

	var count_label = Label.new()
	count_label.text = "%d/%d" % [current, total]
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", color)
	hbox.add_child(count_label)

	container.add_child(hbox)

func _add_stat_row(container: VBoxContainer, label_text: String, value_text: String) -> void:
	var hbox = HBoxContainer.new()

	var label = Label.new()
	label.text = label_text + ":"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hbox.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 12)
	value.add_theme_color_override("font_color", Color(1, 1, 1))
	hbox.add_child(value)

	container.add_child(hbox)

func _create_progress_bar(progress: float, color: Color) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(200, 20)

	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.15, 0.15, 0.2, 1)
	container.add_child(bg)

	# Fill
	var fill = ColorRect.new()
	fill.anchor_left = 0
	fill.anchor_top = 0
	fill.anchor_right = progress
	fill.anchor_bottom = 1
	fill.offset_left = 2
	fill.offset_top = 2
	fill.offset_right = -2
	fill.offset_bottom = -2
	fill.color = color
	container.add_child(fill)

	# Border
	var border = ReferenceRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.border_color = color.darkened(0.3)
	border.border_width = 2
	border.editor_only = false
	container.add_child(border)

	return container

func _style_header() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 0.95)
	style.border_width_bottom = 2
	style.border_color = Color(0.15, 0.14, 0.2, 1)
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

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.35, 0.35, 0.4, 1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 4
	style_hover.border_color = Color(0.2, 0.2, 0.25, 1)
	style_hover.set_corner_radius_all(6)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

func _on_back_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

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

func _format_time(seconds: float) -> String:
	var total_secs = int(seconds)
	var hours = total_secs / 3600
	var mins = (total_secs % 3600) / 60
	var secs = total_secs % 60

	if hours > 0:
		return "%dh %02dm" % [hours, mins]
	else:
		return "%02d:%02d" % [mins, secs]
