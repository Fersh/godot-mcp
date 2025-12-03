extends CanvasLayer

# Daily Login Popup - Shows when app opens with an unclaimed reward

signal closed()

var pixel_font: Font = null
var panel: Control = null
var is_visible: bool = false

func _ready() -> void:
	# Load fonts
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

func show_popup() -> void:
	"""Show the daily login popup."""
	if is_visible:
		return

	is_visible = true
	_build_ui()

func _build_ui() -> void:
	# Main container
	panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	# Dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.85)
	panel.add_child(overlay)

	# Dialog container
	var dialog = PanelContainer.new()
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.custom_minimum_size = Vector2(380, 450)
	dialog.offset_left = -190
	dialog.offset_right = 190
	dialog.offset_top = -225
	dialog.offset_bottom = 225

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.18, 0.98)
	style.border_color = Color(0.3, 0.5, 0.8, 1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	dialog.add_theme_stylebox_override("panel", style)
	panel.add_child(dialog)

	# Content VBox
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	dialog.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "DAILY BONUS!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.add_theme_color_override("font_shadow_color", Color(0.4, 0.3, 0, 1))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title)

	if DailyLoginManager:
		var reward = DailyLoginManager.get_today_reward()
		var streak = DailyLoginManager.get_streak()

		# Streak display
		var streak_label = Label.new()
		streak_label.text = "Day %d Streak!" % streak
		streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if pixel_font:
			streak_label.add_theme_font_override("font", pixel_font)
		streak_label.add_theme_font_size_override("font_size", 14)
		streak_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		vbox.add_child(streak_label)

		# Day in cycle
		var day_label = Label.new()
		day_label.text = "Day %d of 7" % reward["day_in_cycle"]
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if pixel_font:
			day_label.add_theme_font_override("font", pixel_font)
		day_label.add_theme_font_size_override("font_size", 11)
		day_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(day_label)

		# 7-day progress dots
		var dots_container = HBoxContainer.new()
		dots_container.alignment = BoxContainer.ALIGNMENT_CENTER
		dots_container.add_theme_constant_override("separation", 10)
		vbox.add_child(dots_container)

		var preview = DailyLoginManager.get_week_preview()
		for i in range(7):
			var day_data = preview[i]
			var dot_container = VBoxContainer.new()
			dot_container.alignment = BoxContainer.ALIGNMENT_CENTER
			dot_container.add_theme_constant_override("separation", 3)
			dots_container.add_child(dot_container)

			var dot = ColorRect.new()
			dot.custom_minimum_size = Vector2(32, 32)

			if day_data["is_claimed"]:
				dot.color = Color(0.3, 0.8, 0.4)  # Green
			elif day_data["is_today"]:
				dot.color = Color(1.0, 0.85, 0.2)  # Gold - pulsing would be nice
			else:
				dot.color = Color(0.25, 0.25, 0.3)  # Gray
			dot_container.add_child(dot)

			var day_num = Label.new()
			day_num.text = str(i + 1)
			day_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if pixel_font:
				day_num.add_theme_font_override("font", pixel_font)
			day_num.add_theme_font_size_override("font_size", 9)
			day_num.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			dot_container.add_child(day_num)

		# Spacer
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		vbox.add_child(spacer)

		# Today's reward box
		var reward_panel = PanelContainer.new()
		reward_panel.custom_minimum_size = Vector2(280, 80)

		var reward_style = StyleBoxFlat.new()
		reward_style.bg_color = Color(0.15, 0.2, 0.3, 1)
		reward_style.border_color = Color(1, 0.85, 0.2)
		reward_style.set_border_width_all(2)
		reward_style.set_corner_radius_all(8)
		reward_style.content_margin_left = 15
		reward_style.content_margin_right = 15
		reward_style.content_margin_top = 10
		reward_style.content_margin_bottom = 10
		reward_panel.add_theme_stylebox_override("panel", reward_style)
		vbox.add_child(reward_panel)

		var reward_vbox = VBoxContainer.new()
		reward_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		reward_vbox.add_theme_constant_override("separation", 8)
		reward_panel.add_child(reward_vbox)

		var reward_title = Label.new()
		reward_title.text = "TODAY'S REWARD"
		reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if pixel_font:
			reward_title.add_theme_font_override("font", pixel_font)
		reward_title.add_theme_font_size_override("font_size", 11)
		reward_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		reward_vbox.add_child(reward_title)

		# Build reward text
		var reward_text = ""
		if reward["total_coins"] > 0:
			reward_text = "%d COINS" % reward["total_coins"]
		if reward["special"] == "random_passive":
			if reward_text != "":
				reward_text += " + "
			reward_text += "RANDOM ABILITY"
		elif reward["special"] == "jackpot":
			reward_text += " JACKPOT!"

		var reward_amount = Label.new()
		reward_amount.text = reward_text
		reward_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if pixel_font:
			reward_amount.add_theme_font_override("font", pixel_font)
		reward_amount.add_theme_font_size_override("font_size", 16)
		reward_amount.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		reward_vbox.add_child(reward_amount)

		# Streak bonus info
		if reward.has("bonus_multiplier") and reward["bonus_multiplier"] > 0:
			var bonus_label = Label.new()
			bonus_label.text = "(+%d%% streak bonus!)" % int(reward["bonus_multiplier"] * 100)
			bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if pixel_font:
				bonus_label.add_theme_font_override("font", pixel_font)
			bonus_label.add_theme_font_size_override("font_size", 10)
			bonus_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
			reward_vbox.add_child(bonus_label)

		# Spacer
		var spacer2 = Control.new()
		spacer2.custom_minimum_size = Vector2(0, 10)
		vbox.add_child(spacer2)

		# Claim button
		var claim_btn = Button.new()
		claim_btn.text = "CLAIM!"
		claim_btn.custom_minimum_size = Vector2(200, 55)
		_style_golden_button(claim_btn)
		claim_btn.pressed.connect(_on_claim_pressed)
		vbox.add_child(claim_btn)

		# Next bonus info
		var next_bonus = DailyLoginManager.get_next_streak_bonus()
		if next_bonus["threshold"] > 0:
			var next_label = Label.new()
			next_label.text = "%d days until +%d%% bonus!" % [next_bonus["days_remaining"], int(next_bonus["bonus"] * 100)]
			next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if pixel_font:
				next_label.add_theme_font_override("font", pixel_font)
			next_label.add_theme_font_size_override("font_size", 9)
			next_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
			vbox.add_child(next_label)
	else:
		var error_label = Label.new()
		error_label.text = "Login system not available"
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if pixel_font:
			error_label.add_theme_font_override("font", pixel_font)
		error_label.add_theme_font_size_override("font_size", 12)
		error_label.add_theme_color_override("font_color", Color(0.7, 0.3, 0.3))
		vbox.add_child(error_label)

		var close_btn = Button.new()
		close_btn.text = "CLOSE"
		close_btn.custom_minimum_size = Vector2(150, 45)
		_style_gray_button(close_btn)
		close_btn.pressed.connect(_close)
		vbox.add_child(close_btn)

func _on_claim_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.heavy()

	if DailyLoginManager:
		var reward = DailyLoginManager.claim_daily_reward()
		# Could show claimed animation here

	_close()

func _close() -> void:
	is_visible = false
	if panel:
		panel.queue_free()
		panel = null
	closed.emit()

func _style_golden_button(button: Button) -> void:
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

func _style_gray_button(button: Button) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.35, 0.35, 0.4, 1)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 4
	style_normal.border_color = Color(0.2, 0.2, 0.25, 1)
	style_normal.set_corner_radius_all(6)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_normal)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color.WHITE)
