class_name ClockFace
extends Control

@export var radius: float = 40.0

var progress: float = 1.0


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var draw_radius := minf(radius, minf(size.x, size.y) * 0.5)
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var start_angle := -PI * 0.5
	var end_angle := start_angle + clamped_progress * TAU

	draw_circle(center, draw_radius, Color(0.12, 0.12, 0.14, 1.0))

	if clamped_progress > 0.0:
		var wedge_points := PackedVector2Array()
		var steps := maxi(6, int(clamped_progress * 64.0))

		wedge_points.append(center)
		for step in range(steps + 1):
			var t := float(step) / float(steps)
			var angle := lerpf(start_angle, end_angle, t)
			var point := center + Vector2(cos(angle), sin(angle)) * draw_radius
			wedge_points.append(point)
		draw_colored_polygon(wedge_points, Color(0.95, 0.72, 0.2, 1.0))

	var hand_angle := end_angle
	var hand_end := center + Vector2(cos(hand_angle), sin(hand_angle)) * (draw_radius - 4.0)
	draw_line(center, hand_end, Color.WHITE, 2.0)
	draw_circle(center, 4.0, Color.WHITE)
