extends CanvasLayer

const TITLE_SCENE_PATH := "res://scenes/ui/menus/title_screen.tscn"

@onready var play_again_button: Button = $PlayAgainButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_again_button.pressed.connect(_on_play_again_button_pressed)


func _on_play_again_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)
