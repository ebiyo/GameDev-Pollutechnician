extends Node

signal pollution_changed(value: float)
signal game_over()

var pollution: float = 0.0
var base_increase_rate: float = 3.0
var cumulative_minutes_over_threshold: float = 0.0
var frozen_minutes_remaining: float = 0.0

@export var over_limit_pollution_threshold: float = 80.0
@export var lose_threshold_minutes: float = 200.0
@export var ingame_day_minutes: float = 600.0


func _ready() -> void:
	GameManager.day_started.connect(_on_day_started)
	pollution_changed.emit(pollution)


func _process(delta: float) -> void:
	if GameManager.current_phase != GameManager.Phase.ACTIVE:
		return

	var time_scale := ingame_day_minutes / maxf(GameManager.day_duration, 0.001)
	if frozen_minutes_remaining > 0.0:
		frozen_minutes_remaining = maxf(frozen_minutes_remaining - (delta * time_scale), 0.0)
	else:
		var total_efficiency := 0.0
		var reduction_rate := 2.0 * GameManager.machine_efficiency_multiplier

		for machine in get_tree().get_nodes_in_group("machines"):
			if machine.has_method("get_efficiency"):
				total_efficiency += machine.get_efficiency()

		var pollution_reduction := total_efficiency * reduction_rate * delta
		var pollution_increase := base_increase_rate * GameManager.day_pollution_rate_multiplier * delta

		pollution = clampf(pollution + pollution_increase - pollution_reduction, 0.0, 100.0)

	if pollution >= over_limit_pollution_threshold:
		cumulative_minutes_over_threshold += delta * time_scale
		if cumulative_minutes_over_threshold >= lose_threshold_minutes:
			game_over.emit()

	pollution_changed.emit(pollution)


func _on_day_started() -> void:
	frozen_minutes_remaining = 0.0


func freeze_for_minutes(minutes: float) -> void:
	frozen_minutes_remaining += maxf(minutes, 0.0)


func reset_run(new_base_increase_rate: float, new_threshold: float, new_lose_threshold_minutes: float) -> void:
	base_increase_rate = new_base_increase_rate
	over_limit_pollution_threshold = new_threshold
	lose_threshold_minutes = new_lose_threshold_minutes
	pollution = 0.0
	cumulative_minutes_over_threshold = 0.0
	frozen_minutes_remaining = 0.0
	pollution_changed.emit(pollution)
