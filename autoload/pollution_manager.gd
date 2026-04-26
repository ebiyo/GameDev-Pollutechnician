extends Node

signal pollution_changed(value: float)
signal game_over()

var pollution: float = 0.0
var base_increase_rate: float = 3.0
var over_threshold_timer: float = 0.0
var over_threshold_limit: float = 5.0


func _ready() -> void:
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

	if pollution >= 100.0:
		over_threshold_timer += delta
		if over_threshold_timer > over_threshold_limit:
			game_over.emit()
	else:
		over_threshold_timer = 0.0
