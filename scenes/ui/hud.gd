extends CanvasLayer

@onready var pollution_bar: ProgressBar = $PollutionBar
@onready var timer_label: Label = $TimerLabel


func _ready() -> void:
	PollutionManager.pollution_changed.connect(_on_pollution_changed)
	GameManager.day_started.connect(_on_day_started)
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.game_won.connect(_on_game_won)
	_on_pollution_changed(PollutionManager.pollution)
	timer_label.visible = false


func _process(_delta: float) -> void:
	if GameManager.current_phase == GameManager.Phase.ACTIVE and timer_label.visible:
		timer_label.text = str(ceili(GameManager.day_timer))


func _on_pollution_changed(value: float) -> void:
	pollution_bar.value = value

	if value < 50.0:
		pollution_bar.modulate = Color(0.35, 1.0, 0.35, 1.0)
	elif value < 80.0:
		pollution_bar.modulate = Color(1.0, 0.9, 0.25, 1.0)
	else:
		pollution_bar.modulate = Color(1.0, 0.35, 0.35, 1.0)


func _on_day_started() -> void:
	timer_label.visible = true
	timer_label.text = str(ceili(GameManager.day_timer))


func _on_day_ended(_money_earned: int) -> void:
	timer_label.visible = false


func _on_game_won() -> void:
	timer_label.visible = false
