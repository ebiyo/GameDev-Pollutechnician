extends CanvasLayer

const DEFAULT_DURATION := 0.45
const TRANSITION_COLOR := Color(0.04, 0.06, 0.08, 1.0)

var _is_transitioning := false
var _overlay: ColorRect
var _wipe_from_left := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100

	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.color = TRANSITION_COLOR
	_overlay.visible = false

	add_child(_overlay)
	_set_cover_amount(0.0)


func change_scene_to_file(path: String, duration: float = DEFAULT_DURATION) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_overlay.visible = true
	_set_cover_amount(0.0)

	var half_duration := maxf(duration * 0.5, 0.01)
	await _animate_cover_amount(0.0, 1.0, half_duration, true)

	var tree := get_tree()
	if tree == null:
		_finish_transition()
		return

	var error := tree.change_scene_to_file(path)
	if error != OK:
		push_error("Scene transition failed for %s (error %d)." % [path, error])
		await _animate_cover_amount(1.0, 0.0, half_duration, false)
		_finish_transition()
		return

	await tree.process_frame
	await tree.process_frame
	await _animate_cover_amount(1.0, 0.0, half_duration, false)
	_finish_transition()


func _animate_cover_amount(from_value: float, to_value: float, duration: float, from_left: bool) -> void:
	_wipe_from_left = from_left
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_cover_amount, from_value, to_value, duration)
	await tween.finished


func _set_cover_amount(amount: float) -> void:
	if _overlay == null:
		return

	var clamped_amount := clampf(amount, 0.0, 1.0)
	_overlay.pivot_offset = Vector2.ZERO if _wipe_from_left else Vector2(_overlay.size.x, 0.0)
	_overlay.scale = Vector2(clamped_amount, 1.0)


func _finish_transition() -> void:
	_set_cover_amount(0.0)
	_overlay.visible = false
	_is_transitioning = false
