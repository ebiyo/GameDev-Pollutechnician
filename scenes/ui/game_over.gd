extends CanvasLayer

const TITLE_SCENE_PATH := "res://scenes/ui/title_screen.tscn"

@onready var restart_button: Button = $RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_on_restart_button_pressed)


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)
