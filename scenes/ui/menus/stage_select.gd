extends CanvasLayer

const TITLE_SCENE_PATH := "res://scenes/ui/menus/title_screen.tscn"
const WORLD_SCENE_PATH := "res://scenes/world/main.tscn"

@onready var easy_button: Button = $Center/Content/CardsRow/EasyCard/VBoxContainer/StartButton
@onready var normal_button: Button = $Center/Content/CardsRow/NormalCard/VBoxContainer/StartButton
@onready var hard_button: Button = $Center/Content/CardsRow/HardCard/VBoxContainer/StartButton
@onready var back_button: Button = $Center/Content/BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.play_title_music()
	easy_button.pressed.connect(_on_easy_button_pressed)
	normal_button.pressed.connect(_on_normal_button_pressed)
	hard_button.pressed.connect(_on_hard_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)


func _on_easy_button_pressed() -> void:
	_start_run(GameManager.Difficulty.EASY)


func _on_normal_button_pressed() -> void:
	_start_run(GameManager.Difficulty.NORMAL)


func _on_hard_button_pressed() -> void:
	_start_run(GameManager.Difficulty.HARD)


func _on_back_button_pressed() -> void:
	AudioManager.play_close()
	get_tree().paused = false
	SceneTransition.change_scene_to_file(TITLE_SCENE_PATH)


func _start_run(difficulty: int) -> void:
	AudioManager.play_click()
	AudioManager.play_run_music()
	get_tree().paused = false
	GameManager.start_new_run(difficulty)
	SceneTransition.change_scene_to_file(WORLD_SCENE_PATH)
