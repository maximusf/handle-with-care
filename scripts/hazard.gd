extends Area2D

@export var dmg = 10
@export var bouce_force: float = 500.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(dmg)
	if body.has_method("bounce"):
		body.bounce(global_position, bouce_force)
