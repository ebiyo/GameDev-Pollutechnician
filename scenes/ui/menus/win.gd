extends CanvasLayer

const TITLE_SCENE_PATH := "res://scenes/ui/menus/title_screen.tscn"

@onready var run_summary_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RunSummaryLabel
@onready var money_value_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsRow/MoneyCard/MarginContainer/VBoxContainer/ValueLabel
@onready var bonus_value_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsRow/BonusCard/MarginContainer/VBoxContainer/ValueLabel
@onready var pollution_value_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsRow/PollutionCard/MarginContainer/VBoxContainer/ValueLabel
@onready var footer_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FooterLabel
@onready var play_again_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayAgainButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.game_won.connect(_on_game_won)
	play_again_button.pressed.connect(_on_play_again_button_pressed)


func _on_play_again_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)


func _on_game_won() -> void:
	call_deferred("_refresh_ui")


func _refresh_ui() -> void:
	var latest_run := GameManager.get_latest_run_data(GameManager.current_difficulty)
	var money_left: int = int(latest_run.get("money", GameManager.money))
	var bonus_money: int = int(latest_run.get("bonus_money_earned", 0))
	var avg_pollution: float = float(latest_run.get("avg_pollution", PollutionManager.pollution))
	var days_recorded: int = int(latest_run.get("days_recorded", GameManager.total_days))
	var days_target: int = int(latest_run.get("days_target", GameManager.total_days))
	var over_limit_minutes: int = int(round(float(latest_run.get("over_limit_minutes", PollutionManager.cumulative_minutes_over_threshold))))
	var over_limit_limit_minutes: int = int(round(float(latest_run.get("over_limit_limit_minutes", PollutionManager.lose_threshold_minutes))))

	run_summary_label.text = "%s - %d / %d days survived" % [
		GameManager.difficulty_name,
		days_recorded,
		days_target
	]
	money_value_label.text = "$%d" % money_left
	bonus_value_label.text = "$%d" % bonus_money
	pollution_value_label.text = "%.1f%%" % avg_pollution
	footer_label.text = "Over limit time carried: %d / %d min" % [
		over_limit_minutes,
		over_limit_limit_minutes
	]
