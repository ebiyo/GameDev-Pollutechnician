class_name Machine
extends StaticBody2D

signal durability_changed(value: float)

@export var max_durability: float = 100.0
@export var drain_rate: float = 5.0
@export var overclock_drain_rate: float = 8.0

var durability: float = max_durability
var overclock: float = 0.0
var max_overclock: float = 100.0
var is_player_nearby: bool = false
var is_in_repair: bool = false
var _last_durability: float = max_durability
var _last_overclock: float = 0.0

@onready var repair_zone: Area2D = $RepairZone
@onready var durability_bar: ProgressBar = $StatusBars/DurabilityBar
@onready var overclock_bar: ProgressBar = $StatusBars/OverclockBar
@onready var body_visual: ColorRect = $Body


func _ready() -> void:
	durability = max_durability
	overclock = 0.0
	add_to_group("machines")
	repair_zone.body_entered.connect(_on_repair_zone_body_entered)
	repair_zone.body_exited.connect(_on_repair_zone_body_exited)
	durability_changed.connect(_on_durability_changed)
	durability_bar.min_value = 0.0
	durability_bar.max_value = max_durability
	overclock_bar.min_value = 0.0
	overclock_bar.max_value = max_overclock
	_last_durability = durability
	_last_overclock = overclock
	_update_status_display()


func _process(delta: float) -> void:
	if !is_in_repair:
		durability = maxf(durability - drain_rate * delta, 0.0)

	if overclock > 0.0:
		overclock = maxf(overclock - overclock_drain_rate * delta, 0.0)

	if !is_equal_approx(durability, _last_durability):
		durability_changed.emit(durability)
	elif !is_equal_approx(overclock, _last_overclock):
		_update_status_display()

	_last_durability = durability
	_last_overclock = overclock


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return

	var key_event := event as InputEventKey
	if !key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_E and is_player_nearby and !is_in_repair:
		var main := get_node_or_null("/root/Main")
		if main != null and main.has_method("open_repair_popup"):
			main.open_repair_popup(self)
			get_viewport().set_input_as_handled()


func _on_repair_zone_body_entered(body: Node) -> void:
	if body.name == "Player":
		is_player_nearby = true


func _on_repair_zone_body_exited(body: Node) -> void:
	if body.name == "Player":
		is_player_nearby = false


func _on_durability_changed(value: float) -> void:
	_update_status_display()


func get_efficiency() -> float:
	if is_zero_approx(max_durability):
		return 0.0

	var base := durability / max_durability
	if overclock > 0.0:
		return clampf(base + 0.4, 0.0, 1.4)

	return base


func _update_status_display() -> void:
	durability_bar.value = durability
	overclock_bar.value = overclock
	body_visual.modulate = Color.RED if durability < 20.0 else Color.WHITE
