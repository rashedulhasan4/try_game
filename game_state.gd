extends Node

signal state_changed
signal message_requested(text: String)

const SAVE_PATH := "user://empire_legacy_save.json"
const SAVE_VERSION := 2
const OFFLINE_CAP_SECONDS := 8 * 60 * 60
const DAY_SECONDS := 24 * 60 * 60

var cash: float = 2500.0
var lifetime_earnings: float = 0.0
var tap_value: float = 25.0
var deal_count := 0
var created_at: int = 0
var last_saved_at: int = 0
var pending_offline_income: float = 0.0
var tutorial_seen := false
var daily_last_claim_day := -1
var daily_streak := 0
var sound_enabled := true
var haptics_enabled := true
var achievements: Dictionary = {}

var achievement_catalog: Dictionary = {
	"first_deal": {"name": "First Deal", "description": "Earn money from your first active deal."},
	"first_business": {"name": "Founder", "description": "Open your first business."},
	"rising_value": {"name": "Rising Value", "description": "Reach a net worth of $10,000."},
	"milestone_five": {"name": "Breakthrough", "description": "Grow any business to level 5."},
	"millionaire": {"name": "Millionaire", "description": "Reach a net worth of $1,000,000."}
}

var businesses: Dictionary = {}
var business_catalog: Dictionary = {
	"street_brew": {
		"name": "Street Brew",
		"category": "Food & Drink",
		"description": "A compact coffee kiosk for busy commuters.",
		"base_price": 1500.0,
		"base_income": 2.5,
		"accent": Color("#F59E0B")
	},
	"quick_cart": {
		"name": "QuickCart",
		"category": "Retail",
		"description": "A neighborhood convenience store with fast turnover.",
		"base_price": 8500.0,
		"base_income": 10.0,
		"accent": Color("#34D399")
	},
	"pixel_forge": {
		"name": "PixelForge Studio",
		"category": "Technology",
		"description": "A small software studio building practical apps.",
		"base_price": 42000.0,
		"base_income": 42.0,
		"accent": Color("#60A5FA")
	},
	"swift_route": {
		"name": "SwiftRoute",
		"category": "Logistics",
		"description": "A growing delivery fleet for local businesses.",
		"base_price": 180000.0,
		"base_income": 145.0,
		"accent": Color("#A78BFA")
	},
	"harbor_hotel": {
		"name": "Harbor Hotel",
		"category": "Hospitality",
		"description": "A premium city hotel for business travelers.",
		"base_price": 900000.0,
		"base_income": 620.0,
		"accent": Color("#F472B6")
	}
}

var _save_accumulator := 0.0
var _achievement_accumulator := 0.0
var _audio_player: AudioStreamPlayer
var _tap_stream: AudioStreamWAV
var _success_stream: AudioStreamWAV

func _ready() -> void:
	setup_audio()
	load_game()

func _process(delta: float) -> void:
	var income := income_per_second() * delta
	if income > 0.0:
		cash += income
		lifetime_earnings += income
		state_changed.emit()

	_save_accumulator += delta
	if _save_accumulator >= 10.0:
		_save_accumulator = 0.0
		save_game()

	_achievement_accumulator += delta
	if _achievement_accumulator >= 1.0:
		_achievement_accumulator = 0.0
		check_achievements()

func tap_income() -> void:
	cash += tap_value
	lifetime_earnings += tap_value
	deal_count += 1
	play_feedback("tap")
	check_achievements()
	state_changed.emit()

func business_level(id: String) -> int:
	return int(businesses.get(id, 0))

func business_income(id: String) -> float:
	var level := business_level(id)
	if level <= 0:
		return 0.0
	var data: Dictionary = business_catalog[id]
	var growth_bonus := 1.0 + (float(level - 1) * 0.15)
	return float(data.base_income) * float(level) * growth_bonus * business_milestone_multiplier(level)

