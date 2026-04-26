extends CharacterBody2D

@export var SPEED: float = 300.0


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * SPEED
	move_and_slide()
