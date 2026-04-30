class_name CardItem
extends PanelContainer

signal use_pressed(card_type: String)
signal hover_changed(description: String, is_visible: bool)

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var use_button: Button = $MarginContainer/VBoxContainer/UseButton

var card_type: String = ""
var card_name: String = "Card"
var _description: String = ""
var _is_hovering_card: bool = false


func _ready() -> void:
	use_button.pressed.connect(_on_use_button_pressed)
	use_button.mouse_entered.connect(_on_mouse_entered)
	use_button.mouse_exited.connect(_on_mouse_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_update_ui()


func setup(new_card_type: String, new_card_name: String, description: String) -> void:
	card_type = new_card_type
	card_name = new_card_name
	_description = description
	_update_ui()


func _update_ui() -> void:
	if !is_node_ready():
		return

	name_label.text = card_name


func _on_use_button_pressed() -> void:
	use_pressed.emit(card_type)
	queue_free()


func _on_mouse_entered() -> void:
	if _is_hovering_card:
		return

	_is_hovering_card = true
	hover_changed.emit(_description, true)


func _on_mouse_exited() -> void:
	if use_button.get_global_rect().has_point(get_global_mouse_position()):
		return

	_is_hovering_card = false
	hover_changed.emit("", false)
