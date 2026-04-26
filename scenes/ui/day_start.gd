extends CanvasLayer

const RAIN_CARD_COST: int = 30
const REPAIR_KIT_COST: int = 50
const SPEED_BOOST_COST: int = 40
const REPAIR_EFFICIENCY_COST: int = 45
const REPAIR_EFFICIENCY_GAIN: float = 4.0

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var money_label: Label = $VBoxContainer/MoneyLabel
@onready var rain_card_button: Button = $VBoxContainer/RainCardButton
@onready var repair_kit_button: Button = $VBoxContainer/RepairKitButton
@onready var speed_boost_button: Button = $VBoxContainer/SpeedBoostButton
@onready var repair_efficiency_button: Button = $VBoxContainer/RepairEfficiencyButton
@onready var start_day_button: Button = $VBoxContainer/StartDayButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.day_ended.connect(_on_day_ended)
	rain_card_button.pressed.connect(_on_rain_card_button_pressed)
	repair_kit_button.pressed.connect(_on_repair_kit_button_pressed)
	speed_boost_button.pressed.connect(_on_speed_boost_button_pressed)
	repair_efficiency_button.pressed.connect(_on_repair_efficiency_button_pressed)
	start_day_button.pressed.connect(_on_start_day_button_pressed)
	hide()


func _on_day_ended(_money_earned: int) -> void:
	GameManager.current_phase = GameManager.Phase.PREP
	_reset_purchase_buttons()
	_update_labels()
	show()


func _on_rain_card_button_pressed() -> void:
	if !_can_buy_card(RAIN_CARD_COST):
		return

	if !GameManager.add_card(GameManager.RAIN_CARD_TYPE):
		return

	GameManager.money -= RAIN_CARD_COST
	rain_card_button.disabled = true
	_update_labels()
	_refresh_card_purchase_buttons()


func _on_repair_kit_button_pressed() -> void:
	if !_can_buy_card(REPAIR_KIT_COST):
		return

	if !GameManager.add_card(GameManager.REPAIR_KIT_CARD_TYPE):
		return

	GameManager.money -= REPAIR_KIT_COST
	repair_kit_button.disabled = true
	_update_labels()
	_refresh_card_purchase_buttons()


func _on_speed_boost_button_pressed() -> void:
	if !_can_afford(SPEED_BOOST_COST):
		return

	GameManager.money -= SPEED_BOOST_COST
	RepairManager.needle_speed = clampf(
		RepairManager.needle_speed + 0.15,
		RepairManager.MIN_SPEED,
		RepairManager.MAX_SPEED
	)
	speed_boost_button.disabled = true
	_update_labels()


func _on_repair_efficiency_button_pressed() -> void:
	if !_can_afford(REPAIR_EFFICIENCY_COST):
		return

	GameManager.money -= REPAIR_EFFICIENCY_COST
	GameManager.repair_efficiency_bonus += REPAIR_EFFICIENCY_GAIN
	repair_efficiency_button.disabled = true
	_update_labels()


func _on_start_day_button_pressed() -> void:
	hide()
	get_tree().paused = false
	GameManager.start_day()


func _can_afford(cost: int) -> bool:
	return GameManager.money >= cost


func _can_buy_card(cost: int) -> bool:
	return _can_afford(cost) and GameManager.get_total_cards() < GameManager.MAX_CARDS


func _update_labels() -> void:
	title_label.text = "Day %d — Prepare" % GameManager.current_day
	money_label.text = "Money: $%d   Repair: +%.1f/hit   Cards: %d/%d" % [
		GameManager.money,
		18.0 + GameManager.repair_efficiency_bonus,
		GameManager.get_total_cards(),
		GameManager.MAX_CARDS
	]


func _reset_purchase_buttons() -> void:
	rain_card_button.disabled = false
	repair_kit_button.disabled = false
	speed_boost_button.disabled = false
	repair_efficiency_button.disabled = false
	_refresh_card_purchase_buttons()


func _refresh_card_purchase_buttons() -> void:
	if GameManager.get_total_cards() >= GameManager.MAX_CARDS:
		rain_card_button.disabled = true
		repair_kit_button.disabled = true
