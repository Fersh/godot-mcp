extends Node

# Game Settings Manager - handles audio, haptics, and visual settings
# Add to autoload as "GameSettings"

const SETTINGS_PATH := "user://game_settings.cfg"

# Settings
var music_enabled: bool = true
var sfx_enabled: bool = true
var screen_shake_enabled: bool = true
var haptics_enabled: bool = true
var master_volume: float = 1.0  # 0.0 to 1.0
var music_volume: float = 1.0  # 0.0 to 1.0 - separate music volume
var sfx_volume: float = 1.0  # 0.0 to 1.0 - separate sfx volume
var track_missions_enabled: bool = true  # Show mission tracker in game HUD

# Visual effect toggles
var damage_numbers_enabled: bool = true  # Show damage numbers on hit
var status_text_enabled: bool = true  # Show status text over enemies (BURN, POISON, etc.)
var freeze_frames_enabled: bool = true  # Hitstop/freeze frame effects on hits/kills
var visual_effects_enabled: bool = true  # Status tinting, chromatic aberration, zoom punch, etc.

# Generic settings storage for misc values
var misc_settings: Dictionary = {}

signal settings_changed

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	if err == OK:
		music_enabled = config.get_value("audio", "music_enabled", true)
		sfx_enabled = config.get_value("audio", "sfx_enabled", true)
		screen_shake_enabled = config.get_value("visual", "screen_shake_enabled", true)
		haptics_enabled = config.get_value("haptics", "haptics_enabled", true)
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		track_missions_enabled = config.get_value("gameplay", "track_missions_enabled", true)
		# Visual effect toggles
		damage_numbers_enabled = config.get_value("visual", "damage_numbers_enabled", true)
		status_text_enabled = config.get_value("visual", "status_text_enabled", true)
		freeze_frames_enabled = config.get_value("visual", "freeze_frames_enabled", true)
		visual_effects_enabled = config.get_value("visual", "visual_effects_enabled", true)
		# Load misc settings
		if config.has_section("misc"):
			for key in config.get_section_keys("misc"):
				misc_settings[key] = config.get_value("misc", key)
	_apply_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.set_value("visual", "screen_shake_enabled", screen_shake_enabled)
	config.set_value("haptics", "haptics_enabled", haptics_enabled)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("gameplay", "track_missions_enabled", track_missions_enabled)
	# Visual effect toggles
	config.set_value("visual", "damage_numbers_enabled", damage_numbers_enabled)
	config.set_value("visual", "status_text_enabled", status_text_enabled)
	config.set_value("visual", "freeze_frames_enabled", freeze_frames_enabled)
	config.set_value("visual", "visual_effects_enabled", visual_effects_enabled)
	# Save misc settings
	for key in misc_settings:
		config.set_value("misc", key, misc_settings[key])
	config.save(SETTINGS_PATH)

func _apply_settings() -> void:
	# Apply volume to master bus
	var volume_db = linear_to_db(master_volume)
	AudioServer.set_bus_volume_db(0, volume_db)

	# Update music based on setting
	if SoundManager:
		if music_enabled:
			SoundManager.set_music_volume(-10.0 + linear_to_db(master_volume))
		else:
			SoundManager.stop_music()

	emit_signal("settings_changed")

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if SoundManager:
		if enabled:
			SoundManager.play_music()
		else:
			SoundManager.stop_music()
	save_settings()
	emit_signal("settings_changed")

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	save_settings()
	emit_signal("settings_changed")

func set_screen_shake_enabled(enabled: bool) -> void:
	screen_shake_enabled = enabled
	save_settings()
	emit_signal("settings_changed")

func set_haptics_enabled(enabled: bool) -> void:
	haptics_enabled = enabled
	save_settings()
	emit_signal("settings_changed")

func set_track_missions_enabled(enabled: bool) -> void:
	track_missions_enabled = enabled
	save_settings()
	emit_signal("settings_changed")

func set_damage_numbers_enabled(enabled: bool) -> void:
	damage_numbers_enabled = enabled
	save_settings()
	emit_signal("settings_changed")

func set_status_text_enabled(enabled: bool) -> void:
	status_text_enabled = enabled
	save_settings()
	emit_signal("settings_changed")

func set_freeze_frames_enabled(enabled: bool) -> void:
	freeze_frames_enabled = enabled
	save_settings()
	emit_signal("settings_changed")

func set_visual_effects_enabled(enabled: bool) -> void:
	visual_effects_enabled = enabled
	save_settings()
	emit_signal("settings_changed")

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	var volume_db = linear_to_db(master_volume)
	AudioServer.set_bus_volume_db(0, volume_db)
	save_settings()
	emit_signal("settings_changed")

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	if SoundManager:
		SoundManager.apply_music_volume()
	save_settings()
	emit_signal("settings_changed")

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	save_settings()
	emit_signal("settings_changed")

func increase_volume() -> void:
	set_master_volume(master_volume + 0.1)

func decrease_volume() -> void:
	set_master_volume(master_volume - 0.1)

# Generic setting getter/setter for misc values
func get_setting(key: String, default_value = null):
	return misc_settings.get(key, default_value)

func set_setting(key: String, value) -> void:
	misc_settings[key] = value
	save_settings()
