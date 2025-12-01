extends Node

# Challenge Mode Controller
# Manages the 10-minute challenge mode with milestone spawns and victory conditions

# Milestone times in seconds
const MILESTONE_TIMES: Array[float] = [150.0, 300.0, 450.0]  # 2.5m, 5m, 7.5m
const FINAL_BOSS_TIME: float = 600.0  # 10 minutes
const WARNING_ADVANCE: float = 3.0  # Show warning 3 seconds before milestone

# State tracking
var game_time: float = 0.0
var milestones_triggered: Array[bool] = [false, false, false]
var final_boss_triggered: bool = false
var final_boss_killed: bool = false
var challenge_complete: bool = false
var spawning_stopped: bool = false

# References
var enemy_spawner: Node2D = null
var elite_spawner: Node2D = null
var player: Node2D = null

# Pixel font for UI
var pixel_font: Font = null

# Timer display UI
var timer_display: CanvasLayer = null
var timer_label: Label = null

# Victory screen
var victory_ui: CanvasLayer = null

# Signals
signal milestone_reached(milestone_index: int)
signal final_boss_spawned()
signal challenge_completed()
signal spawning_halted()

func _ready() -> void:
	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	_setup_timer_display()

func setup(p_enemy_spawner: Node2D, p_elite_spawner: Node2D, p_player: Node2D) -> void:
	"""Initialize the controller with required references."""
	enemy_spawner = p_enemy_spawner
	elite_spawner = p_elite_spawner
	player = p_player

	# Set elite spawner to challenge mode
	if elite_spawner and elite_spawner.has_method("set_challenge_mode"):
		elite_spawner.set_challenge_mode(true)
		elite_spawner.boss_killed_challenge.connect(_on_boss_killed)

func _process(delta: float) -> void:
	if challenge_complete:
		return

	game_time += delta
	_update_timer_display()

	# Check milestones (elite spawns at 2.5m, 5m, 7.5m)
	for i in range(MILESTONE_TIMES.size()):
		if not milestones_triggered[i] and game_time >= MILESTONE_TIMES[i]:
			milestones_triggered[i] = true
			_trigger_milestone(i)

	# Check final boss (10 minutes)
	if not final_boss_triggered and game_time >= FINAL_BOSS_TIME:
		final_boss_triggered = true
		_trigger_final_boss()

	# Check victory condition after boss killed
	if final_boss_killed and not challenge_complete and not spawning_stopped:
		_stop_spawning()

	# Check if all enemies are cleared after boss is dead
	if spawning_stopped and not challenge_complete:
		_check_victory_condition()

func _setup_timer_display() -> void:
	"""Create the challenge timer display at top of screen."""
	timer_display = CanvasLayer.new()
	timer_display.layer = 50
	add_child(timer_display)

	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_display.add_child(container)

	# Timer label
	timer_label = Label.new()
	timer_label.text = "10:00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.anchor_top = 0.02
	timer_label.anchor_bottom = 0.02
	timer_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if pixel_font:
		timer_label.add_theme_font_override("font", pixel_font)
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	timer_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	timer_label.add_theme_constant_override("shadow_offset_x", 2)
	timer_label.add_theme_constant_override("shadow_offset_y", 2)

	container.add_child(timer_label)

func _update_timer_display() -> void:
	"""Update the countdown timer display."""
	if not timer_label:
		return

	var remaining = max(0, FINAL_BOSS_TIME - game_time)
	var mins = int(remaining) / 60
	var secs = int(remaining) % 60
	timer_label.text = "%d:%02d" % [mins, secs]

	# Change color based on time remaining
	if remaining <= 60:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Red
	elif remaining <= 150:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))  # Orange
	else:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))  # Yellow

	# After boss spawned, show "CLEAR ALL ENEMIES"
	if final_boss_triggered and not final_boss_killed:
		timer_label.text = "DEFEAT THE BOSS"
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	elif spawning_stopped and not challenge_complete:
		timer_label.text = "CLEAR REMAINING"
		timer_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))

func _trigger_milestone(index: int) -> void:
	"""Trigger an elite spawn at a milestone."""
	if elite_spawner and elite_spawner.has_method("force_spawn_elite"):
		elite_spawner.force_spawn_elite()
	milestone_reached.emit(index)

func _trigger_final_boss() -> void:
	"""Trigger the final boss spawn."""
	if elite_spawner and elite_spawner.has_method("force_spawn_boss"):
		elite_spawner.force_spawn_boss()
	final_boss_spawned.emit()

	# Show dramatic notification
	_show_boss_notification()

func _on_boss_killed() -> void:
	"""Called when the challenge mode boss is killed."""
	final_boss_killed = true

func _stop_spawning() -> void:
	"""Stop all enemy spawning after boss is killed."""
	spawning_stopped = true

	if enemy_spawner and enemy_spawner.has_method("stop_spawning"):
		enemy_spawner.stop_spawning()

	spawning_halted.emit()

	# Show notification
	_show_clear_notification()

