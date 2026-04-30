extends CanvasLayer

const OFFER_COUNT: int = 3
const RAIN_CARD_COST: int = 35
const REPAIR_KIT_CARD_COST: int = 45
const SUPER_REPAIR_KIT_CARD_COST: int = 75
const FREEZE_CARD_COST: int = 50
const SPEED_BOOST_COST: int = 30
const REPAIR_EFFICIENCY_COST: int = 45
const CAR_FREE_DAY_COST: int = 35
const SHIELD_COST: int = 55
const FLASH_COST: int = 80
const SPEED_BOOST_AMOUNT: float = 0.15
const REPAIR_EFFICIENCY_GAIN: float = 4.0
const FLASH_SPEED_MULTIPLIER: float = 2.0

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var money_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MoneyLabel
@onready var start_day_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartDayButton

var _offer_cards: Array[Dictionary] = []
var _current_offers: Array[Dictionary] = []
var _purchased_offer_ids: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.day_ended.connect(_on_day_ended)
	_offer_cards = [
		_make_offer_card_refs($CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OffersRow/OfferCard1),
		_make_offer_card_refs($CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OffersRow/OfferCard2),
		_make_offer_card_refs($CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OffersRow/OfferCard3)
	]

	for index in range(_offer_cards.size()):
		var buy_button := _offer_cards[index]["buy_button"] as Button
		buy_button.pressed.connect(_on_offer_button_pressed.bind(index))

	start_day_button.pressed.connect(_on_start_day_button_pressed)
	hide()


func _on_day_ended(_money_earned: int) -> void:
	GameManager.current_phase = GameManager.Phase.PREP
	_roll_daily_offers()
	_update_labels()
	_refresh_offer_cards()
	hide()


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
	_refresh_offer_cards()


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
			"Add 1 card (restore all machine durability when used)."
		),
		_make_offer(
			"super_repair_kit_card",
			"Card",
			"Super Repair Kit Card",
			SUPER_REPAIR_KIT_CARD_COST,
			"Add 1 card (restore all machine durability and overclock when used)."
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


func _make_offer(id: String, group: String, offer_name: String, cost: int, description: String) -> Dictionary:
	return {
		"id": id,
		"group": group,
		"name": offer_name,
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
		"super_repair_kit_card":
			if !GameManager.add_card(GameManager.SUPER_REPAIR_KIT_CARD_TYPE):
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
	GameManager.record_offer_purchase(offer)
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
	title_label.text = "%s - Day %d - Prepare" % [
		GameManager.difficulty_name,
		GameManager.current_day
	]
	money_label.text = "Money: $%d   Repair: +%.1f/hit   Cards: %d/%d   Walk: x%.1f" % [
		GameManager.money,
		GameManager.get_current_repair_amount(),
		GameManager.get_total_cards(),
		GameManager.max_cards,
		GameManager.player_speed_multiplier
	]


func _refresh_offer_cards() -> void:
	for index in range(_offer_cards.size()):
		var card := _offer_cards[index]
		var panel := card["panel"] as PanelContainer
		var group_label := card["group_label"] as Label
		var name_label := card["name_label"] as Label
		var description_label := card["description_label"] as Label
		var cost_label := card["cost_label"] as Label
		var buy_button := card["buy_button"] as Button

		if index >= _current_offers.size():
			panel.visible = false
			continue

		var offer: Dictionary = _current_offers[index]
		panel.visible = true
		group_label.text = String(offer.get("group", "Offer"))
		name_label.text = String(offer.get("name", "Unknown"))
		description_label.text = String(offer.get("description", ""))
		cost_label.text = "Cost: $%d" % int(offer.get("cost", 0))
		buy_button.disabled = !_can_buy_offer(offer)
		buy_button.text = _get_offer_button_text(offer)


func _get_offer_button_text(offer: Dictionary) -> String:
	var offer_id: String = String(offer.get("id", ""))
	var cost: int = int(offer.get("cost", 0))

	if bool(_purchased_offer_ids.get(offer_id, false)):
		return "Purchased"

	if GameManager.money < cost:
		return "Need $%d" % cost

	if String(offer.get("group", "")) == "Card" and GameManager.get_total_cards() >= GameManager.max_cards:
		return "Card slots full"

	if offer_id == "flash" and GameManager.has_flash_upgrade:
		return "Already owned"

	return "Buy"


func _make_offer_card_refs(panel: PanelContainer) -> Dictionary:
	return {
		"panel": panel,
		"group_label": panel.get_node("MarginContainer/VBoxContainer/GroupLabel") as Label,
		"name_label": panel.get_node("MarginContainer/VBoxContainer/NameLabel") as Label,
		"description_label": panel.get_node("MarginContainer/VBoxContainer/DescriptionLabel") as Label,
		"cost_label": panel.get_node("MarginContainer/VBoxContainer/CostLabel") as Label,
		"buy_button": panel.get_node("MarginContainer/VBoxContainer/BuyButton") as Button
	}
