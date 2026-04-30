class_name PauseMenu
extends CanvasLayer

signal resume_requested()
signal back_to_title_requested()

const TITLE_SCENE_PATH := "res://scenes/ui/menus/title_screen.tscn"

@onready var resume_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var back_to_title_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BackToTitleButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	resume_button.pressed.connect(_on_resume_button_pressed)
	back_to_title_button.pressed.connect(_on_back_to_title_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if !visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_resume_button_pressed()
		get_viewport().set_input_as_handled()


func open() -> void:
	show()
	resume_button.grab_focus()


func close() -> void:
	hide()


func _on_resume_button_pressed() -> void:
	resume_requested.emit()


func _on_back_to_title_button_pressed() -> void:
	get_tree().paused = false
	back_to_title_requested.emit()
	SceneTransition.change_scene_to_file(TITLE_SCENE_PATH)
