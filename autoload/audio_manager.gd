extends Node

const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"

var MUSIC_TITLE: AudioStream = preload("res://assets/audio/music/title_music.ogg")
var MUSIC_RUN: AudioStream = preload("res://assets/audio/music/run_music.ogg")
var MUSIC_RUN_TENSE: AudioStream = preload("res://assets/audio/music/run_music_tense.ogg")

const SFX_BUILDING_FIRE := preload("res://assets/audio/sfx/building_fire.wav")
const SFX_CLEAN_AIR := preload("res://assets/audio/sfx/clean_air.wav")
const SFX_POWER_FLICKER := preload("res://assets/audio/sfx/power_flicker.wav")
const SFX_MACHINE_SURGE := preload("res://assets/audio/sfx/machine_surge.wav")
const SFX_CLICK := preload("res://assets/audio/sfx/click.wav")
const SFX_CLOSE := preload("res://assets/audio/sfx/close.wav")
const SFX_DAY_END := preload("res://assets/audio/sfx/day_end.wav")
const SFX_GAME_OVER := preload("res://assets/audio/sfx/game_over.wav")
const SFX_PURCHASE_ITEM := preload("res://assets/audio/sfx/purchase_item.wav")
const SFX_REPAIR_FAIL := preload("res://assets/audio/sfx/repair_fail.wav")
const SFX_SCENE_TRANSITION := preload("res://assets/audio/sfx/scene_transition.wav")
const SFX_USE_CARD := preload("res://assets/audio/sfx/use_card.wav")
const SFX_WIN := preload("res://assets/audio/sfx/win.wav")

const REPAIR_SUCCESS_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/repair_success/repair_1.wav"),
	preload("res://assets/audio/sfx/repair_success/repair_2.wav"),
	preload("res://assets/audio/sfx/repair_success/repair_3.wav"),
	preload("res://assets/audio/sfx/repair_success/repair_4.wav"),
	preload("res://assets/audio/sfx/repair_success/repair_5.wav")
]

const FOOTSTEP_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/footsteps/step_1.wav"),
	preload("res://assets/audio/sfx/footsteps/step_2.wav"),
	preload("res://assets/audio/sfx/footsteps/step_3.wav")
]

var sfx_bus_volume_db: float = 0.0
var music_bus_volume_db: float = -5.0

var _music_player: AudioStreamPlayer
var _music_track_id: String = ""
var _is_run_music_tense: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_ensure_audio_buses()
	_apply_bus_volumes()
	_configure_music_loops()
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = BUS_MUSIC
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)

	GameManager.day_started.connect(_on_day_started)
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.game_won.connect(_on_game_won)
	PollutionManager.pollution_changed.connect(_on_pollution_changed)
	PollutionManager.game_over.connect(_on_game_over)


func play_click() -> void:
	_play_sfx(SFX_CLICK)


func play_close() -> void:
	_play_sfx(SFX_CLOSE)


func play_scene_transition() -> void:
	_play_sfx(SFX_SCENE_TRANSITION)


func play_purchase_item() -> void:
	_play_sfx(SFX_PURCHASE_ITEM)


func play_use_card() -> void:
	_play_sfx(SFX_USE_CARD)


func play_repair_fail() -> void:
	_play_sfx(SFX_REPAIR_FAIL, true)


func play_random_repair_success() -> void:
	_play_random_sfx(REPAIR_SUCCESS_SOUNDS, true)


func play_footstep() -> void:
	_play_random_sfx(FOOTSTEP_SOUNDS, true)


func play_building_fire() -> void:
	_play_sfx(SFX_BUILDING_FIRE, true)


func play_clean_air() -> void:
	_play_sfx(SFX_CLEAN_AIR, true)


func play_power_flicker() -> void:
	_play_sfx(SFX_POWER_FLICKER, true)


func play_machine_surge() -> void:
	_play_sfx(SFX_MACHINE_SURGE, true)


func play_title_music(restart: bool = false) -> void:
	_is_run_music_tense = false
	_play_music("title", MUSIC_TITLE, restart)


func play_run_music(restart: bool = false) -> void:
	_is_run_music_tense = false
	_play_music("run", MUSIC_RUN, restart)


func stop_music() -> void:
	_music_player.stop()
	_music_track_id = ""
	_is_run_music_tense = false


func pause_music(paused: bool) -> void:
	if _music_player != null:
		_music_player.stream_paused = paused


func set_sfx_volume_db(value: float) -> void:
	sfx_bus_volume_db = value
	var bus_index := AudioServer.get_bus_index(BUS_SFX)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, sfx_bus_volume_db)


func set_music_volume_db(value: float) -> void:
	music_bus_volume_db = value
	var bus_index := AudioServer.get_bus_index(BUS_MUSIC)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, music_bus_volume_db)


func _on_day_started() -> void:
	_update_run_music_tension(PollutionManager.pollution >= PollutionManager.over_limit_pollution_threshold)


func _on_day_ended(_money_earned: int) -> void:
	_play_sfx(SFX_DAY_END)
	_update_run_music_tension(false)


func _on_game_won() -> void:
	stop_music()
	_play_sfx(SFX_WIN)


func _on_game_over() -> void:
	stop_music()
	_play_sfx(SFX_GAME_OVER)


func _on_pollution_changed(value: float) -> void:
	if GameManager.current_phase != GameManager.Phase.ACTIVE:
		return

	_update_run_music_tension(value >= PollutionManager.over_limit_pollution_threshold)


func _update_run_music_tension(should_be_tense: bool) -> void:
	if _music_track_id != "run" and _music_track_id != "run_tense":
		return

	if _is_run_music_tense == should_be_tense:
		return

	var target_id := "run_tense" if should_be_tense else "run"
	var target_stream := MUSIC_RUN_TENSE if should_be_tense else MUSIC_RUN
	var playback_position := 0.0

	if _music_player.playing:
		playback_position = _music_player.get_playback_position()
		var stream_length := maxf(target_stream.get_length(), 0.001)
		playback_position = fmod(playback_position, stream_length)

	_is_run_music_tense = should_be_tense
	_play_music(target_id, target_stream, true, playback_position)


func _play_music(track_id: String, stream: AudioStream, restart: bool, from_position: float = 0.0) -> void:
	if _music_player == null:
		return

	if !restart and _music_track_id == track_id and _music_player.playing:
		return

	_music_track_id = track_id
	_music_player.stream = stream
	_music_player.play(from_position)


func _play_sfx(stream: AudioStream, _pausable: bool = false) -> void:
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.bus = BUS_SFX
	player.stream = stream
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _play_random_sfx(streams: Array[AudioStream], pausable: bool = false) -> void:
	if streams.is_empty():
		return

	_play_sfx(streams[_rng.randi_range(0, streams.size() - 1)], pausable)


func _ensure_audio_buses() -> void:
	_ensure_audio_bus(BUS_SFX)
	_ensure_audio_bus(BUS_MUSIC)


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	AudioServer.add_bus(AudioServer.bus_count)
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _apply_bus_volumes() -> void:
	set_sfx_volume_db(sfx_bus_volume_db)
	set_music_volume_db(music_bus_volume_db)


func _configure_music_loops() -> void:
	if MUSIC_TITLE is AudioStreamOggVorbis:
		(MUSIC_TITLE as AudioStreamOggVorbis).loop = true
	if MUSIC_RUN is AudioStreamOggVorbis:
		(MUSIC_RUN as AudioStreamOggVorbis).loop = true
	if MUSIC_RUN_TENSE is AudioStreamOggVorbis:
		(MUSIC_RUN_TENSE as AudioStreamOggVorbis).loop = true
