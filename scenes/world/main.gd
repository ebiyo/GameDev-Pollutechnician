extends Node2D

const GAME_OVER_SCENE := preload("res://scenes/ui/menus/game_over.tscn")

@onready var day_end_screen: CanvasLayer = $DayEnd
@onready var day_start_screen: CanvasLayer = $DayStart
@onready var repair_popup: RepairPopup = $RepairPopup
@onready var win_screen: CanvasLayer = $Win

var game_over_screen: CanvasLayer


func _ready() -> void:
	PollutionManager.game_over.connect(_on_game_over)
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.game_won.connect(_on_game_won)
	repair_popup.popup_closed.connect(_on_repair_popup_closed)
	_connect_machine_signals()
	day_end_screen.visible = false
	day_start_screen.visible = false
	win_screen.visible = false
	get_tree().paused = false
	GameManager.start_day()


func _on_game_over() -> void:
	if is_instance_valid(game_over_screen):
		game_over_screen.visible = true
		game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		return

	game_over_screen = GAME_OVER_SCENE.instantiate()
	add_child(game_over_screen)
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.visible = true
	get_tree().paused = true


func _on_day_ended(_money_earned: int) -> void:
	if repair_popup.visible:
		repair_popup.close()
	day_end_screen.visible = false
	day_start_screen.visible = true
	day_start_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true


func _on_game_won() -> void:
	if repair_popup.visible:
		repair_popup.close()
	win_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	win_screen.visible = true
	get_tree().paused = true


func open_repair_popup(machine: Machine) -> void:
	if repair_popup.visible:
		return

	repair_popup.open(machine)


func _connect_machine_signals() -> void:
	for machine_node in get_tree().get_nodes_in_group("machines"):
		var machine := machine_node as Machine
		if machine != null and !machine.repair_requested.is_connected(open_repair_popup):
			machine.repair_requested.connect(open_repair_popup)


func _on_repair_popup_closed() -> void:
	pass
