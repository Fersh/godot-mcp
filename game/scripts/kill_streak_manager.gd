extends Node

# Kill Streak Manager - Tracks combo kills with escalating rewards and epic effects
# Add to autoload as "KillStreakManager"

signal streak_changed(streak: int, tier: int)
signal streak_milestone(tier: int, name: String)
signal streak_ended(final_streak: int)

# Streak tracking
var current_streak: int = 0
var streak_timer: float = 0.0
var streak_decay_time: float = 5.0  # Time between kills to maintain streak

# Tier thresholds and names
const TIER_THRESHOLDS: Array[int] = [0, 5, 10, 20, 35, 50, 75, 100]
const TIER_NAMES: Array[String] = ["", "KILLING SPREE", "RAMPAGE", "UNSTOPPABLE", "DOMINATING", "GODLIKE", "LEGENDARY", "BEYOND GODLIKE"]
const TIER_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0),       # White (0)
	Color(1.0, 0.9, 0.3),       # Yellow (5)
	Color(1.0, 0.6, 0.2),       # Orange (10)
	Color(1.0, 0.3, 0.2),       # Red (20)
	Color(0.9, 0.2, 0.9),       # Purple (35)
	Color(0.3, 0.8, 1.0),       # Cyan (50)
	Color(1.0, 0.85, 0.0),      # Gold (75)
	Color(1.0, 1.0, 1.0),       # Prismatic/White (100)
]

# Reward multipliers per tier
const XP_MULTIPLIERS: Array[float] = [1.0, 1.1, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
const GOLD_MULTIPLIERS: Array[float] = [1.0, 1.1, 1.2, 1.4, 1.6, 1.8, 2.2, 2.5]

var current_tier: int = 0
var highest_streak: int = 0
var highest_tier: int = 0

# Audio pitch scaling for combo sounds
var base_pitch: float = 0.8
var pitch_increment: float = 0.03
var max_pitch: float = 1.6

# UI reference
var streak_ui: CanvasLayer = null
var pixel_font: Font = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_font()

func _load_font() -> void:
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

func _process(delta: float) -> void:
	if current_streak > 0:
		streak_timer -= delta
		if streak_timer <= 0:
			_end_streak()

func register_kill() -> void:
	"""Called when player kills an enemy."""
	current_streak += 1
	streak_timer = streak_decay_time

	# Track highest
	if current_streak > highest_streak:
		highest_streak = current_streak

	# Check for tier advancement
	var new_tier = _calculate_tier()
	var tier_up = new_tier > current_tier
	current_tier = new_tier

	if current_tier > highest_tier:
		highest_tier = current_tier

	# Emit signals
	emit_signal("streak_changed", current_streak, current_tier)

	# Tier milestone reached
	if tier_up and current_tier > 0:
		_on_tier_milestone(current_tier)

func _calculate_tier() -> int:
	for i in range(TIER_THRESHOLDS.size() - 1, -1, -1):
		if current_streak >= TIER_THRESHOLDS[i]:
			return i
	return 0

func _on_tier_milestone(tier: int) -> void:
	emit_signal("streak_milestone", tier, TIER_NAMES[tier])

	# Play escalating sound
	if SoundManager:
		_play_milestone_sound(tier)

	# Haptic feedback
	if HapticManager:
		_play_milestone_haptic(tier)

	# Screen effects
	if JuiceManager:
		_play_milestone_juice(tier)

func _play_milestone_sound(tier: int) -> void:
	# Play levelup sound with escalating pitch
	var pitch = base_pitch + (tier * pitch_increment * 2)
	pitch = min(pitch, max_pitch)

	# Use the sound manager's internal player for custom pitch
	if SoundManager.has_method("_play_sound"):
		SoundManager._play_sound(SoundManager.levelup_sound, 0.0, 0.0)

func _play_milestone_haptic(tier: int) -> void:
	match tier:
		1, 2:
			HapticManager.medium()
		3, 4:
			HapticManager.heavy()
		5, 6, 7:
			HapticManager.ultimate()

func _play_milestone_juice(tier: int) -> void:
	match tier:
		1:
			JuiceManager.shake_small()
		2:
			JuiceManager.shake_small()
			JuiceManager.chromatic_pulse(0.3)
		3:
			JuiceManager.shake_medium()
			JuiceManager.chromatic_pulse(0.5)
		4:
			JuiceManager.shake_medium()
			JuiceManager.chromatic_pulse(0.7)
		5, 6, 7:
			JuiceManager.shake_large()
			JuiceManager.chromatic_pulse(1.0)
			JuiceManager.hitstop_small()

func _end_streak() -> void:
	if current_streak >= 5:
		emit_signal("streak_ended", current_streak)
	current_streak = 0
	current_tier = 0

func get_xp_multiplier() -> float:
	return XP_MULTIPLIERS[current_tier]

func get_gold_multiplier() -> float:
	return GOLD_MULTIPLIERS[current_tier]

func get_current_streak() -> int:
	return current_streak

func get_current_tier() -> int:
	return current_tier

func get_tier_name() -> String:
	return TIER_NAMES[current_tier]

func get_tier_color() -> Color:
	return TIER_COLORS[current_tier]

func get_streak_progress() -> float:
	"""Returns 0-1 progress toward streak decay."""
	return streak_timer / streak_decay_time if streak_decay_time > 0 else 0.0

func get_kill_pitch() -> float:
	"""Get pitch for hit/kill sounds based on streak."""
	var streak_bonus = min(current_streak * pitch_increment, max_pitch - base_pitch)
	return base_pitch + streak_bonus

func reset() -> void:
	current_streak = 0
	current_tier = 0
	streak_timer = 0.0
	highest_streak = 0
	highest_tier = 0
