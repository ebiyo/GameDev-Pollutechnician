extends CanvasLayer

const STAGE_SELECT_SCENE_PATH := "res://scenes/ui/menus/stage_select.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/ui/menus/tutorial.tscn"

@onready var play_button: Button = $Center/Content/Buttons/PlayButton
@onready var tutorial_button: Button = $Center/Content/Buttons/TutorialButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_button.pressed.connect(_on_play_button_pressed)
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)


func _on_play_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE_PATH)


func _on_tutorial_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)
