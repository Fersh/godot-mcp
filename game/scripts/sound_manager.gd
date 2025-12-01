extends Node

# Sound Manager - handles all game sound effects with pooling and random variations
# Also manages dynamic music system with boss/elite/menu music transitions

# Sound pools for randomization
var swing_sounds: Array[AudioStream] = []
var hit_sounds: Array[AudioStream] = []
var grunt_sounds: Array[AudioStream] = []
var blood_sounds: Array[AudioStream] = []

# Single sounds
var heal_sound: AudioStream
var levelup_sound: AudioStream
var levelup_fanfare: AudioStream
var xp_sound: AudioStream
var swoosh_sound: AudioStream
var damage_sound: AudioStream
var buff_sound: AudioStream
var ding_sound: AudioStream
var block_sound: AudioStream
var click_sound: AudioStream

# Audio players pool for concurrent sounds
var audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 16

# ============================================
# MUSIC SYSTEM
# ============================================

# Music players - main for background, overlay for boss/elite
var music_player: AudioStreamPlayer
var overlay_music_player: AudioStreamPlayer

# Music tracks
var music1: AudioStream  # In-game track 1
var music2: AudioStream  # In-game track 2
var menu_music: AudioStream  # Main menu music (1. Stolen Future)
var boss_music: AudioStream  # Boss music (3. Lost)
var elite_music: AudioStream  # Elite music (4. Awakened)
var game_over_music: AudioStream  # Game over music (5. Aurora)

# Music state
enum MusicState { NONE, MENU, GAME, BOSS, ELITE, GAME_OVER }
var current_music_state: MusicState = MusicState.NONE
var previous_music_state: MusicState = MusicState.NONE

# Background music state for resuming after boss/elite
var background_music_position: float = 0.0
var background_music_stream: AudioStream = null
var in_game_music_loop: bool = false
var play_music2_on_finish: bool = false

# Fade settings
const FADE_DURATION: float = 5.0  # Fade out duration for boss music
const FADE_IN_DURATION: float = 2.0  # Fade in duration
const MUSIC_VOLUME_DB: float = -10.0  # Normal music volume
const OVERLAY_VOLUME_DB: float = -6.0  # Boss/elite music slightly louder

# Elite music timer
var elite_music_timer: float = 0.0
const ELITE_MUSIC_MAX_DURATION: float = 30.0  # Max 30 seconds for elite music

# Active boss/elite tracking
var active_boss: Node = null
var active_elite: Node = null

# Tweens for fading
var fade_tween: Tween = null
var overlay_fade_tween: Tween = null

func _ready() -> void:
	_load_sounds()
	_create_audio_pool()
	_setup_music_players()
	_load_music_tracks()

func _process(delta: float) -> void:
	# Handle elite music timeout
	if current_music_state == MusicState.ELITE and elite_music_timer > 0:
		elite_music_timer -= delta
		if elite_music_timer <= 0:
			_end_overlay_music()

func _load_sounds() -> void:
	# Load swing sounds (swing, swing2-5)
	swing_sounds.append(load("res://assets/sounds/swing.mp3"))
	swing_sounds.append(load("res://assets/sounds/swing2.mp3"))
	swing_sounds.append(load("res://assets/sounds/swing3.mp3"))
	swing_sounds.append(load("res://assets/sounds/swing4.mp3"))
	swing_sounds.append(load("res://assets/sounds/swing5.mp3"))

	# Load hit sounds
	hit_sounds.append(load("res://assets/sounds/hit.mp3"))
	hit_sounds.append(load("res://assets/sounds/hit2.mp3"))

	# Load grunt sounds (player hurt)
	grunt_sounds.append(load("res://assets/sounds/grunt.mp3"))
	grunt_sounds.append(load("res://assets/sounds/grunt2.mp3"))

	# Load blood sounds (enemy death)
	blood_sounds.append(load("res://assets/sounds/blood.mp3"))
	blood_sounds.append(load("res://assets/sounds/blood2.mp3"))

	# Load single sounds
	heal_sound = load("res://assets/sounds/heal.mp3")
	levelup_sound = load("res://assets/sounds/levelup 2.mp3")
	levelup_fanfare = load("res://assets/sounds/medieval_rpg_game_qu_#1-1763518583917.mp3")
	xp_sound = load("res://assets/sounds/xp.mp3")
	swoosh_sound = load("res://assets/sounds/swoosh.mp3")
	damage_sound = load("res://assets/sounds/damage.mp3")
	buff_sound = load("res://assets/sounds/buff.mp3")
	ding_sound = load("res://assets/sounds/ding.mp3")
	block_sound = load("res://assets/sounds/block.mp3")
	click_sound = load("res://assets/sounds/click.mp3")

