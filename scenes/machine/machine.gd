class_name Machine
extends StaticBody2D

signal durability_changed(value: float)
signal repair_requested(machine: Machine)

@export var max_durability: float = 100.0
@export var drain_rate: float = 3.0
@export var overclock_drain_rate: float = 8.0

var durability: float = max_durability
var overclock: float = 0.0
var max_overclock: float = 100.0
var is_player_nearby: bool = false
var is_in_repair: bool = false
var is_efficiency_penalised: bool = false
var _last_durability: float = max_durability
var _last_overclock: float = 0.0

@onready var repair_zone: Area2D = $RepairZone
@onready var durability_bar: ProgressBar = $StatusBars/DurabilityBar
@onready var overclock_bar: ProgressBar = $StatusBars/OverclockBar
@onready var interact_label: Label = $InteractLabel
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
	_update_interact_prompt()


func _process(delta: float) -> void:
	if !is_in_repair:
		durability = maxf(
			durability - (drain_rate * GameManager.machine_drain_multiplier * delta),
			0.0
		)

	if overclock > 0.0:
		var overclock_drain_multiplier: float = 0.35 if is_in_repair else 1.0
		overclock = maxf(overclock - overclock_drain_rate * overclock_drain_multiplier * delta, 0.0)

	if !is_equal_approx(durability, _last_durability):
		durability_changed.emit(durability)
	elif !is_equal_approx(overclock, _last_overclock):
		_update_status_display()

	_update_interact_prompt()

	_last_durability = durability
	_last_overclock = overclock


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return

	var key_event := event as InputEventKey
	if !key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_E and is_player_nearby:
		repair_requested.emit(self)
		get_viewport().set_input_as_handled()


func _on_repair_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		_update_interact_prompt()


func _on_repair_zone_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		_update_interact_prompt()


func _on_durability_changed(value: float) -> void:
	_update_status_display()


func get_efficiency() -> float:
	if is_zero_approx(max_durability):
		return 0.0

	var efficiency: float = durability / max_durability
	if overclock > 0.0:
		efficiency = clampf(
			efficiency + GameManager.overclock_efficiency_bonus,
			0.0,
			1.0 + GameManager.overclock_efficiency_bonus
		)

	if is_efficiency_penalised:
		efficiency *= 0.5

	return efficiency


func _update_status_display() -> void:
	durability_bar.value = durability
	overclock_bar.value = overclock
	body_visual.modulate = Color.RED if durability < 20.0 else Color.WHITE


func _update_interact_prompt() -> void:
	interact_label.visible = is_player_nearby and !is_in_repair