func business_milestone_multiplier(level: int) -> float:
	var multiplier := 1.0
	for milestone in [5, 10, 25]:
		if level >= milestone:
			multiplier *= 2.0
	return multiplier

func next_business_milestone(level: int) -> int:
	for milestone in [5, 10, 25]:
		if level < milestone:
			return milestone
	return 0

func income_per_second() -> float:
	var total := 0.0
	for id in business_catalog:
		total += business_income(id)
	return total

func net_worth() -> float:
	var value := cash
	for id in businesses:
		var level := business_level(id)
		if level > 0:
			value += float(business_catalog[id].base_price) * (1.0 + float(level - 1) * 0.55)
	return value

func owned_business_count() -> int:
	var count := 0
	for id in businesses:
		if business_level(id) > 0:
			count += 1
	return count

func next_business_cost(id: String) -> float:
	var level := business_level(id)
	var base_price := float(business_catalog[id].base_price)
	if level == 0:
		return base_price
	return base_price * 0.65 * pow(1.62, float(level - 1))

func buy_or_upgrade_business(id: String) -> bool:
	if not business_catalog.has(id):
		return false
	var cost := next_business_cost(id)
	if cash < cost:
		message_requested.emit("You need %s more." % format_money(cost - cash))
		return false
	cash -= cost
	var old_level := business_level(id)
	businesses[id] = old_level + 1
	var verb := "Opened" if old_level == 0 else "Upgraded"
	message_requested.emit("%s %s." % [verb, business_catalog[id].name])
	play_feedback("success")
	check_achievements()
	state_changed.emit()
	save_game()
	return true

func claim_offline_income() -> float:
	var amount := pending_offline_income
	if amount > 0.0:
		cash += amount
		lifetime_earnings += amount
		pending_offline_income = 0.0
		play_feedback("success")
		check_achievements()
		state_changed.emit()
		save_game()
	return amount

func reset_game() -> void:
	cash = 2500.0
	lifetime_earnings = 0.0
	tap_value = 25.0
	deal_count = 0
	businesses = {}
	created_at = int(Time.get_unix_time_from_system())
	last_saved_at = created_at
	pending_offline_income = 0.0
	tutorial_seen = false
	daily_last_claim_day = -1
	daily_streak = 0
	achievements = {}
	state_changed.emit()
	save_game()

func mark_tutorial_seen() -> void:
	tutorial_seen = true
	save_game()

func current_day_index() -> int:
	return int(Time.get_unix_time_from_system() / float(DAY_SECONDS))

func can_claim_daily_reward() -> bool:
	return daily_last_claim_day != current_day_index()

func daily_reward_amount() -> float:
	var next_streak := daily_streak + 1
	if daily_last_claim_day < current_day_index() - 1:
		next_streak = 1
	return 500.0 * float(mini(next_streak, 7))

func claim_daily_reward() -> float:
	if not can_claim_daily_reward():
		return 0.0
	var today := current_day_index()
	if daily_last_claim_day == today - 1:
		daily_streak = mini(daily_streak + 1, 7)
	else:
		daily_streak = 1
	daily_last_claim_day = today
	var reward := 500.0 * float(daily_streak)
	cash += reward
	lifetime_earnings += reward
	play_feedback("success")
	check_achievements()
	state_changed.emit()
	save_game()
	return reward

func achievement_unlocked(id: String) -> bool:
	return bool(achievements.get(id, false))

func unlocked_achievement_count() -> int:
	var count := 0
	for id in achievement_catalog:
		if achievement_unlocked(id):
			count += 1
	return count

func check_achievements() -> void:
	try_unlock_achievement("first_deal", deal_count >= 1)
	try_unlock_achievement("first_business", owned_business_count() >= 1)
	try_unlock_achievement("rising_value", net_worth() >= 10_000.0)
	var has_level_five := false
	for id in businesses:
		if business_level(id) >= 5:
			has_level_five = true
			break
	try_unlock_achievement("milestone_five", has_level_five)
	try_unlock_achievement("millionaire", net_worth() >= 1_000_000.0)

