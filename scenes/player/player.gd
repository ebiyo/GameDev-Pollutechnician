extends CharacterBody2D

@export var SPEED: float = 300.0

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var _facing_right: bool = false
var _footstep_timer: float = 0.0

const FOOTSTEP_INTERVAL: float = 0.34


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * SPEED * GameManager.player_speed_multiplier
	move_and_slide()
	_update_footsteps(input_vector, _delta)
	_update_animation(input_vector)


func _update_animation(input_vector: Vector2) -> void:
	if animated_sprite == null:
		return

	if input_vector.x < 0.0:
		_facing_right = false
	elif input_vector.x > 0.0:
		_facing_right = true

	animated_sprite.flip_h = _facing_right

	if !input_vector.is_zero_approx():
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")


func _update_footsteps(input_vector: Vector2, delta: float) -> void:
	if input_vector.is_zero_approx():
		_footstep_timer = 0.0
		return

	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return

	AudioManager.play_footstep()
	_footstep_timer = FOOTSTEP_INTERVAL / maxf(GameManager.player_speed_multiplier, 1.0)
