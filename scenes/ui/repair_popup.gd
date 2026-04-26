class_name RepairPopup
extends CanvasLayer

signal popup_closed()


class TimingBarControl extends Control:
	var popup: RepairPopup


	func _draw() -> void:
		if popup != null:
			popup._draw_timing_bar(self)


@export var repair_amount: float = 18.0
@export var overclock_amount: float = 22.0

var machine: Machine
var needle_pos: float = 0.0
var needle_speed: float = 0.35
var needle_direction: float = 1.0
var timing_bar: Control

@onready var machine_label: Label = $Panel/VBoxContainer/MachineLabel
@onready var durability_bar: ProgressBar = $Panel/VBoxContainer/Bars/DurabilityBar
@onready var overclock_bar: ProgressBar = $Panel/VBoxContainer/Bars/OverclockBar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	timing_bar = _replace_timing_bar()
	hide()


func _process(delta: float) -> void:
	if !visible or !is_instance_valid(machine):
		return

	_update_needle(delta)
	_update_bars()
	timing_bar.queue_redraw()


func _input(event: InputEvent) -> void:
	if !visible or event is not InputEventKey:
		return

	var key_event := event as InputEventKey
	if !key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_E:
		close()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_SPACE:
		_handle_hit()
		get_viewport().set_input_as_handled()


func open(target_machine: Machine) -> void:
	machine = target_machine
	needle_pos = 0.0
	needle_speed = 0.35
	needle_direction = 1.0
	get_tree().paused = false
	show()
	machine.is_in_repair = true
	_update_bars()
	timing_bar.queue_redraw()


func close() -> void:
	popup_closed.emit()
	hide()
	if is_instance_valid(machine):
		machine.is_in_repair = false
	machine = null


func _replace_timing_bar() -> Control:
	var placeholder: Control = $Panel/VBoxContainer/TimingBar
	var replacement := TimingBarControl.new()

	replacement.name = "TimingBar"
	replacement.popup = self
	replacement.custom_minimum_size = placeholder.custom_minimum_size
	replacement.size_flags_horizontal = placeholder.size_flags_horizontal
	replacement.size_flags_vertical = placeholder.size_flags_vertical
	replacement.mouse_filter = Control.MOUSE_FILTER_IGNORE

	placeholder.replace_by(replacement)
	placeholder.queue_free()

	return replacement


func _update_needle(delta: float) -> void:
	needle_pos += needle_direction * needle_speed * delta

	if needle_pos >= 1.0:
		needle_pos = 1.0
		needle_direction = -1.0
	elif needle_pos <= 0.0:
		needle_pos = 0.0
		needle_direction = 1.0


func _handle_hit() -> void:
	if !is_instance_valid(machine):
		return

	var hit_zone_half := _get_hit_zone_size() * 0.5
	var zone_min := 0.5 - hit_zone_half
	var zone_max := 0.5 + hit_zone_half

	if needle_pos >= zone_min and needle_pos <= zone_max:
		if machine.durability < machine.max_durability:
			machine.durability = minf(machine.durability + repair_amount, machine.max_durability)
		else:
			machine.overclock = minf(machine.overclock + overclock_amount, machine.max_overclock)
		needle_speed = clampf(needle_speed + 0.07, 0.15, 0.9)
	else:
		needle_speed = clampf(needle_speed - 0.06, 0.15, 0.9)

	_update_bars()
	timing_bar.queue_redraw()


func _update_bars() -> void:
	if !is_instance_valid(machine):
		return

	machine_label.text = _format_machine_name(machine.name)
	durability_bar.value = machine.durability
	durability_bar.max_value = machine.max_durability
	overclock_bar.value = machine.overclock
	overclock_bar.max_value = machine.max_overclock
	overclock_bar.modulate = Color(1.0, 0.85, 0.2, 1.0) if machine.overclock >= machine.max_overclock else Color(0.35, 0.65, 1.0, 1.0)


func _get_hit_zone_size() -> float:
	if !is_instance_valid(machine):
		return 0.15

	if machine.durability >= machine.max_durability:
		return 0.15

	var fill_ratio := clampf(machine.durability / maxf(machine.max_durability, 0.001), 0.0, 1.0)
	return lerpf(0.35, 0.05, fill_ratio)


func _draw_timing_bar(target: Control) -> void:
	var bar_rect := Rect2(Vector2.ZERO, target.size)
	target.draw_rect(bar_rect, Color(0.15, 0.15, 0.15, 1.0), true)

	var hit_zone_width := _get_hit_zone_size() * target.size.x
	var hit_zone_left := (target.size.x - hit_zone_width) * 0.5
	var hit_zone_rect := Rect2(Vector2(hit_zone_left, 0.0), Vector2(hit_zone_width, target.size.y))
	target.draw_rect(hit_zone_rect, Color(0.2, 0.8, 0.3, 1.0), true)

	var needle_x := needle_pos * target.size.x
	target.draw_line(Vector2(needle_x, 0.0), Vector2(needle_x, target.size.y), Color(1.0, 0.2, 0.2, 1.0), 4.0)


func _format_machine_name(raw_name: String) -> String:
	var formatted := ""

	for index in raw_name.length():
		var character := raw_name[index]
		if index > 0 and character >= "A" and character <= "Z":
			formatted += " "
		formatted += character

	return formatted
