extends Node

enum Phase { PREP, ACTIVE, END }

signal day_started()
signal day_ended(money_earned: int)
signal game_won()

const MAX_CARDS: int = 5
const RAIN_CARD_TYPE := "rain"
const REPAIR_KIT_CARD_TYPE := "repair_kit"
const RAIN_CARD_POLLUTION_REDUCTION: float = 15.0

var current_phase: Phase = Phase.PREP
var current_day: int = 1
var total_days: int = 3
var day_duration: float = 90.0
var day_timer: float = 0.0
var money: int = 0
var minutes_above_threshold: float = 0.0
var rain_cards: int = 0
var repair_kit_cards: int = 0
var repair_efficiency_bonus: float = 0.0


func get_total_cards() -> int:
	return rain_cards + repair_kit_cards


func add_card(card_type: String) -> bool:
	if get_total_cards() >= MAX_CARDS:
		return false

	match card_type:
		RAIN_CARD_TYPE:
			rain_cards += 1
			return true
		REPAIR_KIT_CARD_TYPE:
			repair_kit_cards += 1
			return true

	return false


func use_card(card_type: String) -> bool:
	if current_phase != Phase.ACTIVE:
		return false

	match card_type:
		RAIN_CARD_TYPE:
			if rain_cards <= 0:
				return false

			rain_cards -= 1
			PollutionManager.pollution = clampf(
				PollutionManager.pollution - RAIN_CARD_POLLUTION_REDUCTION,
				0.0,
				100.0
			)
			PollutionManager.pollution_changed.emit(PollutionManager.pollution)
			return true
		REPAIR_KIT_CARD_TYPE:
			if repair_kit_cards <= 0:
				return false

			repair_kit_cards -= 1
			_repair_all_machines()
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
	if PollutionManager.pollution >= 80.0:
		minutes_above_threshold += delta * time_scale

	day_timer = maxf(day_timer - delta, 0.0)

	if day_timer <= 0.0:
		end_day()


func start_day() -> void:
	current_phase = Phase.ACTIVE
	day_timer = day_duration
	minutes_above_threshold = 0.0
	day_started.emit()


func end_day() -> void:
	current_phase = Phase.END

	var base: int = 50
	var bonus: int = 30 if PollutionManager.pollution < 40.0 else 0
	var penalty: int = int(minutes_above_threshold) * 10
	var money_earned: int = max(0, base + bonus - penalty)

	money += money_earned
	current_day += 1

	if current_day > total_days:
		game_won.emit()
	else:
		day_ended.emit(money_earned)


func start_next_day() -> void:
	current_phase = Phase.ACTIVE
	day_timer = day_duration
	minutes_above_threshold = 0.0
	day_started.emit()
