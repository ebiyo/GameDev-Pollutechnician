extends CanvasLayer

@onready var play_again_button: Button = $PlayAgainButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_again_button.pressed.connect(_on_play_again_button_pressed)


func _on_play_again_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
