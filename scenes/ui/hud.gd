extends CanvasLayer

const INGAME_TOTAL_MINUTES: float = 600.0

@onready var pollution_bar: ProgressBar = $PollutionBar
@onready var time_label: Label = $TimeLabel
@onready var day_label: Label = $DayLabel
@onready var over_threshold_label: Label = $OverThresholdLabel

var urgency_tween: Tween


func _ready() -> void:
	PollutionManager.pollution_changed.connect(_on_pollution_changed)
	GameManager.day_started.connect(_on_day_started)
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.game_won.connect(_on_game_won)
	_on_pollution_changed(PollutionManager.pollution)
	_set_timer_visible(false)
	_update_day_label()
	_update_time_label()
	_update_over_threshold_label()


func _process(_delta: float) -> void:
	if GameManager.current_phase == GameManager.Phase.ACTIVE and time_label.visible:
		_update_time_label()
		_update_urgency_pulse()
	_update_over_threshold_label()


func _on_pollution_changed(value: float) -> void:
	pollution_bar.value = value

	if value < 50.0:
		pollution_bar.modulate = Color(0.35, 1.0, 0.35, 1.0)
	elif value < 80.0:
		pollution_bar.modulate = Color(1.0, 0.9, 0.25, 1.0)
	else:
		pollution_bar.modulate = Color(1.0, 0.35, 0.35, 1.0)


func _on_day_started() -> void:
	_set_timer_visible(true)
	_update_day_label()
	_update_time_label()
	_update_urgency_pulse()


func _on_day_ended(_money_earned: int) -> void:
	_set_timer_visible(false)


func _on_game_won() -> void:
	_set_timer_visible(false)


func _set_timer_visible(is_visible: bool) -> void:
	time_label.visible = is_visible
	day_label.visible = is_visible
	if !is_visible:
		_stop_urgency_pulse()
		over_threshold_label.visible = false


func _update_day_label() -> void:
	day_label.text = "Day %d / %d" % [GameManager.current_day, GameManager.total_days]


func _update_time_label() -> void:
	var elapsed_fraction := 1.0 - (GameManager.day_timer / maxf(GameManager.day_duration, 0.001))
	var elapsed_minutes := elapsed_fraction * INGAME_TOTAL_MINUTES
	var total_minutes := int(elapsed_minutes)
	var hour := 8 + total_minutes / 60
	var minute := total_minutes % 60
	time_label.text = "%02d:%02d" % [hour, minute]


func _update_urgency_pulse() -> void:
	if GameManager.day_timer <= 15.0:
		if urgency_tween == null:
			urgency_tween = create_tween()
			urgency_tween.set_loops()
			urgency_tween.tween_property(time_label, "modulate", Color(1.0, 0.35, 0.35, 1.0), 0.3)
			urgency_tween.tween_property(time_label, "modulate", Color.WHITE, 0.3)
	else:
		_stop_urgency_pulse()


func _stop_urgency_pulse() -> void:
	if urgency_tween != null:
		urgency_tween.kill()
		urgency_tween = null
	time_label.modulate = Color.WHITE


func _update_over_threshold_label() -> void:
	if PollutionManager.pollution >= 100.0 and GameManager.current_phase == GameManager.Phase.ACTIVE:
		over_threshold_label.visible = true
		over_threshold_label.text = "Over limit: %.1f / %.1f min" % [
			PollutionManager.ingame_minutes_over,
			PollutionManager.lose_threshold_minutes
		]
	else:
		over_threshold_label.visible = false