func _check_victory_condition() -> void:
	"""Check if all enemies have been cleared for victory."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var active_enemies = enemies.filter(func(e): return is_instance_valid(e))

	if active_enemies.size() == 0:
		_trigger_victory()

func _trigger_victory() -> void:
	"""Handle challenge completion."""
	challenge_complete = true

	# Unlock next difficulty
	if DifficultyManager:
		var unlocked = DifficultyManager.unlock_next_difficulty()
		if unlocked:
			var next = DifficultyManager.get_next_difficulty(DifficultyManager.current_difficulty)
			_show_unlock_notification(DifficultyManager.get_difficulty_name(next))

	challenge_completed.emit()

	# Show victory screen after a short delay
	await get_tree().create_timer(1.0).timeout
	_show_victory_screen()

func _show_boss_notification() -> void:
	"""Show dramatic boss spawn notification."""
	var notification = _create_notification("FINAL BOSS", Color(1.0, 0.15, 0.15), 56)

	# Extra dramatic effects
	if JuiceManager:
		JuiceManager.shake_large()
		JuiceManager.chromatic_pulse(1.0)

	if HapticManager:
		HapticManager.heavy()

func _show_clear_notification() -> void:
	"""Show notification to clear remaining enemies."""
	_create_notification("CLEAR ALL ENEMIES", Color(0.3, 1.0, 0.5), 36)

func _show_unlock_notification(difficulty_name: String) -> void:
	"""Show notification that a new difficulty was unlocked."""
	_create_notification("%s UNLOCKED!" % difficulty_name.to_upper(), Color(1.0, 0.85, 0.2), 32)

func _create_notification(text: String, color: Color, font_size: int) -> CanvasLayer:
	"""Create a centered notification that fades out."""
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 4)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	label.add_theme_constant_override("outline_size", 5)

	# Start animation
	label.modulate.a = 0.0
	label.scale = Vector2(2.0, 2.0)
	label.pivot_offset = label.size / 2

	canvas.add_child(label)

	# Animate slam-in and fade-out
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(label, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): canvas.queue_free())

	return canvas

func _show_victory_screen() -> void:
	"""Show the victory screen."""
	# Pause the game
	get_tree().paused = true

	victory_ui = CanvasLayer.new()
	victory_ui.layer = 110
	victory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(victory_ui)

	# Background overlay
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	victory_ui.add_child(bg)

	# Main container
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical = Control.GROW_DIRECTION_BOTH
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 30)
	victory_ui.add_child(container)

	# Victory title
	var title = Label.new()
	title.text = "VICTORY!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.add_theme_color_override("font_shadow_color", Color(0.4, 0.3, 0.0, 1.0))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	container.add_child(title)

	# Difficulty completed
	var difficulty_label = Label.new()
	var diff_name = DifficultyManager.get_difficulty_name() if DifficultyManager else "Unknown"
	difficulty_label.text = "%s Completed!" % diff_name
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		difficulty_label.add_theme_font_override("font", pixel_font)
	difficulty_label.add_theme_font_size_override("font_size", 24)
	var diff_color = DifficultyManager.get_difficulty_color() if DifficultyManager else Color.WHITE
	difficulty_label.add_theme_color_override("font_color", diff_color)
	container.add_child(difficulty_label)

	# Time display
	var time_label = Label.new()
	var mins = int(game_time) / 60
	var secs = int(game_time) % 60
	time_label.text = "Time: %d:%02d" % [mins, secs]
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		time_label.add_theme_font_override("font", pixel_font)
	time_label.add_theme_font_size_override("font_size", 18)
	time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	container.add_child(time_label)

	# Buttons
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 20)
	container.add_child(button_container)

	# Continue button (play again at same difficulty)
	var continue_btn = Button.new()
	continue_btn.text = "Play Again"
	continue_btn.custom_minimum_size = Vector2(150, 50)
	continue_btn.pressed.connect(_on_play_again)
	_style_button(continue_btn, Color(0.2, 0.75, 0.3))
	button_container.add_child(continue_btn)

	# Menu button
	var menu_btn = Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.custom_minimum_size = Vector2(150, 50)
	menu_btn.pressed.connect(_on_main_menu)
	_style_button(menu_btn, Color(0.4, 0.4, 0.5))
	button_container.add_child(menu_btn)

	# Animate entry
	container.modulate.a = 0.0
	container.scale = Vector2(0.8, 0.8)
	container.pivot_offset = container.size / 2

	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(container, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Celebration effects
	if JuiceManager:
		JuiceManager.shake_medium()
	if HapticManager:
		HapticManager.heavy()

func _style_button(button: Button, color: Color) -> void:
	"""Apply consistent styling to buttons."""
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 6
	style.border_color = color.darkened(0.4)
	style.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.15)
	pressed.border_width_top = 5
	pressed.border_width_bottom = 4
	button.add_theme_stylebox_override("pressed", pressed)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 14)

func _on_play_again() -> void:
	"""Restart the game at the same difficulty."""
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	# Reset run stats
	if StatsManager:
		StatsManager.reset_run()
	if AbilityManager:
		AbilityManager.reset()

	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_main_menu() -> void:
	"""Return to main menu."""
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func get_completion_time() -> float:
	"""Get the time it took to complete the challenge."""
	return game_time
