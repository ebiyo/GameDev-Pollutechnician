extends Node

signal event_triggered(event_name: String, event_desc: String)

const LOG_FADE_DURATION: float = 5.0

const EVENT_POOL: Array[Dictionary] = [
	{
		"name": "Building Fire",
		"desc": "A nearby fire spikes pollution.",
		"effect": "pollution_boost",
		"value": 5.0,
		"duration": 20.0
	},
	{
		"name": "Machine Surge",
		"desc": "One machine drains twice as fast.",
		"effect": "machine_surge",
		"duration": 24.0
	},
	{
		"name": "Clean Air",
		"desc": "A breeze clears the air.",
		"effect": "pollution_drop",
		"value": 10.0
	},
	{
		"name": "Power Flicker",
		"desc": "All machines lose efficiency briefly.",
		"effect": "efficiency_drop",
		"duration": 24.0
	}
]

@export var interval_min: float = 20.0
@export var interval_max: float = 40.0

var event_timer: float = 0.0
var active_effects: Dictionary = {}
var event_log_entries: Array[Dictionary] = []


func _ready() -> void:
	randomize()
	GameManager.day_started.connect(_on_day_started)
	GameManager.day_ended.connect(_on_day_ended)


func _process(delta: float) -> void:
	_process_event_log(delta)

	if GameManager.current_phase != GameManager.Phase.ACTIVE:
		return

	if GameManager.day_random_events_blocked:
		return

	event_timer -= delta
	if event_timer <= 0.0:
		_trigger_random_event()
		_reset_event_timer()

	var expired_effects: Array[String] = []
	var time_scale: float = _get_ingame_time_scale()
	for effect_name_variant in active_effects.keys():
		var effect_name: String = String(effect_name_variant)
		var effect_state: Dictionary = active_effects[effect_name]
		var remaining: float = float(effect_state.get("remaining", 0.0)) - (delta * time_scale)
		effect_state["remaining"] = remaining
		active_effects[effect_name] = effect_state

		if remaining <= 0.0:
			expired_effects.append(effect_name)

	for effect_name in expired_effects:
		_expire_effect(effect_name)


func _on_day_started() -> void:
	_clear_active_effects()
	event_log_entries.clear()
	_reset_event_timer()
	if GameManager.day_random_events_blocked:
		_add_instant_log_entry("Shield", "random events blocked today")


func _on_day_ended(_money_earned: int) -> void:
	_clear_active_effects()
	event_log_entries.clear()


func _reset_event_timer() -> void:
	event_timer = randf_range(GameManager.event_interval_min, GameManager.event_interval_max)


func _trigger_random_event() -> void:
	var available_events := _get_available_event_pool()
	if available_events.is_empty():
		return

	var event_data: Dictionary = available_events[randi() % available_events.size()]
	_apply_event(event_data)
	event_triggered.emit(String(event_data["name"]), String(event_data["desc"]))


func _apply_event(event_data: Dictionary) -> void:
	var effect_name: String = String(event_data["effect"])
	var duration: float = float(event_data.get("duration", 0.0))
	var value: float = float(event_data.get("value", 0.0))

	if active_effects.has(effect_name):
		_clear_effect(effect_name)

	match effect_name:
		"pollution_boost":
			PollutionManager.base_increase_rate += value
			active_effects[effect_name] = {
				"remaining": duration,
				"value": value
			}
			_set_timed_log_entry(effect_name, "Building Fire", "pollution rate +%.0f" % value)
			AudioManager.play_building_fire()
		"machine_surge":
			var machines: Array[Node] = get_tree().get_nodes_in_group("machines")
			if machines.is_empty():
				return

			var chosen_machine: Machine = machines[randi() % machines.size()] as Machine
			if chosen_machine == null:
				return

			var original_drain_rate: float = chosen_machine.drain_rate
			chosen_machine.drain_rate = original_drain_rate * 2.0
			active_effects[effect_name] = {
				"remaining": duration,
				"machine": chosen_machine,
				"original_drain_rate": original_drain_rate,
				"machine_name": chosen_machine.name
			}
			_set_timed_log_entry(effect_name, "Machine Surge", "drain x2", _format_machine_name(chosen_machine.name))
			AudioManager.play_machine_surge()
		"pollution_drop":
			PollutionManager.pollution = clampf(PollutionManager.pollution - value, 0.0, 100.0)
			PollutionManager.pollution_changed.emit(PollutionManager.pollution)
			_add_instant_log_entry("Clean Air", "reduces pollution by %.0f%%" % value)
			AudioManager.play_clean_air()
		"efficiency_drop":
			for machine_node in get_tree().get_nodes_in_group("machines"):
				var machine: Machine = machine_node as Machine
				if machine != null:
					machine.set_efficiency_penalised(true)
			active_effects[effect_name] = {
				"remaining": duration
			}
			_set_timed_log_entry(effect_name, "Power Flicker", "all machines at 50% efficiency")
			AudioManager.play_power_flicker()


