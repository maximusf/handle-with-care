extends RigidBody2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

const PACKAGE_DESTROYED = preload("res://assets/sprites/package/package_destroyed.png")
const PACKAGE_INTACT = preload("res://assets/sprites/package/package_intact.png")
const PACKAGE_DAMAGED = preload("res://assets/sprites/package/package_damaged.png")


signal kicked(kicked_package) # Used to let other Game Objects know that the package has been kicked
signal landed(kicked_package) # Used to let other Game Objects know that the package is on the ground
signal destroy(destroyed_package) # Used to let other Game Objects know that the package has no more HP

var package_hp = 5
var is_destroyed = false
var is_in_air = false # To know when to put the camera on the package

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_in_air = true
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_kicked(direction: Vector2, power: float):
	if is_destroyed:
		return
	
	if (!hp_check()):
		is_destroyed = true
		destroy.emit(self)
	else:
		apply_impulse(direction * power)
		is_in_air = true	
		kicked.emit(self) # Sends the broadcast that it has been kicked while also sending itself as a parameter

func _on_sleeping_state_changed() -> void:
	if sleeping and is_in_air:
		print("I fell")
		is_in_air = false
		landed.emit(self)
	if (not sleeping):
		print("IM FALLING")


func hp_check() -> bool:
	package_hp -= 1
	if (package_hp <= 0):
		sprite_2d.texture = PACKAGE_DESTROYED
		return false
	elif (package_hp <= 3):
		sprite_2d.texture = PACKAGE_DAMAGED
	elif (package_hp <= 5):
		sprite_2d.texture = PACKAGE_INTACT
	return true
