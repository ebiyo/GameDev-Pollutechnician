extends CanvasLayer

const INGAME_TOTAL_MINUTES: float = 600.0
const INGAME_START_HOUR: int = 8
const CARD_ITEM_SCENE := preload("res://scenes/ui/components/card_item.tscn")

@onready var pollution_bar: ProgressBar = $PollutionBar
@onready var pollution_bar_fill: StyleBoxFlat = pollution_bar.get_theme_stylebox("fill") as StyleBoxFlat
@onready var threshold_marker: ColorRect = $PollutionBar/ThresholdMarker
@onready var time_label: Label = $TimeLabel
@onready var day_label: Label = $DayLabel
@onready var day_end_hint_label: Label = $DayEndHintLabel
@onready var over_threshold_label: Label = $OverThresholdLabel
@onready var event_log_panel: Control = $EventLogPanel
@onready var event_log_entries: VBoxContainer = $EventLogPanel/EventLogEntries
@onready var card_tooltip_label: Label = $CardTooltipLabel
@onready var cards_root: Control = $CardsRoot
@onready var cards_container: VBoxContainer = $CardsRoot/CardsContainer
@onready var cheat_speed_button: Button = $CheatSpeedButton

var _displayed_card_signature: String = ""
var _event_log_signature: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PollutionManager.pollution_changed.connect(_on_pollution_changed)
	GameManager.day_started.connect(_on_day_started)
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.game_won.connect(_on_game_won)
	pollution_bar.resized.connect(_update_threshold_marker)
	cheat_speed_button.pressed.connect(_on_cheat_end_day_button_pressed)
	cheat_speed_button.visible = GameManager.CHEAT_BUTTON_ENABLED
	_on_pollution_changed(PollutionManager.pollution)
	_update_threshold_marker()
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
		pollution_bar_fill.bg_color = Color(0.45, 0.75, 0.55, 1.0)
	elif value < PollutionManager.over_limit_pollution_threshold:
		pollution_bar_fill.bg_color = Color(0.85, 0.75, 0.40, 1.0)
	else:
		pollution_bar_fill.bg_color = Color(0.90, 0.38, 0.28, 1.0)


func _on_day_started() -> void:
	_set_timer_visible(true)
	_update_day_label()
	_update_time_label()
	_update_day_end_hint()


func _on_day_ended(_money_earned: int) -> void:
	_update_day_label()
	_update_time_label()
	_update_day_end_hint()
	_update_card_panel()


func _on_game_won() -> void:
	_set_timer_visible(false)


func _set_timer_visible(should_show: bool) -> void:
	time_label.visible = should_show
	day_label.visible = should_show
	day_end_hint_label.visible = should_show
	over_threshold_label.visible = should_show
	cards_root.visible = should_show
	cheat_speed_button.visible = should_show and GameManager.CHEAT_BUTTON_ENABLED
	card_tooltip_label.visible = false
	if !should_show:
		event_log_panel.visible = false


func _update_day_label() -> void:
	day_label.text = "%s - Day %d / %d" % [
		GameManager.difficulty_name,
		GameManager.current_day,
		GameManager.total_days
	]


func _update_time_label() -> void:
	var elapsed_fraction := 1.0 - (GameManager.day_timer / maxf(GameManager.day_duration, 0.001))
	var elapsed_minutes := elapsed_fraction * INGAME_TOTAL_MINUTES
	var total_minutes := int(elapsed_minutes)
	var hour := INGAME_START_HOUR + int(total_minutes / 60.0)
	var minute := total_minutes % 60
	time_label.text = "%02d:%02d" % [hour, minute]


func _update_day_end_hint() -> void:
	var end_total_minutes := INGAME_START_HOUR * 60 + int(INGAME_TOTAL_MINUTES)
	var end_hour := int(end_total_minutes / 60.0)
	var end_minute := end_total_minutes % 60
	day_end_hint_label.text = "Day ends at %02d:%02d" % [end_hour, end_minute]


func _update_over_threshold_label() -> void:
	var current := PollutionManager.cumulative_minutes_over_threshold
	var limit := PollutionManager.lose_threshold_minutes

	over_threshold_label.text = "Over limit: %d / %d min" % [
		int(current),
		int(limit)
	]

	if current >= limit * 0.5:
		over_threshold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45, 1.0))
	else:
		over_threshold_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))


func _update_threshold_marker() -> void:
	var threshold_ratio := PollutionManager.over_limit_pollution_threshold / maxf(pollution_bar.max_value, 0.001)
	var marker_x := (pollution_bar.size.x * threshold_ratio) - (threshold_marker.size.x * 0.5)
	threshold_marker.position = Vector2(marker_x, 0.0)
	threshold_marker.size.y = pollution_bar.size.y


func _on_cheat_end_day_button_pressed() -> void:
	if !GameManager.CHEAT_BUTTON_ENABLED:
		return

	if GameManager.current_phase != GameManager.Phase.ACTIVE:
		return

	AudioManager.play_click()
	GameManager.end_day()


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

	var card_signature := GameManager.get_card_inventory_signature()
	if _displayed_card_signature == card_signature:
		return

	_displayed_card_signature = card_signature
	_rebuild_cards()


func _rebuild_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	var owned_cards: Array[Dictionary] = []
	for card_type in GameManager.get_card_types():
		var count := GameManager.get_card_count(card_type)
		if count <= 0:
			continue

		owned_cards.append({
			"type": card_type,
			"name": GameManager.get_card_name(card_type),
			"description": GameManager.get_card_description(card_type),
			"count": count
		})

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards_container.add_child(spacer)

	var rows: Array[HBoxContainer] = []
	var row: HBoxContainer = _create_card_row()
	for index in range(owned_cards.size()):
		if index > 0 and index % 2 == 0:
			rows.append(row)
			row = _create_card_row()

		var card_data: Dictionary = owned_cards[index]
		row.add_child(_create_card_item(
			String(card_data.get("type", "")),
			String(card_data.get("name", "Card")),
			String(card_data.get("description", "")),
			int(card_data.get("count", 1))
		))

	if row.get_child_count() > 0:
		rows.append(row)

	for row_index in range(rows.size() - 1, -1, -1):
		cards_container.add_child(rows[row_index])


func _create_card_item(card_type: String, card_name: String, description: String, count: int) -> PanelContainer:
	var card := CARD_ITEM_SCENE.instantiate() as CardItem
	card.size_flags_vertical = Control.SIZE_SHRINK_END
	card.setup(card_type, card_name, description, count)
	card.use_pressed.connect(_on_card_use_pressed)
	card.hover_changed.connect(_on_card_hover_changed)
	return card


func _create_card_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


func _on_card_use_pressed(card_type: String) -> void:
	card_tooltip_label.visible = false
	card_tooltip_label.text = ""
	if GameManager.use_card(card_type):
		_update_card_panel()


func _on_card_hover_changed(description: String, should_show: bool) -> void:
	card_tooltip_label.visible = should_show
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
	label.add_theme_font_size_override("font_size", 24)
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
