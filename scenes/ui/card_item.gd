class_name CardItem
extends PanelContainer

signal use_pressed(card_type: String)
signal hover_changed(description: String, is_visible: bool)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var use_button: Button = $VBoxContainer/UseButton

var card_type: String = ""
var card_name: String = "Card"
var _description: String = ""


func _ready() -> void:
	use_button.pressed.connect(_on_use_button_pressed)
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
	hover_changed.emit(_description, true)


func _on_mouse_exited() -> void:
	hover_changed.emit("", false)
