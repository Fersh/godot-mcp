extends Node

# Sound Manager - handles all game sound effects with pooling and random variations

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

# Audio players pool for concurrent sounds
var audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 16

# Music player (separate from SFX pool)
var music_player: AudioStreamPlayer
var music1: AudioStream

func _ready() -> void:
	_load_sounds()
	_create_audio_pool()
	_setup_music_player()

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
	levelup_sound = load("res://assets/sounds/levelup.mp3")
	levelup_fanfare = load("res://assets/sounds/medieval_rpg_game_qu_#1-1763518583917.mp3")
	xp_sound = load("res://assets/sounds/xp.mp3")
	swoosh_sound = load("res://assets/sounds/swoosh.mp3")
	damage_sound = load("res://assets/sounds/damage.mp3")
	buff_sound = load("res://assets/sounds/buff.mp3")
	ding_sound = load("res://assets/sounds/ding.mp3")
	block_sound = load("res://assets/sounds/block.mp3")

func _create_audio_pool() -> void:
	for i in POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		audio_players.append(player)

func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -10.0  # Background music quieter than SFX
	add_child(music_player)

	# Load music
	music1 = load("res://assets/sounds/music1.mp3")

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

# Music controls
func play_music() -> void:
	if music_player and music1:
		# Check if music is enabled
		if GameSettings and not GameSettings.music_enabled:
			return
		music_player.stream = music1
		music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func set_music_volume(volume_db: float) -> void:
	if music_player:
		music_player.volume_db = volume_db

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