func log_instant_effect(label: String, detail: String) -> void:
	_add_instant_log_entry(label, detail)


func track_custom_timed_effect(
	effect_name: String,
	label: String,
	detail: String,
	duration_minutes: float,
	color: Color = Color(0.65, 0.9, 1.0, 1.0)
) -> void:
	var remaining := maxf(duration_minutes, 0.0)

	if active_effects.has(effect_name):
		var effect_state: Dictionary = active_effects[effect_name]
		remaining += float(effect_state.get("remaining", 0.0))

	active_effects[effect_name] = {
		"remaining": remaining,
		"custom_only": true
	}
	_set_timed_log_entry(effect_name, label, detail)

	for entry in event_log_entries:
		if String(entry.get("effect_name", "")) == effect_name:
			entry["color"] = color
			return


func _expire_effect(effect_name: String) -> void:
	if !active_effects.has(effect_name):
		return

	var effect_state: Dictionary = active_effects[effect_name]
	_reverse_effect(effect_name, effect_state)
	active_effects.erase(effect_name)
	_mark_log_entry_resolved(effect_name)


func _clear_effect(effect_name: String) -> void:
	if !active_effects.has(effect_name):
		return

	var effect_state: Dictionary = active_effects[effect_name]
	_reverse_effect(effect_name, effect_state)
	active_effects.erase(effect_name)
	_remove_log_entry(effect_name)


func _clear_active_effects() -> void:
	var effect_names: Array[String] = []
	for effect_name_variant in active_effects.keys():
		effect_names.append(String(effect_name_variant))

	for effect_name in effect_names:
		_clear_effect(effect_name)


func _reverse_effect(effect_name: String, effect_state: Dictionary) -> void:
	match effect_name:
		"pollution_boost":
			var value: float = float(effect_state.get("value", 0.0))
			PollutionManager.base_increase_rate -= value
		"machine_surge":
			var machine_ref: Variant = effect_state.get("machine", null)
			if machine_ref != null and is_instance_valid(machine_ref):
				var surged_machine := machine_ref as Machine
				surged_machine.drain_rate = float(effect_state.get("original_drain_rate", surged_machine.drain_rate))
		"efficiency_drop":
			for machine_node in get_tree().get_nodes_in_group("machines"):
				var machine: Machine = machine_node as Machine
				if machine != null:
					machine.set_efficiency_penalised(false)
		_:
			pass


