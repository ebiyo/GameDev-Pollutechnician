extends CharacterBody2D

@export var SPEED: float = 300.0

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var _facing_right: bool = false


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * SPEED * GameManager.player_speed_multiplier
	move_and_slide()
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