func _create_audio_pool() -> void:
	for i in POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		audio_players.append(player)

func _setup_music_players() -> void:
	# Main music player for background/menu/game over
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = MUSIC_VOLUME_DB
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)

	# Overlay music player for boss/elite (plays on top, background fades)
	overlay_music_player = AudioStreamPlayer.new()
	overlay_music_player.bus = "Master"
	overlay_music_player.volume_db = OVERLAY_VOLUME_DB
	add_child(overlay_music_player)
	overlay_music_player.finished.connect(_on_overlay_music_finished)

func _load_music_tracks() -> void:
	# In-game music (existing)
	music1 = load("res://assets/sounds/music1.mp3")
	music2 = load("res://assets/sounds/music2.mp3")

	# New contextual music tracks
	if ResourceLoader.exists("res://assets/sounds/1. Stolen Future.mp3"):
		menu_music = load("res://assets/sounds/1. Stolen Future.mp3")
	if ResourceLoader.exists("res://assets/sounds/3. Lost.mp3"):
		boss_music = load("res://assets/sounds/3. Lost.mp3")
	if ResourceLoader.exists("res://assets/sounds/4. Awakened.mp3"):
		elite_music = load("res://assets/sounds/4. Awakened.mp3")
	if ResourceLoader.exists("res://assets/sounds/5. Aurora.mp3"):
		game_over_music = load("res://assets/sounds/5. Aurora.mp3")

func _on_music_finished() -> void:
	if GameSettings and not GameSettings.music_enabled:
		return

	match current_music_state:
		MusicState.GAME:
			# In-game music loop: cycle music1 -> music2 -> music1...
			if in_game_music_loop:
				if music_player.stream == music1 and music2:
					music_player.stream = music2
					music_player.play()
				elif music_player.stream == music2 and music1:
					music_player.stream = music1
					music_player.play()

		MusicState.MENU:
			# Loop menu music
			if menu_music:
				music_player.play()

		MusicState.GAME_OVER:
			# Game over music doesn't loop - just ends
			pass

func _on_overlay_music_finished() -> void:
	# Boss/elite music finished naturally - return to background music
	_end_overlay_music()

func _get_available_player() -> AudioStreamPlayer:
	for player in audio_players:
		if not player.playing:
			return player
	# All players busy, return first one (will cut off oldest sound)
	return audio_players[0]

func _play_sound(stream: AudioStream, volume_db: float = 0.0, pitch_variance: float = 0.0) -> void:
	if stream == null:
		return
	# Check if SFX is enabled
	if GameSettings and not GameSettings.sfx_enabled:
		return
	var player = _get_available_player()
	player.stream = stream
	player.volume_db = volume_db
	if pitch_variance > 0:
		player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	else:
		player.pitch_scale = 1.0
	player.play()

func _play_random_from_pool(pool: Array[AudioStream], volume_db: float = 0.0, pitch_variance: float = 0.1) -> void:
	if pool.is_empty():
		return
	var sound = pool[randi() % pool.size()]
	_play_sound(sound, volume_db, pitch_variance)

# Public API - call these from game code

func play_swing() -> void:
	# Melee attack swing sound
	_play_random_from_pool(swing_sounds, -5.0, 0.15)

func play_hit() -> void:
	# Enemy taking damage
	_play_random_from_pool(hit_sounds, -3.0, 0.1)

func play_player_hurt() -> void:
	# Player taking damage - play both damage sound and grunt
	_play_sound(damage_sound, -2.0, 0.1)
	_play_random_from_pool(grunt_sounds, -5.0, 0.15)

func play_enemy_death() -> void:
	# Enemy dying - blood splatter sound
	_play_random_from_pool(blood_sounds, -5.0, 0.1)

func play_heal() -> void:
	_play_sound(heal_sound, -3.0)

func play_levelup() -> void:
	_play_sound(levelup_sound, 0.0)
	# Play fanfare slightly after for layered effect
	_play_sound(levelup_fanfare, -5.0)

func play_xp() -> void:
	# Quieter and with pitch variance for frequent XP pickups
	_play_sound(xp_sound, -10.0, 0.2)

func play_arrow() -> void:
	# Arrow/projectile shot
	_play_sound(swoosh_sound, -5.0, 0.15)

func play_buff() -> void:
	# Ability/buff acquired
	_play_sound(buff_sound, -3.0)

