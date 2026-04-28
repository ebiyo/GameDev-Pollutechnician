extends CanvasLayer

const STAGE_SELECT_SCENE_PATH := "res://scenes/ui/menus/stage_select.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/ui/menus/tutorial.tscn"
const LATEST_RUN_SCENE_PATH := "res://scenes/ui/menus/latest_run.tscn"

@onready var play_button: Button = $Center/Content/Buttons/PlayButton
@onready var tutorial_button: Button = $Center/Content/Buttons/TutorialButton
@onready var latest_run_button: Button = $LatestRunButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_button.pressed.connect(_on_play_button_pressed)
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)
	latest_run_button.pressed.connect(_on_latest_run_button_pressed)


func _on_play_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE_PATH)


func _on_tutorial_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)


func _on_latest_run_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LATEST_RUN_SCENE_PATH)
