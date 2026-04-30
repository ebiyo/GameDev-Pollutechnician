extends CanvasLayer

signal next_day_requested()

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var summary_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SummaryLabel
@onready var money_earned_value: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/EarnedRow/ValueLabel
@onready var bonus_value: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/BonusRow/ValueLabel
@onready var pollution_value: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/PollutionRow/ValueLabel
@onready var bonus_hint_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BonusHintLabel
@onready var next_day_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NextDayButton


func _ready() -> void:
	GameManager.day_ended.connect(_on_day_ended)
	next_day_button.pressed.connect(_on_next_day_button_pressed)


func _on_day_ended(money_earned: int) -> void:
	var summary := GameManager.get_last_day_summary()
	var completed_day: int = int(summary.get("completed_day", GameManager.current_day - 1))
	var base_reward: int = int(summary.get("base_reward", money_earned))
	var bonus_reward: int = int(summary.get("bonus_reward", 0))
	var ended_pollution: float = float(summary.get("ended_pollution", PollutionManager.pollution))
	var bonus_threshold: float = float(summary.get("bonus_threshold", GameManager.low_pollution_bonus_threshold))
	var qualified_for_bonus: bool = bool(summary.get("qualified_for_bonus", false))

	title_label.text = "%s - Day %d Complete" % [
		GameManager.difficulty_name,
		completed_day
	]
	summary_label.text = "Base pay: $%d" % base_reward
	money_earned_value.text = "$%d" % money_earned
	bonus_value.text = "+$%d" % bonus_reward
	pollution_value.text = "%.1f" % ended_pollution
	if qualified_for_bonus:
		bonus_hint_label.text = "Low pollution bonus earned for finishing below %.0f pollution." % bonus_threshold
	else:
		bonus_hint_label.text = "No low pollution bonus. Finish below %.0f% pollution to earn a bonus." % bonus_threshold
	show()


func _on_next_day_button_pressed() -> void:
	visible = false
	next_day_requested.emit()