func play_ding() -> void:
	# Generic notification/pickup
	_play_sound(ding_sound, -5.0)

func play_block() -> void:
	# Attack blocked
	_play_sound(block_sound, -3.0, 0.1)

func play_click() -> void:
	# UI button click sound
	_play_sound(click_sound, -5.0, 0.05)

# ============================================
# MUSIC CONTROL API
# ============================================

func play_menu_music() -> void:
	"""Play main menu music (1. Stolen Future) - loops until game starts.
	If menu music is already playing, this does nothing (prevents restart on scene change)."""
	if GameSettings and not GameSettings.music_enabled:
		return

	# Don't restart if menu music is already playing
	if current_music_state == MusicState.MENU and music_player.playing:
		return

	_stop_all_music()
	current_music_state = MusicState.MENU

	if menu_music:
		music_player.stream = menu_music
		music_player.volume_db = MUSIC_VOLUME_DB
		music_player.play()

func play_music() -> void:
	"""Start in-game background music (cycles music1 <-> music2)."""
	if GameSettings and not GameSettings.music_enabled:
		return

	_stop_all_music()
	current_music_state = MusicState.GAME
	in_game_music_loop = true

	if music1:
		music_player.stream = music1
		music_player.volume_db = MUSIC_VOLUME_DB
		music_player.play()

func play_game_over_music() -> void:
	"""Play game over music (5. Aurora)."""
	if GameSettings and not GameSettings.music_enabled:
		return

	_stop_all_music()
	current_music_state = MusicState.GAME_OVER
	in_game_music_loop = false

	if game_over_music:
		music_player.stream = game_over_music
		music_player.volume_db = MUSIC_VOLUME_DB
		music_player.play()

func play_boss_music(boss: Node = null) -> void:
	"""Play boss music (3. Lost) - fades out background, plays until boss dies or song ends."""
	if GameSettings and not GameSettings.music_enabled:
		return
	if not boss_music:
		return

	# Don't interrupt existing boss music
	if current_music_state == MusicState.BOSS:
		return

	active_boss = boss
	_start_overlay_music(boss_music, MusicState.BOSS)

func play_elite_music(elite: Node = null) -> void:
	"""Play elite music (4. Awakened) - plays until elite dies or 30 seconds, whichever first."""
	if GameSettings and not GameSettings.music_enabled:
		return
	if not elite_music:
		return

	# Don't interrupt boss music with elite music
	if current_music_state == MusicState.BOSS:
		return

	# Don't interrupt existing elite music
	if current_music_state == MusicState.ELITE:
		return

	active_elite = elite
	elite_music_timer = ELITE_MUSIC_MAX_DURATION
	_start_overlay_music(elite_music, MusicState.ELITE)

func on_boss_died() -> void:
	"""Called when boss dies - end boss music and return to background."""
	if current_music_state == MusicState.BOSS:
		active_boss = null
		_end_overlay_music()

func on_elite_died() -> void:
	"""Called when elite dies - end elite music and return to background."""
	if current_music_state == MusicState.ELITE:
		active_elite = null
		elite_music_timer = 0.0
		_end_overlay_music()

func stop_music() -> void:
	"""Stop all music immediately."""
	_stop_all_music()
	current_music_state = MusicState.NONE

func set_music_volume(volume_db: float) -> void:
	if music_player:
		music_player.volume_db = volume_db

# ============================================
# INTERNAL MUSIC HELPERS
# ============================================

func _stop_all_music() -> void:
	"""Stop all music players and cancel any fades."""
	if fade_tween:
		fade_tween.kill()
		fade_tween = null
	if overlay_fade_tween:
		overlay_fade_tween.kill()
		overlay_fade_tween = null

	if music_player:
		music_player.stop()
	if overlay_music_player:
		overlay_music_player.stop()

	in_game_music_loop = false
	elite_music_timer = 0.0
	active_boss = null
	active_elite = null

func _start_overlay_music(track: AudioStream, state: MusicState) -> void:
	"""Start boss/elite music with fade transition."""
	# Save current background music state
	if music_player.playing:
		background_music_position = music_player.get_playback_position()
		background_music_stream = music_player.stream
	previous_music_state = current_music_state
	current_music_state = state

	# Cancel any existing fade
	if fade_tween:
		fade_tween.kill()

	# Fade out background music over FADE_DURATION seconds
	fade_tween = create_tween()
	fade_tween.tween_property(music_player, "volume_db", -40.0, FADE_DURATION)
	fade_tween.tween_callback(func():
		music_player.stop()
	)

	# Start overlay music immediately (fade in)
	overlay_music_player.stream = track
	overlay_music_player.volume_db = -30.0  # Start quiet
	overlay_music_player.play()

	if overlay_fade_tween:
		overlay_fade_tween.kill()
	overlay_fade_tween = create_tween()
	overlay_fade_tween.tween_property(overlay_music_player, "volume_db", OVERLAY_VOLUME_DB, FADE_IN_DURATION)

