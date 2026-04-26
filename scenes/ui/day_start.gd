extends CanvasLayer

const OFFER_COUNT: int = 3
const RAIN_CARD_COST: int = 30
const REPAIR_KIT_CARD_COST: int = 50
const FREEZE_CARD_COST: int = 45
const SPEED_BOOST_COST: int = 40
const REPAIR_EFFICIENCY_COST: int = 45
const CAR_FREE_DAY_COST: int = 35
const SHIELD_COST: int = 55
const FLASH_COST: int = 80
const SPEED_BOOST_AMOUNT: float = 0.15
const REPAIR_EFFICIENCY_GAIN: float = 4.0
const FLASH_SPEED_MULTIPLIER: float = 2.0

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var money_label: Label = $VBoxContainer/MoneyLabel
@onready var offer_button_1: Button = $VBoxContainer/OfferButton1
@onready var offer_button_2: Button = $VBoxContainer/OfferButton2
@onready var offer_button_3: Button = $VBoxContainer/OfferButton3
@onready var start_day_button: Button = $VBoxContainer/StartDayButton

var _offer_buttons: Array[Button] = []
var _current_offers: Array[Dictionary] = []
var _purchased_offer_ids: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.day_ended.connect(_on_day_ended)
	_offer_buttons = [offer_button_1, offer_button_2, offer_button_3]

	for index in range(_offer_buttons.size()):
		_offer_buttons[index].pressed.connect(_on_offer_button_pressed.bind(index))

	start_day_button.pressed.connect(_on_start_day_button_pressed)
	hide()


func _on_day_ended(_money_earned: int) -> void:
	GameManager.current_phase = GameManager.Phase.PREP
	_roll_daily_offers()
	_update_labels()
	_refresh_offer_buttons()
	show()


func _on_offer_button_pressed(index: int) -> void:
	if index < 0 or index >= _current_offers.size():
		return

	var offer: Dictionary = _current_offers[index]
	if !_can_buy_offer(offer):
		return

	if !_purchase_offer(offer):
		return

	_purchased_offer_ids[String(offer.get("id", ""))] = true
	_update_labels()
	_refresh_offer_buttons()


func _on_start_day_button_pressed() -> void:
	hide()
	get_tree().paused = false
	GameManager.start_day()


func _roll_daily_offers() -> void:
	var eligible_offers := _get_offer_pool()
	eligible_offers.shuffle()
	_current_offers.clear()
	_purchased_offer_ids.clear()

	for index in range(mini(OFFER_COUNT, eligible_offers.size())):
		_current_offers.append(eligible_offers[index])


func _get_offer_pool() -> Array[Dictionary]:
	var offers: Array[Dictionary] = [
		_make_offer(
			"rain_card",
			"Card",
			"Rain Card",
			RAIN_CARD_COST,
			"Add 1 card (-15 pollution when used)."
		),
		_make_offer(
			"repair_kit_card",
			"Card",
			"Repair Kit Card",
			REPAIR_KIT_CARD_COST,
			"Add 1 card (repair all machines when used)."
		),
		_make_offer(
			"freeze_card",
			"Card",
			"Freeze Card",
			FREEZE_CARD_COST,
			"Add 1 card (freeze pollution for 60 in-game minutes)."
		),
		_make_offer(
			"speed_boost",
			"Upgrade",
			"Speed Boost",
			SPEED_BOOST_COST,
			"+0.15 to repair needle speed permanently."
		),
		_make_offer(
			"repair_efficiency",
			"Upgrade",
			"Repair Efficiency",
			REPAIR_EFFICIENCY_COST,
			"+4 repair per hit permanently."
		),
		_make_offer(
			"car_free_day",
			"Next Day",
			"Car Free Day",
			CAR_FREE_DAY_COST,
			"Tomorrow has a lower pollution rate."
		),
		_make_offer(
			"shield_day",
			"Next Day",
			"Shield",
			SHIELD_COST,
			"Tomorrow has no random events."
		)
	]

	if !GameManager.has_flash_upgrade:
		offers.append(_make_offer(
			"flash",
			"Upgrade",
			"The Flash",
			FLASH_COST,
			"Gain 2x walking speed permanently."
		))

	if GameManager.get_total_cards() >= GameManager.max_cards:
		var filtered_offers: Array[Dictionary] = []
		for offer in offers:
			if String(offer.get("group", "")) != "Card":
				filtered_offers.append(offer)
		return filtered_offers

	return offers


func _make_offer(id: String, group: String, name: String, cost: int, description: String) -> Dictionary:
	return {
		"id": id,
		"group": group,
		"name": name,
		"cost": cost,
		"description": description
	}


func _purchase_offer(offer: Dictionary) -> bool:
	var offer_id: String = String(offer.get("id", ""))
	var cost: int = int(offer.get("cost", 0))

	if GameManager.money < cost:
		return false

	match offer_id:
		"rain_card":
			if !GameManager.add_card(GameManager.RAIN_CARD_TYPE):
				return false
		"repair_kit_card":
			if !GameManager.add_card(GameManager.REPAIR_KIT_CARD_TYPE):
				return false
		"freeze_card":
			if !GameManager.add_card(GameManager.FREEZE_CARD_TYPE):
				return false
		"speed_boost":
			RepairManager.needle_speed = clampf(
				RepairManager.needle_speed + SPEED_BOOST_AMOUNT,
				RepairManager.MIN_SPEED,
				RepairManager.MAX_SPEED
			)
		"repair_efficiency":
			GameManager.repair_efficiency_bonus += REPAIR_EFFICIENCY_GAIN
		"car_free_day":
			GameManager.queue_car_free_day()
		"shield_day":
			GameManager.queue_shield_day()
		"flash":
			if GameManager.has_flash_upgrade:
				return false
			GameManager.has_flash_upgrade = true
			GameManager.player_speed_multiplier *= FLASH_SPEED_MULTIPLIER
		_:
			return false

	GameManager.money -= cost
	return true


func _can_buy_offer(offer: Dictionary) -> bool:
	var offer_id: String = String(offer.get("id", ""))
	var group: String = String(offer.get("group", ""))
	var cost: int = int(offer.get("cost", 0))

	if bool(_purchased_offer_ids.get(offer_id, false)):
		return false

	if GameManager.money < cost:
		return false

	if group == "Card" and GameManager.get_total_cards() >= GameManager.max_cards:
		return false

	if offer_id == "flash" and GameManager.has_flash_upgrade:
		return false

	return true


func _update_labels() -> void:
	title_label.text = "Day %d - Prepare" % GameManager.current_day
	money_label.text = "Money: $%d   Repair: +%.1f/hit   Cards: %d/%d   Walk: x%.1f" % [
		GameManager.money,
		GameManager.get_current_repair_amount(),
		GameManager.get_total_cards(),
		GameManager.max_cards,
		GameManager.player_speed_multiplier
	]


func _refresh_offer_buttons() -> void:
	for index in range(_offer_buttons.size()):
		var button := _offer_buttons[index]
		if index >= _current_offers.size():
			button.visible = false
			continue

		var offer: Dictionary = _current_offers[index]
		button.visible = true
		button.text = _format_offer_text(offer)
		button.disabled = !_can_buy_offer(offer)


func _format_offer_text(offer: Dictionary) -> String:
	return "[%s] %s - $%d: %s" % [
		String(offer.get("group", "")),
		String(offer.get("name", "")),
		int(offer.get("cost", 0)),
		String(offer.get("description", ""))
	]
