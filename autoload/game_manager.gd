extends Node

enum Phase { PREP, ACTIVE, END }

signal day_started()
signal day_ended(money_earned: int)
signal game_won()

var current_phase: Phase = Phase.PREP
var current_day: int = 1
var total_days: int = 3
var day_duration: float = 90.0
var day_timer: float = 0.0
var money: int = 0


func _process(delta: float) -> void:
	if current_phase != Phase.ACTIVE:
		return

	day_timer = maxf(day_timer - delta, 0.0)

	if day_timer <= 0.0:
		end_day()


func start_day() -> void:
	current_phase = Phase.ACTIVE
	day_timer = day_duration
	day_started.emit()


func end_day() -> void:
	current_phase = Phase.END

	var money_earned := 50
	if PollutionManager.pollution < 40.0:
		money_earned += 25

	money += money_earned
	current_day += 1

	if current_day > total_days:
		game_won.emit()
	else:
		day_ended.emit(money_earned)


func start_next_day() -> void:
	current_phase = Phase.ACTIVE
	day_timer = day_duration
	day_started.emit()
