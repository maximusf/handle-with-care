extends Area2D

signal turned_on
signal turned_off

@onready var lever_sprite: AnimatedSprite2D = $lever_animation
@onready var lever_sound: AudioStreamPlayer2D = $lever_sound

var _on := false
var bodies_in_area := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	lever_sprite.play("off")

func is_on() -> bool: 
	return _on
	
func _is_valid(body) -> bool:
	return body.is_in_group("player") or body.is_in_group("packages")

func _on_body_entered(body) -> void:
	if not _is_valid(body):
		return
	bodies_in_area += 1
	if bodies_in_area == 1:
		_toggle()
	
func _on_body_exited(body) -> void: 
	if not _is_valid(body):
		return
	bodies_in_area -= 1
	
func _toggle() -> void:
	_on = not _on
	lever_sound.play()
	if _on: 
		lever_sprite.play("on")
		turned_on.emit()
	else: 
		lever_sprite.play("off")
		turned_off.emit()
	