func _end_overlay_music() -> void:
	"""End boss/elite music and fade back to background music."""
	if current_music_state != MusicState.BOSS and current_music_state != MusicState.ELITE:
		return

	# Cancel any existing fades
	if overlay_fade_tween:
		overlay_fade_tween.kill()

	# Fade out overlay music
	overlay_fade_tween = create_tween()
	overlay_fade_tween.tween_property(overlay_music_player, "volume_db", -40.0, FADE_IN_DURATION)
	overlay_fade_tween.tween_callback(func():
		overlay_music_player.stop()
	)

	# Restore background music state
	current_music_state = previous_music_state if previous_music_state == MusicState.GAME else MusicState.GAME

	# Resume background music from where it left off
	if background_music_stream and current_music_state == MusicState.GAME:
		if fade_tween:
			fade_tween.kill()

		music_player.stream = background_music_stream
		music_player.volume_db = -30.0  # Start quiet
		music_player.play()
		music_player.seek(background_music_position)
		in_game_music_loop = true

		fade_tween = create_tween()
		fade_tween.tween_property(music_player, "volume_db", MUSIC_VOLUME_DB, FADE_IN_DURATION)

# ============================================
# ACTIVE ABILITY SOUNDS
# ============================================

func play_dodge() -> void:
	# Dodge roll sound - use swoosh
	_play_sound(swoosh_sound, -3.0, 0.2)

func play_ability_sound(ability_id: String) -> void:
	# Route to specific sound based on ability type
	match ability_id:
		"cleave", "spinning_attack", "whirlwind", "bladestorm":
			play_swing()
		"shield_bash", "ground_slam", "seismic_slam", "earthquake":
			_play_sound(block_sound, 0.0, 0.1)  # Impact sound
		"power_shot", "multi_shot", "piercing_volley", "ballista_strike":
			play_arrow()
		"fireball", "meteor_strike":
			_play_sound(swoosh_sound, -2.0, 0.1)  # Fire whoosh
		"frost_nova", "totem_of_frost":
			_play_sound(buff_sound, -5.0, 0.2)  # Magic sound
		"chain_lightning", "thunderstorm":
			_play_sound(damage_sound, 0.0, 0.3)  # Zap sound
		"healing_light":
			play_heal()
		"shadowstep", "blade_rush", "savage_leap":
			_play_sound(swoosh_sound, -2.0, 0.15)
		_:
			# Default ability sound
			_play_sound(buff_sound, -5.0, 0.1)

func play_ground_slam() -> void:
	_play_sound(block_sound, 0.0, 0.1)

func play_fireball() -> void:
	_play_sound(swoosh_sound, -2.0, 0.1)

func play_frost() -> void:
	_play_sound(buff_sound, -5.0, 0.2)

func play_lightning() -> void:
	_play_sound(damage_sound, 0.0, 0.3)

func play_thunder() -> void:
	_play_sound(damage_sound, 2.0, 0.2)

func play_meteor() -> void:
	_play_sound(swoosh_sound, 0.0, 0.1)

func play_flash() -> void:
	_play_sound(buff_sound, 0.0)

func play_throw() -> void:
	_play_sound(swoosh_sound, -3.0, 0.2)

func play_leap() -> void:
	_play_sound(swoosh_sound, -2.0, 0.1)

func play_dash() -> void:
	_play_sound(swoosh_sound, -3.0, 0.15)

func play_shield_bash() -> void:
	_play_sound(block_sound, 0.0, 0.1)

func play_black_hole() -> void:
	_play_sound(buff_sound, -2.0, 0.1)

func play_time_stop() -> void:
	_play_sound(buff_sound, 0.0)

func play_deploy() -> void:
	_play_sound(ding_sound, -3.0)

func play_ballista() -> void:
	_play_sound(swoosh_sound, 2.0, 0.1)

func play_arrow_storm() -> void:
	_play_sound(swoosh_sound, 0.0, 0.1)

func play_whirlwind() -> void:
	play_swing()

func play_bladestorm() -> void:
	play_swing()

func play_omnislash() -> void:
	play_swing()

func play_shadowstep() -> void:
	_play_sound(swoosh_sound, -2.0, 0.15)
