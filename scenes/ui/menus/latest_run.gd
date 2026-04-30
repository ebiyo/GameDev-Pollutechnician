extends CanvasLayer

const TITLE_SCENE_PATH := "res://scenes/ui/menus/title_screen.tscn"

@onready var easy_label: Label = $Center/Content/CardsRow/EasyCard/VBoxContainer/Margin/Body
@onready var normal_label: Label = $Center/Content/CardsRow/NormalCard/VBoxContainer/Margin/Body
@onready var hard_label: Label = $Center/Content/CardsRow/HardCard/VBoxContainer/Margin/Body
@onready var back_button: Button = $Center/Content/BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.pressed.connect(_on_back_button_pressed)
	easy_label.text = _build_latest_run_details(GameManager.Difficulty.EASY)
	normal_label.text = _build_latest_run_details(GameManager.Difficulty.NORMAL)
	hard_label.text = _build_latest_run_details(GameManager.Difficulty.HARD)


func _on_back_button_pressed() -> void:
	get_tree().paused = false
	SceneTransition.change_scene_to_file(TITLE_SCENE_PATH)


func _build_latest_run_details(difficulty: int) -> String:
	var latest_run := GameManager.get_latest_run_data(difficulty)

	if latest_run.is_empty():
		return "Result: -\nDays Survived: -\nAvg Pollution/Day: -\nMoney Left: -\nMoney Spent: -\nBonus Money Earned: -\nOver limit: -\nCards Purchased: -\nUpgrades Purchased: -\nDay Effects Purchased: -"

	return "Result: %s\nDays Survived: %d/%d\nAvg Pollution/Day: %s\nMoney Left: $%d\nMoney Spent: $%d\nBonus Money Earned: $%d\nOver limit: %s/%s min\nCards Purchased: %s\nUpgrades Purchased: %s\nDay Effects Purchased: %s" % [
		"Win" if bool(latest_run.get("won", false)) else "Loss",
		int(latest_run.get("days_recorded", 0)),
		int(latest_run.get("days_target", 0)),
		_format_percentage(float(latest_run.get("avg_pollution", 0.0))),
		int(latest_run.get("money", 0)),
		int(latest_run.get("money_spent", 0)),
		int(latest_run.get("bonus_money_earned", 0)),
		str(int(round(float(latest_run.get("over_limit_minutes", 0.0))))),
		str(int(round(float(latest_run.get("over_limit_limit_minutes", 0.0))))),
		_format_purchase_group(latest_run.get("cards_purchased", {})),
		_format_purchase_group(latest_run.get("upgrades_purchased", {})),
		_format_purchase_group(latest_run.get("day_effects_purchased", {}))
	]


func _format_percentage(value: float) -> String:
	return ("%.2f%%" % value).replace(".", ",")


func _format_purchase_group(data: Variant) -> String:
	if !(data is Dictionary):
		return "-"

	var purchase_data := data as Dictionary
	if purchase_data.is_empty():
		return "-"

	var names: PackedStringArray = []
	for key_variant in purchase_data.keys():
		names.append(String(key_variant))
	names.sort()

	var parts: PackedStringArray = []
	for purchase_name in names:
		parts.append("%s x%d" % [purchase_name, int(purchase_data.get(purchase_name, 0))])

	return ", ".join(parts)
