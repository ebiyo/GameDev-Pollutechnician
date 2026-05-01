extends Node2D

const GAME_OVER_SCENE := preload("res://scenes/ui/menus/game_over.tscn")

@onready var day_end_screen = $DayEnd
@onready var day_start_screen = $DayStart
@onready var run_intro_screen: CanvasLayer = $RunIntro
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var repair_popup: RepairPopup = $RepairPopup
@onready var win_screen: CanvasLayer = $Win

var game_over_screen: CanvasLayer


func _ready() -> void:
	AudioManager.play_run_music()
	PollutionManager.game_over.connect(_on_game_over)
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.game_won.connect(_on_game_won)
	day_end_screen.next_day_requested.connect(_on_day_end_next_day_requested)
	repair_popup.popup_closed.connect(_on_repair_popup_closed)
	pause_menu.resume_requested.connect(_on_pause_menu_resume_requested)
	_connect_machine_signals()
	day_end_screen.visible = false
	day_start_screen.visible = false
	run_intro_screen.visible = false
	pause_menu.visible = false
	win_screen.visible = false
	await _start_new_run_intro()


func _unhandled_input(event: InputEvent) -> void:
	if !event.is_action_pressed("ui_cancel"):
		return

	if !_can_open_pause_menu():
		return

	_open_pause_menu()
	get_viewport().set_input_as_handled()


func _on_game_over() -> void:
	GameManager.finalize_run(false)

	if is_instance_valid(game_over_screen):
		game_over_screen.visible = true
		game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		_set_tree_paused(true)
		return

	game_over_screen = GAME_OVER_SCENE.instantiate()
	add_child(game_over_screen)
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.visible = true
	_set_tree_paused(true)


func _on_day_ended(_money_earned: int) -> void:
	if repair_popup.visible:
		repair_popup.close(false)
	day_start_screen.visible = false
	day_end_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	day_end_screen.visible = true
	_set_tree_paused(true)


func _on_day_end_next_day_requested() -> void:
	day_end_screen.visible = false
	day_start_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	day_start_screen.visible = true
	_set_tree_paused(true)


func _on_game_won() -> void:
	if repair_popup.visible:
		repair_popup.close(false)
	GameManager.finalize_run(true)
	win_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	win_screen.visible = true
	_set_tree_paused(true)


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


func _on_pause_menu_resume_requested() -> void:
	_close_pause_menu()


func _start_new_run_intro() -> void:
	_set_tree_paused(true)
	await run_intro_screen.play_intro()
	_set_tree_paused(false)
	GameManager.start_day()


func _set_tree_paused(should_pause: bool) -> void:
	if !is_inside_tree():
		return

	var tree := get_tree()
	if tree == null:
		return

	tree.paused = should_pause


func _can_open_pause_menu() -> bool:
	if get_tree().paused:
		return false

	if GameManager.current_phase != GameManager.Phase.ACTIVE:
		return false

	if repair_popup.visible or day_end_screen.visible or day_start_screen.visible or win_screen.visible:
		return false

	if is_instance_valid(game_over_screen) and game_over_screen.visible:
		return false

	return true


func _open_pause_menu() -> void:
	AudioManager.play_click()
	pause_menu.open()
	_set_tree_paused(true)


func _close_pause_menu() -> void:
	pause_menu.close()
	_set_tree_paused(false)
