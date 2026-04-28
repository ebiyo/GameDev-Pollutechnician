extends CanvasLayer

@onready var title_label: Label = $TitleLabel
@onready var money_label: Label = $MoneyLabel
@onready var next_day_button: Button = $NextDayButton


func _ready() -> void:
	GameManager.day_ended.connect(_on_day_ended)
	next_day_button.pressed.connect(_on_next_day_button_pressed)


func _on_day_ended(money_earned: int) -> void:
	title_label.text = "%s - Day %d Complete" % [
		GameManager.difficulty_name,
		GameManager.current_day - 1
	]
	money_label.text = "Money Earned: %d" % money_earned


func _on_next_day_button_pressed() -> void:
	GameManager.start_next_day()
	visible = false
