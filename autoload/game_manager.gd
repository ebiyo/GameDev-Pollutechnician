extends Node

enum Phase { PREP, ACTIVE, END }
enum Difficulty { EASY, NORMAL, HARD }

signal day_started()
signal day_ended(money_earned: int)
signal game_won()

const MAX_CARDS: int = 5
const RAIN_CARD_TYPE := "rain"
const REPAIR_KIT_CARD_TYPE := "repair_kit"
const FREEZE_CARD_TYPE := "freeze"
const RAIN_CARD_POLLUTION_REDUCTION: float = 15.0
const FREEZE_CARD_DURATION_MINUTES: float = 60.0
const CAR_FREE_DAY_POLLUTION_MULTIPLIER: float = 0.65
const DEFAULT_BASE_REPAIR_AMOUNT: float = 12.0

const CARD_DEFINITIONS := {
	RAIN_CARD_TYPE: {
		"name": "Rain Card",
		"description": "Instantly reduces pollution by 15."
	},
	REPAIR_KIT_CARD_TYPE: {
		"name": "Repair Kit Card",
		"description": "Repairs all machines to full durability."
	},
	FREEZE_CARD_TYPE: {
		"name": "Freeze Card",
		"description": "Freezes the pollution meter for 60 in-game minutes."
	}
}

const DIFFICULTY_CONFIGS := {
	Difficulty.EASY: {
		"name": "Easy",
		"max_cards": 5,
		"total_days": 3,
		"day_duration": 90.0,
		"base_reward": 50,
		"low_pollution_bonus": 30,
		"low_pollution_bonus_threshold": 40.0,
		"repair_miss_penalty": 1.2,
		"base_pollution_rate": 3.0,
		"machine_drain_multiplier": 1.0,
		"overclock_efficiency_bonus": 0.4,
		"machine_efficiency_multiplier": 1.0,
		"over_limit_threshold": 80.0,
		"cumulative_limit_minutes": 200.0,
		"good_events_enabled": true,
		"event_interval_min": 20.0,
		"event_interval_max": 40.0
	},
	Difficulty.NORMAL: {
		"name": "Normal",
		"max_cards": 3,
		"total_days": 7,
		"day_duration": 85.0,
		"base_reward": 50,
		"low_pollution_bonus": 20,
		"low_pollution_bonus_threshold": 40.0,
		"repair_miss_penalty": 2.4,
		"base_pollution_rate": 3.35,
		"machine_drain_multiplier": 1.12,
		"overclock_efficiency_bonus": 0.4,
		"machine_efficiency_multiplier": 1.0,
		"over_limit_threshold": 80.0,
		"cumulative_limit_minutes": 165.0,
		"good_events_enabled": true,
		"event_interval_min": 18.0,
		"event_interval_max": 32.0
	},
	Difficulty.HARD: {
		"name": "Hard",
		"max_cards": 3,
		"total_days": 7,
		"day_duration": 80.0,
		"base_reward": 60,
		"low_pollution_bonus": 12,
		"low_pollution_bonus_threshold": 40.0,
		"repair_miss_penalty": 3.6,
		"base_pollution_rate": 4.0,
		"machine_drain_multiplier": 1.28,
		"overclock_efficiency_bonus": 0.5,
		"machine_efficiency_multiplier": 1,
		"over_limit_threshold": 80.0,
		"cumulative_limit_minutes": 125.0,
		"good_events_enabled": false,
		"event_interval_min": 18.0,
		"event_interval_max": 28.0
	}
}

var current_phase: Phase = Phase.PREP
var current_day: int = 1
var total_days: int = 3
var day_duration: float = 90.0
var day_timer: float = 0.0
var money: int = 0
var minutes_above_threshold: float = 0.0
var repair_efficiency_bonus: float = 0.0
var player_speed_multiplier: float = 1.0
var has_flash_upgrade: bool = false
var day_pollution_rate_multiplier: float = 1.0
var day_random_events_blocked: bool = false
var next_day_pollution_rate_multiplier: float = 1.0
var next_day_random_events_blocked: bool = false
var current_difficulty: Difficulty = Difficulty.EASY
var difficulty_name: String = "Easy"
var base_reward: int = 50
var low_pollution_bonus: int = 30
var low_pollution_bonus_threshold: float = 40.0
var good_events_enabled: bool = true
var event_interval_min: float = 20.0
var event_interval_max: float = 40.0
var base_repair_amount: float = DEFAULT_BASE_REPAIR_AMOUNT
var repair_miss_penalty: float = 0.5
var max_cards: int = MAX_CARDS
var machine_drain_multiplier: float = 1.0
var overclock_efficiency_bonus: float = 0.4
var machine_efficiency_multiplier: float = 1.0
var _card_counts := {
	RAIN_CARD_TYPE: 0,
	REPAIR_KIT_CARD_TYPE: 0,
	FREEZE_CARD_TYPE: 0
}


