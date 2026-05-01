class_name RepairPopup
extends CanvasLayer

signal popup_closed()


class TimingBarControl extends Control:
	var popup: RepairPopup


	func _draw() -> void:
		if popup != null:
			popup._draw_timing_bar(self)

@export var overclock_amount: float = 20.0

var current_machine: Machine = null
var needle_pos: float = 0.0
var needle_dir: float = 1.0
var hit_zone_center: float = 0.5
var timing_bar: Control
var _durability_flash_tween: Tween = null
var _speed_adjust_timer: float = 0.0
var _durability_bar_base_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)

const SPEED_ADJUST_INTERVAL: float = 0.08

@onready var machine_label: Label = $Panel/MarginContainer/VBoxContainer/MachineLabel
@onready var speed_label: Label = $Panel/MarginContainer/VBoxContainer/SpeedLabel
@onready var durability_bar: ProgressBar = $Panel/MarginContainer/VBoxContainer/Bars/DurabilityRow/DurabilityBar
@onready var overclock_bar: ProgressBar = $Panel/MarginContainer/VBoxContainer/Bars/OverclockRow/OverclockBar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_durability_bar_base_modulate = durability_bar.modulate
	timing_bar = _replace_timing_bar()
	hide()


func _process(delta: float) -> void:
	if !visible or !is_instance_valid(current_machine):
		return

	_handle_speed_adjust_input(delta)
	needle_pos += needle_dir * RepairManager.needle_speed * delta

	if needle_pos >= 1.0 or needle_pos <= 0.0:
		needle_dir *= -1.0
		needle_pos = clampf(needle_pos, 0.0, 1.0)

	_sync_bars()
	timing_bar.queue_redraw()


func _input(event: InputEvent) -> void:
	if !visible or !is_instance_valid(current_machine) or event is not InputEventKey:
		return

	var key_event := event as InputEventKey
	if !key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_SPACE:
			_handle_space_press()
			get_viewport().set_input_as_handled()
		KEY_R:
			RepairManager.speed_up()
			get_viewport().set_input_as_handled()
		KEY_Q:
			RepairManager.slow_down()
			get_viewport().set_input_as_handled()
		KEY_E:
			close()
			get_viewport().set_input_as_handled()


func open(machine: Machine) -> void:
	AudioManager.play_repair_popup()
	current_machine = machine
	current_machine.is_in_repair = true
	needle_pos = 0.0
	needle_dir = 1.0
	_speed_adjust_timer = 0.0
	durability_bar.modulate = _durability_bar_base_modulate
	_randomize_hit_zone()
	_sync_bars()
	show()
	timing_bar.queue_redraw()


func close(play_sound: bool = true) -> void:
	if play_sound:
		AudioManager.play_close()
	popup_closed.emit()
	hide()
	if is_instance_valid(current_machine):
		current_machine.is_in_repair = false
	current_machine = null


func _handle_space_press() -> void:
	var hit := absf(needle_pos - hit_zone_center) <= _get_hit_zone_size() * 0.5

	if hit:
		if current_machine.durability < current_machine.max_durability:
			current_machine.durability = minf(
				current_machine.durability + _get_repair_amount(),
				current_machine.max_durability
			)
		else:
			current_machine.overclock = minf(current_machine.overclock + overclock_amount, current_machine.max_overclock)
		AudioManager.play_random_repair_success()
	else:
		current_machine.durability = maxf(
			current_machine.durability - GameManager.repair_miss_penalty,
			0.0
		)
		AudioManager.play_repair_fail()
		_flash_durability_bar()

	_randomize_hit_zone()
	_sync_bars()
	timing_bar.queue_redraw()


func _sync_bars() -> void:
	if !is_instance_valid(current_machine):
		return

	machine_label.text = _format_machine_name(current_machine.name)
	speed_label.text = "Needle Speed: %.2f   Repair: +%.1f" % [RepairManager.needle_speed, _get_repair_amount()]
	durability_bar.max_value = current_machine.max_durability
	durability_bar.value = current_machine.durability
	overclock_bar.max_value = current_machine.max_overclock
	overclock_bar.value = current_machine.overclock


func _get_repair_amount() -> float:
	return GameManager.get_current_repair_amount()


func _handle_speed_adjust_input(delta: float) -> void:
	var direction: int = 0
	if Input.is_key_pressed(KEY_R):
		direction += 1
	if Input.is_key_pressed(KEY_Q):
		direction -= 1

	if direction == 0:
		_speed_adjust_timer = 0.0
		return

	_speed_adjust_timer += delta
	while _speed_adjust_timer >= SPEED_ADJUST_INTERVAL:
		_speed_adjust_timer -= SPEED_ADJUST_INTERVAL
		if direction > 0:
			RepairManager.speed_up()
		else:
			RepairManager.slow_down()


func _get_hit_zone_size() -> float:
	if !is_instance_valid(current_machine):
		return 0.15

	if current_machine.durability < current_machine.max_durability:
		var fill_ratio := clampf(current_machine.durability / maxf(current_machine.max_durability, 0.001), 0.0, 1.0)
		return lerpf(0.35, 0.09, fill_ratio)

	return 0.15


func _replace_timing_bar() -> Control:
	var placeholder: Control = $Panel/MarginContainer/VBoxContainer/TimingArea/TimingBar
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


func _randomize_hit_zone() -> void:
	hit_zone_center = randf_range(0.1, 0.9)


func _flash_durability_bar() -> void:
	if _durability_flash_tween != null and _durability_flash_tween.is_valid():
		_durability_flash_tween.kill()

	durability_bar.modulate = Color(1.0, 0.35, 0.35, 1.0)
	_durability_flash_tween = create_tween()
	_durability_flash_tween.tween_property(durability_bar, "modulate", _durability_bar_base_modulate, 0.18)


func _draw_timing_bar(target: Control) -> void:
	var bar_rect := Rect2(Vector2.ZERO, target.size)
	target.draw_rect(bar_rect, Color(0.15, 0.15, 0.15, 1.0), true)

	var hit_zone_size := _get_hit_zone_size()
	var zone_left := (hit_zone_center - hit_zone_size * 0.5) * target.size.x
	var zone_width := hit_zone_size * target.size.x
	var zone_rect := Rect2(Vector2(zone_left, 0.0), Vector2(zone_width, target.size.y))
	target.draw_rect(zone_rect, Color(0.2, 0.94902, 0.45098, 1.0), true)

	var needle_x := needle_pos * target.size.x
	target.draw_line(Vector2(needle_x, 0.0), Vector2(needle_x, target.size.y), Color(1.0, 0.2, 0.2, 1.0), 5.0)


func _format_machine_name(raw_name: String) -> String:
	var formatted := ""

	for index in raw_name.length():
		var character := raw_name[index]
		if index > 0 and character >= "A" and character <= "Z":
			formatted += " "
		formatted += character

	return formatted
