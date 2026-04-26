extends CanvasLayer

signal difficulty_selected(difficulty: int)

@onready var easy_button: Button = $Panel/VBoxContainer/EasyButton
@onready var normal_button: Button = $Panel/VBoxContainer/NormalButton
@onready var hard_button: Button = $Panel/VBoxContainer/HardButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	easy_button.pressed.connect(_on_easy_button_pressed)
	normal_button.pressed.connect(_on_normal_button_pressed)
	hard_button.pressed.connect(_on_hard_button_pressed)


func _on_easy_button_pressed() -> void:
	difficulty_selected.emit(GameManager.Difficulty.EASY)


func _on_normal_button_pressed() -> void:
	difficulty_selected.emit(GameManager.Difficulty.NORMAL)


func _on_hard_button_pressed() -> void:
	difficulty_selected.emit(GameManager.Difficulty.HARD)
