extends Node

# Daily Login Manager - Tracks daily login rewards and streaks
# Add to autoload as "DailyLoginManager"

const SAVE_PATH = "user://daily_login.save"
const GRACE_PERIOD_HOURS = 24  # Hours before streak resets

signal reward_available()
signal reward_claimed(day: int, coins: int, bonus_text: String)
signal streak_broken()

# Daily reward schedule (7-day cycle)
const DAILY_REWARDS = [
	{"day": 1, "coins": 100, "special": ""},
	{"day": 2, "coins": 150, "special": ""},
	{"day": 3, "coins": 200, "special": ""},
	{"day": 4, "coins": 0, "special": "random_passive"},  # Random ability unlock
	{"day": 5, "coins": 300, "special": ""},
	{"day": 6, "coins": 400, "special": ""},
	{"day": 7, "coins": 1000, "special": "jackpot"},  # Jackpot day
]

# Streak bonus thresholds
const STREAK_BONUSES = {
	7: 0.5,   # +50% on day 7
	14: 1.0,  # +100% on day 7
	30: 2.0,  # +200% on day 7
}

# State
var last_login_date: String = ""
var last_login_timestamp: int = 0
var current_streak: int = 0
var day_in_cycle: int = 1  # 1-7
var claimed_today: bool = false
var total_days_logged_in: int = 0

func _ready() -> void:
	load_data()
	_check_login_status()

func _check_login_status() -> void:
	"""Check if it's a new day and update streak."""
	var today = Time.get_date_string_from_system()
	var now_timestamp = Time.get_unix_time_from_system()

	if last_login_date == "":
		# First time login
		last_login_date = today
		last_login_timestamp = int(now_timestamp)
		current_streak = 1
		day_in_cycle = 1
		claimed_today = false
		save_data()
		reward_available.emit()
		return

	if last_login_date == today:
		# Same day, already checked in
		if not claimed_today:
			reward_available.emit()
		return

	# Different day - check if streak continues or breaks
	var hours_since_last = (now_timestamp - last_login_timestamp) / 3600.0

	if hours_since_last <= 48:  # Within 2 days (grace period)
		# Streak continues
		current_streak += 1
		day_in_cycle = ((day_in_cycle) % 7) + 1  # Cycle 1-7
		claimed_today = false
		last_login_date = today
		last_login_timestamp = int(now_timestamp)
		total_days_logged_in += 1
		save_data()
		reward_available.emit()
	else:
		# Streak broken
		current_streak = 1
		day_in_cycle = 1
		claimed_today = false
		last_login_date = today
		last_login_timestamp = int(now_timestamp)
		total_days_logged_in += 1
		save_data()
		streak_broken.emit()
		reward_available.emit()

func can_claim_reward() -> bool:
	"""Check if daily reward can be claimed."""
	return not claimed_today

func get_today_reward() -> Dictionary:
	"""Get today's reward info."""
	var reward = DAILY_REWARDS[day_in_cycle - 1].duplicate()
	reward["streak"] = current_streak
	reward["day_in_cycle"] = day_in_cycle

	# Apply streak bonus on day 7
	if day_in_cycle == 7:
		var bonus_multiplier = 0.0
		for threshold in STREAK_BONUSES:
			if current_streak >= threshold:
				bonus_multiplier = STREAK_BONUSES[threshold]
		if bonus_multiplier > 0:
			reward["bonus_multiplier"] = bonus_multiplier
			reward["bonus_coins"] = int(reward["coins"] * bonus_multiplier)
			reward["total_coins"] = reward["coins"] + reward["bonus_coins"]
		else:
			reward["total_coins"] = reward["coins"]
	else:
		reward["total_coins"] = reward["coins"]

	return reward

func claim_daily_reward() -> Dictionary:
	"""Claim today's reward. Returns reward info or empty dict if already claimed."""
	if claimed_today:
		return {}

	var reward = get_today_reward()

	# Award coins
	if reward["total_coins"] > 0 and StatsManager:
		StatsManager.spendable_coins += reward["total_coins"]
		StatsManager.save_stats()

	# Award special rewards
	var bonus_text = ""
	if reward["special"] == "random_passive" and UnlocksManager:
		var unlocked = UnlocksManager._unlock_random_passive()
		if unlocked != "":
			bonus_text = "Unlocked: " + _format_ability_name(unlocked)
		else:
			# No more passives to unlock, give extra coins instead
			reward["total_coins"] += 500
			if StatsManager:
				StatsManager.spendable_coins += 500
				StatsManager.save_stats()
			bonus_text = "+500 bonus coins!"
	elif reward["special"] == "jackpot":
		bonus_text = "JACKPOT!"

	claimed_today = true
	save_data()

	reward_claimed.emit(day_in_cycle, reward["total_coins"], bonus_text)
	return reward

func _format_ability_name(ability_id: String) -> String:
	"""Format ability ID to readable name."""
	return ability_id.replace("_", " ").capitalize()

func get_streak() -> int:
	return current_streak

func get_day_in_cycle() -> int:
	return day_in_cycle

func get_total_days() -> int:
	return total_days_logged_in

func get_next_streak_bonus() -> Dictionary:
	"""Get info about next streak bonus threshold."""
	for threshold in STREAK_BONUSES:
		if current_streak < threshold:
			return {
				"threshold": threshold,
				"bonus": STREAK_BONUSES[threshold],
				"days_remaining": threshold - current_streak
			}
	return {"threshold": -1, "bonus": 0, "days_remaining": 0}  # Max streak reached

func get_week_preview() -> Array:
	"""Get preview of all 7 days with claimed status."""
	var preview: Array = []
	for i in range(7):
		var day_num = i + 1
		var reward = DAILY_REWARDS[i].duplicate()
		reward["day"] = day_num
		reward["is_today"] = (day_num == day_in_cycle)
		reward["is_claimed"] = (day_num < day_in_cycle) or (day_num == day_in_cycle and claimed_today)
		reward["is_future"] = day_num > day_in_cycle
		preview.append(reward)
	return preview

# ============================================
# PERSISTENCE
# ============================================

func save_data() -> void:
	var save_data = {
		"last_login_date": last_login_date,
		"last_login_timestamp": last_login_timestamp,
		"current_streak": current_streak,
		"day_in_cycle": day_in_cycle,
		"claimed_today": claimed_today,
		"total_days_logged_in": total_days_logged_in
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()

		if data is Dictionary:
			last_login_date = data.get("last_login_date", "")
			last_login_timestamp = data.get("last_login_timestamp", 0)
			current_streak = data.get("current_streak", 0)
			day_in_cycle = data.get("day_in_cycle", 1)
			claimed_today = data.get("claimed_today", false)
			total_days_logged_in = data.get("total_days_logged_in", 0)

func reset_all_data() -> void:
	"""Reset all daily login progress."""
	last_login_date = ""
	last_login_timestamp = 0
	current_streak = 0
	day_in_cycle = 1
	claimed_today = false
	total_days_logged_in = 0
	save_data()
