extends CanvasLayer

@onready var pollution_bar: ProgressBar = $PollutionBar
@onready var clock_face: ClockFace = $ClockFace
@onready var day_label: Label = $DayLabel
@onready var over_limit_label: Label = $OverLimitLabel

var urgency_tween: Tween


func _ready() -> void:
	PollutionManager.pollution_changed.connect(_on_pollution_changed)
	GameManager.day_started.connect(_on_day_started)
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.game_won.connect(_on_game_won)
	_on_pollution_changed(PollutionManager.pollution)
	_set_timer_visible(false)
	_update_day_label()
	_update_over_limit_label()


func _process(_delta: float) -> void:
	if GameManager.current_phase == GameManager.Phase.ACTIVE and clock_face.visible:
		clock_face.progress = clampf(GameManager.day_timer / maxf(GameManager.day_duration, 0.001), 0.0, 1.0)
		_update_urgency_pulse()
	_update_over_limit_label()


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
	clock_face.progress = clampf(GameManager.day_timer / maxf(GameManager.day_duration, 0.001), 0.0, 1.0)
	_update_urgency_pulse()


func _on_day_ended(_money_earned: int) -> void:
	_set_timer_visible(false)


func _on_game_won() -> void:
	_set_timer_visible(false)


func _set_timer_visible(is_visible: bool) -> void:
	clock_face.visible = is_visible
	day_label.visible = is_visible
	if !is_visible:
		over_limit_label.visible = false
	if !is_visible:
		_stop_urgency_pulse()


func _update_day_label() -> void:
	day_label.text = "Day %d / %d" % [GameManager.current_day, GameManager.total_days]


func _update_urgency_pulse() -> void:
	if GameManager.day_timer <= 15.0:
		if urgency_tween == null:
			urgency_tween = create_tween()
			urgency_tween.set_loops()
			urgency_tween.tween_property(clock_face, "modulate", Color(1.0, 0.35, 0.35, 1.0), 0.35)
			urgency_tween.tween_property(clock_face, "modulate", Color.WHITE, 0.35)
	else:
		_stop_urgency_pulse()


func _stop_urgency_pulse() -> void:
	if urgency_tween != null:
		urgency_tween.kill()
		urgency_tween = null
	clock_face.modulate = Color.WHITE


func _update_over_limit_label() -> void:
	if PollutionManager.pollution >= 100.0 and GameManager.current_phase == GameManager.Phase.ACTIVE:
		over_limit_label.visible = true
		over_limit_label.text = "Over limit: %.1f / %.1f min" % [
			PollutionManager.ingame_minutes_over,
			PollutionManager.lose_threshold_minutes
		]
	else:
		over_limit_label.visible = false
