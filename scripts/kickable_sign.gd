extends RigidBody2D
## A tutorial sign that can also be kicked around
## it isn't a package, so it has no hp and doesn't count toward deliveries
## place it with its origin on the floor like a normal tutorial sign

@export_multiline var text := ""

@onready var sign_area: Area2D = $Sign
@onready var prompt: Sprite2D = $Sign/Prompt

# the player skips destroyed things when looking for a kick target, a sign never breaks
var is_destroyed := false

func _ready() -> void:
	sign_area.text = text

func _physics_process(_delta: float) -> void:
	# keep the E prompt upright above the sign even when it tumbles
	prompt.global_rotation = 0.0
	prompt.global_position = global_position + Vector2(0, -84)

func get_kicked(direction: Vector2, power: float) -> void:
	apply_impulse(direction * power)
