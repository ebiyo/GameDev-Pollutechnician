extends CanvasLayer

const TITLE_SCENE_PATH := "res://scenes/ui/menus/title_screen.tscn"

@onready var run_summary_label: Label = $CenterContainer/VBoxContainer/RunSummaryLabel
@onready var money_value_label: Label = $CenterContainer/VBoxContainer/StatsRow/MoneyCard/MarginContainer/VBoxContainer/ValueLabel
@onready var pollution_value_label: Label = $CenterContainer/VBoxContainer/StatsRow/PollutionCard/MarginContainer/VBoxContainer/ValueLabel
@onready var limit_value_label: Label = $CenterContainer/VBoxContainer/StatsRow/LimitCard/MarginContainer/VBoxContainer/ValueLabel
@onready var footer_label: Label = $CenterContainer/VBoxContainer/FooterLabel
@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_ui()
	restart_button.pressed.connect(_on_restart_button_pressed)


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)


func _refresh_ui() -> void:
	var latest_run := GameManager.get_latest_run_data(GameManager.current_difficulty)
	var money_left: int = int(latest_run.get("money", GameManager.money))
	var avg_pollution: float = float(latest_run.get("avg_pollution", PollutionManager.pollution))
	var days_recorded: int = int(latest_run.get("days_recorded", GameManager.current_day))
	var days_target: int = int(latest_run.get("days_target", GameManager.total_days))
	var over_limit_minutes: int = int(round(float(latest_run.get("over_limit_minutes", PollutionManager.cumulative_minutes_over_threshold))))
	var over_limit_limit_minutes: int = int(round(float(latest_run.get("over_limit_limit_minutes", PollutionManager.lose_threshold_minutes))))

	run_summary_label.text = "%s - %d / %d days survived" % [
		GameManager.difficulty_name,
		days_recorded,
		days_target
	]
	money_value_label.text = "$%d" % money_left
	pollution_value_label.text = "%.1f%%" % avg_pollution
	limit_value_label.text = "%d / %d" % [over_limit_minutes, over_limit_limit_minutes]
	footer_label.text = (
		"Over-limit pollution time exceeded the safe threshold."
		if over_limit_minutes >= over_limit_limit_minutes
		else "The city can still recover, but this run is over."
	)