func get_event_log_entries() -> Array[Dictionary]:
	var rendered_entries: Array[Dictionary] = []

	for entry in event_log_entries:
		var entry_type: String = String(entry.get("type", ""))
		if entry_type == "timed":
			var effect_name: String = String(entry.get("effect_name", ""))
			if active_effects.has(effect_name):
				var effect_state: Dictionary = active_effects[effect_name]
				var remaining_minutes: int = maxi(1, int(ceil(float(effect_state.get("remaining", 0.0)))))
				var machine_name: String = String(entry.get("machine_name", ""))
				var label: String = String(entry.get("label", ""))
				var detail: String = String(entry.get("detail", ""))
				var text: String = ""

				if machine_name.is_empty():
					text = "%s (%s)\n(%dm left)" % [label, detail, remaining_minutes]
				else:
					text = "%s (%s, %s)\n(%dm left)" % [label, machine_name, detail, remaining_minutes]

				rendered_entries.append({
					"text": text,
					"alpha": 1.0,
					"color": entry.get("color", Color(1.0, 0.9, 0.35, 1.0))
				})
			elif bool(entry.get("resolved", false)):
				var resolved_machine_name: String = String(entry.get("machine_name", ""))
				var resolved_label: String = String(entry.get("label", ""))
				var resolved_detail: String = String(entry.get("detail", ""))
				var resolved_text: String = ""

				if resolved_machine_name.is_empty():
					resolved_text = "%s (%s)\n(0m left)" % [resolved_label, resolved_detail]
				else:
					resolved_text = "%s (%s, %s)\n(0m left)" % [
						resolved_label,
						resolved_machine_name,
						resolved_detail
					]

				rendered_entries.append({
					"text": resolved_text,
					"alpha": _get_log_alpha(float(entry.get("ttl", 0.0))),
					"color": entry.get("color", Color(1.0, 0.9, 0.35, 1.0))
				})
		else:
			rendered_entries.append({
				"text": "%s (%s)" % [String(entry.get("label", "")), String(entry.get("detail", ""))],
				"alpha": _get_log_alpha(float(entry.get("ttl", 0.0))),
				"color": entry.get("color", Color(0.45, 1.0, 0.55, 1.0))
			})

	return rendered_entries


func _process_event_log(delta: float) -> void:
	var remaining_entries: Array[Dictionary] = []
	for entry in event_log_entries:
		var entry_type: String = String(entry.get("type", ""))
		if entry_type == "instant":
			var ttl: float = float(entry.get("ttl", 0.0)) - delta
			if ttl > 0.0:
				entry["ttl"] = ttl
				remaining_entries.append(entry)
		elif entry_type == "timed" and bool(entry.get("resolved", false)):
			var resolved_ttl: float = float(entry.get("ttl", 0.0)) - delta
			if resolved_ttl > 0.0:
				entry["ttl"] = resolved_ttl
				remaining_entries.append(entry)
		else:
			remaining_entries.append(entry)

	event_log_entries = remaining_entries


func _add_instant_log_entry(label: String, detail: String) -> void:
	event_log_entries.append({
		"type": "instant",
		"label": label,
		"detail": detail,
		"ttl": LOG_FADE_DURATION,
		"color": Color(0.45, 1.0, 0.55, 1.0)
	})


func _get_ingame_time_scale() -> float:
	return PollutionManager.ingame_day_minutes / maxf(GameManager.day_duration, 0.001)


func _set_timed_log_entry(effect_name: String, label: String, detail: String, machine_name: String = "") -> void:
	_remove_log_entry(effect_name)
	event_log_entries.append({
		"type": "timed",
		"effect_name": effect_name,
		"label": label,
		"detail": detail,
		"machine_name": machine_name,
		"color": Color(1.0, 0.9, 0.35, 1.0)
	})


func _remove_log_entry(effect_name: String) -> void:
	var remaining_entries: Array[Dictionary] = []
	for entry in event_log_entries:
		if String(entry.get("effect_name", "")) != effect_name:
			remaining_entries.append(entry)
	event_log_entries = remaining_entries


func _mark_log_entry_resolved(effect_name: String) -> void:
	for entry in event_log_entries:
		if String(entry.get("effect_name", "")) != effect_name:
			continue

		entry["resolved"] = true
		entry["ttl"] = LOG_FADE_DURATION
		return


func _get_log_alpha(ttl: float) -> float:
	return clampf(ttl / LOG_FADE_DURATION, 0.0, 1.0)


func _format_machine_name(raw_name: String) -> String:
	var formatted := ""

	for index in raw_name.length():
		var character := raw_name[index]
		if index > 0 and character >= "A" and character <= "Z":
			formatted += " "
		formatted += character

	return formatted


func _get_available_event_pool() -> Array[Dictionary]:
	var available_events: Array[Dictionary] = []

	for event_data in EVENT_POOL:
		var effect_name: String = String(event_data.get("effect", ""))
		var is_good_event := effect_name == "pollution_drop"
		if is_good_event and !GameManager.good_events_enabled:
			continue

		available_events.append(event_data)

	return available_events


func reset_run() -> void:
	_clear_active_effects()
	event_log_entries.clear()
	event_timer = 0.0
