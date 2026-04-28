extends CanvasLayer

const TITLE_SCENE_PATH := "res://scenes/ui/menus/title_screen.tscn"

@onready var page_label: Label = $Center/Content/Footer/PageLabel
@onready var prev_button: Button = $Center/Content/Footer/NavButtons/PrevButton
@onready var next_button: Button = $Center/Content/Footer/NavButtons/NextButton
@onready var pages: Array[Node] = $Center/Content/PageAspect/Pages.get_children()

var current_page := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	prev_button.pressed.connect(_show_previous_page)
	next_button.pressed.connect(_show_next_page)
	$Center/Content/Footer/BackButton.pressed.connect(_go_back)
	_refresh_page()


func _show_previous_page() -> void:
	if current_page > 0:
		current_page -= 1
		_refresh_page()


func _show_next_page() -> void:
	if current_page < pages.size() - 1:
		current_page += 1
		_refresh_page()


func _go_back() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)


func _refresh_page() -> void:
	for index in range(pages.size()):
		pages[index].visible = index == current_page

	page_label.text = "Page %d / %d" % [current_page + 1, pages.size()]
	prev_button.disabled = current_page == 0
	next_button.disabled = current_page == pages.size() - 1
