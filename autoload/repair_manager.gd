extends Node

const MIN_SPEED: float = 0.20
const MAX_SPEED: float = 1.4

var needle_speed: float = 0.35


func speed_up() -> void:
	needle_speed = clampf(needle_speed + 0.08, MIN_SPEED, MAX_SPEED)


func slow_down() -> void:
	needle_speed = clampf(needle_speed - 0.08, MIN_SPEED, MAX_SPEED)


func reset_run() -> void:
	needle_speed = 0.35
