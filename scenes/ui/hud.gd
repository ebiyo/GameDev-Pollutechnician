extends CanvasLayer

const INGAME_TOTAL_MINUTES: float = 600.0
const CARD_ITEM_SCENE := preload("res://scenes/ui/card_item.tscn")

@onready var pollution_bar: ProgressBar = $PollutionBar
@onready var time_label: Label = $TimeLabel
@onready var day_label: Label = $DayLabel
@onready var day_end_hint_label: Label = $DayEndHintLabel
@onready var over_threshold_label: Label = $OverThresholdLabel
@onready var event_log_panel: Control = $EventLogPanel
@onready var event_log_entries: VBoxContainer = $EventLogPanel/EventLogEntries
@onready var card_tooltip_label: Label = $CardTooltipLabel
@onready var cards_root: Control = $CardsRoot
@onready var cards_container: HBoxContainer = $CardsRoot/CardsContainer

var _displayed_rain_cards: int = -1
var _displayed_repair_kit_cards: int = -1
var _event_log_signature: String = ""


func _ready() -> void:
	PollutionManager.pollution_changed.connect(_on_pollution_changed)
	GameManager.day_started.connect(_on_day_started)
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.game_won.connect(_on_game_won)
	_on_pollution_changed(PollutionManager.pollution)
	_set_timer_visible(false)
	_update_day_label()
	_update_time_label()
	_update_over_threshold_label()
	_update_day_end_hint()
	_update_event_log()
	_update_card_panel()

func _process(_delta: float) -> void:
	if GameManager.current_phase == GameManager.Phase.ACTIVE and time_label.visible:
		_update_time_label()
	_update_over_threshold_label()
	_update_event_log()
	_update_card_panel()


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
	_update_time_label()
	_update_day_end_hint()


func _on_day_ended(_money_earned: int) -> void:
	_set_timer_visible(false)


func _on_game_won() -> void:
	_set_timer_visible(false)


func _set_timer_visible(is_visible: bool) -> void:
	time_label.visible = is_visible
	day_label.visible = is_visible
	day_end_hint_label.visible = is_visible
	over_threshold_label.visible = is_visible
	cards_root.visible = is_visible
	card_tooltip_label.visible = false
	if !is_visible:
		event_log_panel.visible = false


func _update_day_label() -> void:
	day_label.text = "Day %d / %d" % [GameManager.current_day, GameManager.total_days]


func _update_time_label() -> void:
	var elapsed_fraction := 1.0 - (GameManager.day_timer / maxf(GameManager.day_duration, 0.001))
	var elapsed_minutes := elapsed_fraction * INGAME_TOTAL_MINUTES
	var total_minutes := int(elapsed_minutes)
	var hour := 8 + total_minutes / 60
	var minute := total_minutes % 60
	time_label.text = "%02d:%02d" % [hour, minute]


func _update_day_end_hint() -> void:
	day_end_hint_label.text = "day ends at 18:00"


func _update_over_threshold_label() -> void:
	over_threshold_label.text = "Over limit: %d / %d min" % [
		int(PollutionManager.ingame_minutes_over),
		int(PollutionManager.lose_threshold_minutes)
	]


func _update_event_log() -> void:
	var rendered_entries: Array[Dictionary] = EventManager.get_event_log_entries()
	event_log_panel.visible = !rendered_entries.is_empty()
	var signature: String = _build_event_log_signature(rendered_entries)
	if signature == _event_log_signature:
		return

	_event_log_signature = signature
	_rebuild_event_log_entries(rendered_entries)


func _update_card_panel() -> void:
	var has_any_cards: bool = GameManager.get_total_cards() > 0
	cards_root.visible = time_label.visible and has_any_cards
	cards_container.visible = has_any_cards

	if _displayed_rain_cards == GameManager.rain_cards and _displayed_repair_kit_cards == GameManager.repair_kit_cards:
		return

	_displayed_rain_cards = GameManager.rain_cards
	_displayed_repair_kit_cards = GameManager.repair_kit_cards
	_rebuild_cards()


func _rebuild_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	for i in range(GameManager.rain_cards):
		cards_container.add_child(_create_card_item(
			GameManager.RAIN_CARD_TYPE,
			"Rain Card",
			"Instantly reduces pollution by 15."
		))

	for i in range(GameManager.repair_kit_cards):
		cards_container.add_child(_create_card_item(
			GameManager.REPAIR_KIT_CARD_TYPE,
			"Repair Kit",
			"Repairs all machines to full durability."
		))


func _create_card_item(card_type: String, card_name: String, description: String) -> PanelContainer:
	print("CREATE CARD:", card_name)
	var card := CARD_ITEM_SCENE.instantiate() as CardItem
	card.size_flags_vertical = Control.SIZE_SHRINK_END
	card.setup(card_type, card_name, description)
	card.use_pressed.connect(_on_card_use_pressed)
	card.hover_changed.connect(_on_card_hover_changed)
	return card


func _on_card_use_pressed(card_type: String) -> void:
	card_tooltip_label.visible = false
	card_tooltip_label.text = ""
	if GameManager.use_card(card_type):
		_update_card_panel()


func _on_card_hover_changed(description: String, is_visible: bool) -> void:
	card_tooltip_label.visible = is_visible
	card_tooltip_label.text = description


func _rebuild_event_log_entries(rendered_entries: Array[Dictionary]) -> void:
	for child in event_log_entries.get_children():
		child.queue_free()

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_log_entries.add_child(spacer)

	for entry in rendered_entries:
		event_log_entries.add_child(_create_event_log_label(
			String(entry.get("text", "")),
			float(entry.get("alpha", 1.0)),
			entry.get("color", Color(1.0, 1.0, 1.0, 1.0)) as Color
		))


func _create_event_log_label(text: String, alpha: float, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color(color.r, color.g, color.b, alpha)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build_event_log_signature(rendered_entries: Array[Dictionary]) -> String:
	var parts: PackedStringArray = []
	for entry in rendered_entries:
		var color: Color = entry.get("color", Color(1.0, 1.0, 1.0, 1.0)) as Color
		parts.append("%s|%.2f|%.2f|%.2f|%.2f" % [
			String(entry.get("text", "")),
			float(entry.get("alpha", 1.0)),
			color.r,
			color.g,
			color.b
		])
	return "::".join(parts)
