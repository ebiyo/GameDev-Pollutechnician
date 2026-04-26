extends Node

signal pollution_changed(value: float)
signal game_over()

var pollution: float = 0.0
var base_increase_rate: float = 3.0
var ingame_minutes_over: float = 0.0

@export var lose_threshold_minutes: float = 2.0
@export var ingame_day_minutes: float = 60.0


func _ready() -> void:
	GameManager.day_started.connect(_on_day_started)
	pollution_changed.emit(pollution)


func _process(delta: float) -> void:
	var total_efficiency := 0.0
	var reduction_rate := 2.0

	for machine in get_tree().get_nodes_in_group("machines"):
		if machine.has_method("get_efficiency"):
			total_efficiency += machine.get_efficiency()

	var pollution_reduction := total_efficiency * reduction_rate * delta
	var pollution_increase := base_increase_rate * delta

	pollution = clampf(pollution + pollution_increase - pollution_reduction, 0.0, 100.0)
	pollution_changed.emit(pollution)

	if GameManager.current_phase != GameManager.Phase.ACTIVE:
		return

	var time_scale := ingame_day_minutes / maxf(GameManager.day_duration, 0.001)
	if pollution >= 100.0:
		ingame_minutes_over += delta * time_scale
		if ingame_minutes_over >= lose_threshold_minutes:
			game_over.emit()
	else:
		ingame_minutes_over = 0.0


func _on_day_started() -> void:
	ingame_minutes_over = 0.0
