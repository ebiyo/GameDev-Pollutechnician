extends Node2D

const GAME_OVER_SCENE := preload("res://scenes/ui/game_over.tscn")

@onready var day_end_screen: CanvasLayer = $DayEnd
@onready var win_screen: CanvasLayer = $Win

var game_over_screen: CanvasLayer


func _ready() -> void:
	PollutionManager.game_over.connect(_on_game_over)
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.game_won.connect(_on_game_won)
	GameManager.start_day()


func _on_game_over() -> void:
	if is_instance_valid(game_over_screen):
		game_over_screen.visible = true
		return

	game_over_screen = GAME_OVER_SCENE.instantiate()
	add_child(game_over_screen)
	game_over_screen.visible = true


func _on_day_ended(_money_earned: int) -> void:
	day_end_screen.visible = true


func _on_game_won() -> void:
	win_screen.visible = true