func start_new_run(difficulty: Difficulty) -> void:
	var config: Dictionary = DIFFICULTY_CONFIGS.get(difficulty, DIFFICULTY_CONFIGS[Difficulty.EASY])

	current_difficulty = difficulty
	difficulty_name = String(config.get("name", "Easy"))
	current_phase = Phase.PREP
	current_day = 1
	total_days = int(config.get("total_days", 3))
	max_cards = int(config.get("max_cards", MAX_CARDS))
	day_duration = float(config.get("day_duration", 90.0))
	day_timer = day_duration
	money = 0
	minutes_above_threshold = 0.0
	repair_efficiency_bonus = 0.0
	player_speed_multiplier = 1.0
	has_flash_upgrade = false
	day_pollution_rate_multiplier = 1.0
	day_random_events_blocked = false
	next_day_pollution_rate_multiplier = 1.0
	next_day_random_events_blocked = false
	base_reward = int(config.get("base_reward", 50))
	low_pollution_bonus = int(config.get("low_pollution_bonus", 30))
	low_pollution_bonus_threshold = float(config.get("low_pollution_bonus_threshold", 40.0))
	good_events_enabled = bool(config.get("good_events_enabled", true))
	event_interval_min = float(config.get("event_interval_min", 20.0))
	event_interval_max = float(config.get("event_interval_max", 40.0))
	base_repair_amount = DEFAULT_BASE_REPAIR_AMOUNT
	repair_miss_penalty = float(config.get("repair_miss_penalty", 0.5))
	machine_drain_multiplier = float(config.get("machine_drain_multiplier", 1.0))
	overclock_efficiency_bonus = float(config.get("overclock_efficiency_bonus", 0.4))
	machine_efficiency_multiplier = float(config.get("machine_efficiency_multiplier", 1.0))

	for card_type in get_card_types():
		_card_counts[card_type] = 0

	RepairManager.reset_run()
	PollutionManager.reset_run(
		float(config.get("base_pollution_rate", 3.0)),
		float(config.get("over_limit_threshold", 80.0)),
		float(config.get("cumulative_limit_minutes", 200.0))
	)
	EventManager.reset_run()


func get_total_cards() -> int:
	var total := 0
	for count_variant in _card_counts.values():
		total += int(count_variant)
	return total


func get_card_types() -> Array[String]:
	return [RAIN_CARD_TYPE, REPAIR_KIT_CARD_TYPE, FREEZE_CARD_TYPE]


func get_card_count(card_type: String) -> int:
	return int(_card_counts.get(card_type, 0))


func get_card_name(card_type: String) -> String:
	var definition: Dictionary = CARD_DEFINITIONS.get(card_type, {})
	return String(definition.get("name", "Card"))


func get_card_description(card_type: String) -> String:
	var definition: Dictionary = CARD_DEFINITIONS.get(card_type, {})
	return String(definition.get("description", ""))


func get_card_inventory_signature() -> String:
	var parts: PackedStringArray = []
	for card_type in get_card_types():
		parts.append("%s:%d" % [card_type, get_card_count(card_type)])
	return "|".join(parts)


func get_current_repair_amount() -> float:
	return base_repair_amount + repair_efficiency_bonus


func add_card(card_type: String) -> bool:
	if get_total_cards() >= max_cards:
		return false

	if !_card_counts.has(card_type):
		return false

	_card_counts[card_type] = get_card_count(card_type) + 1
	return true


func queue_car_free_day() -> void:
	next_day_pollution_rate_multiplier = minf(
		next_day_pollution_rate_multiplier,
		CAR_FREE_DAY_POLLUTION_MULTIPLIER
	)


func queue_shield_day() -> void:
	next_day_random_events_blocked = true


func use_card(card_type: String) -> bool:
	if current_phase != Phase.ACTIVE:
		return false

	if get_card_count(card_type) <= 0:
		return false

	match card_type:
		RAIN_CARD_TYPE:
			_card_counts[card_type] = get_card_count(card_type) - 1
			PollutionManager.pollution = clampf(
				PollutionManager.pollution - RAIN_CARD_POLLUTION_REDUCTION,
				0.0,
				100.0
			)
			PollutionManager.pollution_changed.emit(PollutionManager.pollution)
			EventManager.log_instant_effect("Rain Card", "-15 pollution")
			return true
		REPAIR_KIT_CARD_TYPE:
			_card_counts[card_type] = get_card_count(card_type) - 1
			_repair_all_machines()
			EventManager.log_instant_effect("Repair Kit Card", "all machines repaired")
			return true
		FREEZE_CARD_TYPE:
			_card_counts[card_type] = get_card_count(card_type) - 1
			PollutionManager.freeze_for_minutes(FREEZE_CARD_DURATION_MINUTES)
			EventManager.track_custom_timed_effect(
				"freeze_card",
				"Freeze Card",
				"pollution frozen",
				FREEZE_CARD_DURATION_MINUTES
			)
			return true

	return false


func _repair_all_machines() -> void:
	for machine_node in get_tree().get_nodes_in_group("machines"):
		var machine := machine_node as Machine
		if machine == null:
			continue

		machine.durability = machine.max_durability
		machine.durability_changed.emit(machine.durability)


func _process(delta: float) -> void:
	if current_phase != Phase.ACTIVE:
		return

	var time_scale := PollutionManager.ingame_day_minutes / maxf(day_duration, 0.001)
	if PollutionManager.pollution >= PollutionManager.over_limit_pollution_threshold:
		minutes_above_threshold += delta * time_scale

	day_timer = maxf(day_timer - delta, 0.0)

	if day_timer <= 0.0:
		end_day()


func start_day() -> void:
	current_phase = Phase.ACTIVE
	day_timer = day_duration
	minutes_above_threshold = 0.0
	day_pollution_rate_multiplier = next_day_pollution_rate_multiplier
	day_random_events_blocked = next_day_random_events_blocked
	next_day_pollution_rate_multiplier = 1.0
	next_day_random_events_blocked = false
	day_started.emit()


func end_day() -> void:
	current_phase = Phase.END
	day_pollution_rate_multiplier = 1.0
	day_random_events_blocked = false

	var bonus: int = low_pollution_bonus if PollutionManager.pollution < low_pollution_bonus_threshold else 0
	var money_earned: int = max(0, base_reward + bonus)

	money += money_earned
	current_day += 1

	if current_day > total_days:
		game_won.emit()
	else:
		day_ended.emit(money_earned)


func start_next_day() -> void:
	start_day()