func try_unlock_achievement(id: String, condition: bool) -> void:
	if not condition or achievement_unlocked(id):
		return
	achievements[id] = true
	message_requested.emit("Achievement unlocked: %s" % achievement_catalog[id].name)
	play_feedback("success")
	save_game()

func set_sound_enabled(value: bool) -> void:
	sound_enabled = value
	if value:
		play_feedback("tap")
	save_game()

func set_haptics_enabled(value: bool) -> void:
	haptics_enabled = value
	if value:
		Input.vibrate_handheld(20)
	save_game()

func play_feedback(kind: String) -> void:
	if haptics_enabled:
		Input.vibrate_handheld(30 if kind == "success" else 10)
	if sound_enabled and is_instance_valid(_audio_player):
		_audio_player.stream = _success_stream if kind == "success" else _tap_stream
		_audio_player.play()

func setup_audio() -> void:
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	_tap_stream = create_tone(520.0, 0.045, 0.16)
	_success_stream = create_tone(760.0, 0.09, 0.20)

func create_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(float(sample_rate) * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var fade := 1.0 - (float(i) / float(sample_count))
		var wave := sin(TAU * frequency * float(i) / float(sample_rate))
		var sample := int(wave * fade * volume * 32767.0)
		bytes[i * 2] = sample & 0xFF
		bytes[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream

func save_game() -> void:
	last_saved_at = int(Time.get_unix_time_from_system())
	var payload := {
		"version": SAVE_VERSION,
		"cash": cash,
		"lifetime_earnings": lifetime_earnings,
		"tap_value": tap_value,
		"deal_count": deal_count,
		"businesses": businesses,
		"created_at": created_at,
		"last_saved_at": last_saved_at,
		"tutorial_seen": tutorial_seen,
		"daily_last_claim_day": daily_last_claim_day,
		"daily_streak": daily_streak,
		"sound_enabled": sound_enabled,
		"haptics_enabled": haptics_enabled,
		"achievements": achievements
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))

func load_game() -> void:
	var now := int(Time.get_unix_time_from_system())
	if not FileAccess.file_exists(SAVE_PATH):
		created_at = now
		last_saved_at = now
		save_game()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		reset_game()
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		reset_game()
		return

	cash = maxf(float(parsed.get("cash", 2500.0)), 0.0)
	lifetime_earnings = maxf(float(parsed.get("lifetime_earnings", 0.0)), 0.0)
	tap_value = maxf(float(parsed.get("tap_value", 25.0)), 1.0)
	deal_count = maxi(int(parsed.get("deal_count", 0)), 0)
	businesses = parsed.get("businesses", {})
	created_at = int(parsed.get("created_at", now))
	last_saved_at = int(parsed.get("last_saved_at", now))
	tutorial_seen = bool(parsed.get("tutorial_seen", false))
	daily_last_claim_day = int(parsed.get("daily_last_claim_day", -1))
	daily_streak = int(parsed.get("daily_streak", 0))
	sound_enabled = bool(parsed.get("sound_enabled", true))
	haptics_enabled = bool(parsed.get("haptics_enabled", true))
	achievements = parsed.get("achievements", {})

	var offline_seconds := clampi(now - last_saved_at, 0, OFFLINE_CAP_SECONDS)
	pending_offline_income = income_per_second() * float(offline_seconds) * 0.80
	last_saved_at = now

func format_money(value: float) -> String:
	var absolute := absf(value)
	if absolute >= 1_000_000_000.0:
		return "$%.2fB" % (value / 1_000_000_000.0)
	if absolute >= 1_000_000.0:
		return "$%.2fM" % (value / 1_000_000.0)
	if absolute >= 1_000.0:
		return "$%.2fK" % (value / 1_000.0)
	return "$%.0f" % value
