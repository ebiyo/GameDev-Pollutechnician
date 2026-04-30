extends CanvasLayer

const READY_TEXT := "Ready..."
const START_TEXT := "Start!"
const READY_DURATION := 0.75
const START_DURATION := 0.55
const TRANSITION_DURATION := 0.18
const BACKDROP_ALPHA := 0.45

@onready var backdrop: ColorRect = $Backdrop
@onready var message_label: Label = $CenterContainer/MessageLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func play_intro() -> void:
	show()
	backdrop.modulate.a = BACKDROP_ALPHA
	message_label.modulate.a = 0.0
	message_label.scale = Vector2.ONE * 0.88

	await _show_message(READY_TEXT, READY_DURATION, 0.92)
	await _show_message_instant(START_TEXT, START_DURATION, 1.0)

	hide()


func _show_message(text: String, hold_duration: float, peak_alpha: float) -> void:
	message_label.text = text
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(message_label, "modulate:a", peak_alpha, TRANSITION_DURATION)
	tween.parallel().tween_property(message_label, "scale", Vector2.ONE, TRANSITION_DURATION)
	await tween.finished

	await get_tree().create_timer(hold_duration, true, false, true).timeout

	var exit_tween := create_tween()
	exit_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	exit_tween.set_trans(Tween.TRANS_CUBIC)
	exit_tween.set_ease(Tween.EASE_IN)
	exit_tween.parallel().tween_property(message_label, "modulate:a", 0.0, TRANSITION_DURATION)
	exit_tween.parallel().tween_property(message_label, "scale", Vector2.ONE * 1.04, TRANSITION_DURATION)
	await exit_tween.finished

	message_label.scale = Vector2.ONE * 0.88


func _show_message_instant(text: String, hold_duration: float, peak_alpha: float) -> void:
	message_label.text = text
	message_label.modulate.a = peak_alpha
	message_label.scale = Vector2.ONE

	await get_tree().create_timer(hold_duration, true, false, true).timeout

	var exit_tween := create_tween()
	exit_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	exit_tween.set_trans(Tween.TRANS_CUBIC)
	exit_tween.set_ease(Tween.EASE_IN)
	exit_tween.parallel().tween_property(message_label, "modulate:a", 0.0, TRANSITION_DURATION)
	exit_tween.parallel().tween_property(message_label, "scale", Vector2.ONE * 1.04, TRANSITION_DURATION)
	await exit_tween.finished

	message_label.scale = Vector2.ONE * 0.88
