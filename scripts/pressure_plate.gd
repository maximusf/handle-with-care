extends Area2D

signal pressed
signal released

@onready var plate_animation: AnimatedSprite2D = $plate_animation
@onready var pressed_sound: AudioStreamPlayer2D = $pressed_sound
@onready var unpressed_sound: AudioStreamPlayer2D = $unpressed_sound

var bodies_on_plate := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func is_pressed() -> bool:
	return bodies_on_plate > 0

func _is_valid(body) -> bool:
	return body.is_in_group("player") or body.is_in_group("packages")

func _on_body_entered(body) -> void:
	if not _is_valid(body):
		return
	
	bodies_on_plate += 1
	if bodies_on_plate == 1:
		plate_animation.play("down")
		pressed_sound.play()
		pressed.emit()

func _on_body_exited(body) -> void: 
	if not _is_valid(body):
		return
	bodies_on_plate -= 1
	if bodies_on_plate == 0:
		plate_animation.play("up")
		unpressed_sound.play()
		released.emit()
