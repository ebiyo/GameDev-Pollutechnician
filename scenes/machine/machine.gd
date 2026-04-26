extends StaticBody2D

signal durability_changed(value: float)

@export var max_durability: float = 100.0
@export var drain_rate: float = 5.0
@export var repair_rate: float = 20.0

var durability: float = max_durability
var is_player_nearby: bool = false

@onready var repair_zone: Area2D = $RepairZone
@onready var durability_bar: ProgressBar = $ProgressBar
@onready var body_visual: ColorRect = $Body


func _ready() -> void:
	durability = max_durability
	repair_zone.body_entered.connect(_on_repair_zone_body_entered)
	repair_zone.body_exited.connect(_on_repair_zone_body_exited)
	durability_changed.connect(_on_durability_changed)
	durability_bar.min_value = 0.0
	durability_bar.max_value = max_durability
	_on_durability_changed(durability)


func _process(delta: float) -> void:
	var previous_durability := durability

	durability = maxf(durability - drain_rate * delta, 0.0)

	if is_player_nearby and Input.is_action_pressed("repair"):
		durability = minf(durability + repair_rate * delta, max_durability)

	if !is_equal_approx(durability, previous_durability):
		durability_changed.emit(durability)


func _on_repair_zone_body_entered(body: Node) -> void:
	if body.name == "Player":
		is_player_nearby = true


func _on_repair_zone_body_exited(body: Node) -> void:
	if body.name == "Player":
		is_player_nearby = false


func _on_durability_changed(value: float) -> void:
	durability_bar.value = value
	body_visual.modulate = Color.RED if value < 20.0 else Color.WHITE
