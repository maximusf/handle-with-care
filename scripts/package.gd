extends RigidBody2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var whoosh_sfx: AudioStreamPlayer2D = $WhooshSFX # Used when Package is in the air
@onready var plop_solid_sfx: AudioStreamPlayer2D = $PlopSolidSFX # Used when Package collides with a surface
@onready var package_destroyed_sfx: AudioStreamPlayer2D = $PackageDestroyedSFX # Used when Package is destroyed

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
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (package_hp == 5):
			get_kicked(Vector2(0,-50), 50)
	pass

func get_kicked(direction: Vector2, power: float):
	if is_destroyed:
		return
	
	if (!hp_check()):
		is_destroyed = true
		package_destroyed_sfx.play()
		destroy.emit(self)
	else:
		apply_impulse(direction * power)
		if not whoosh_sfx.playing:
			whoosh_sfx.play()
		is_in_air = true	
		kicked.emit(self) # Sends the broadcast that it has been kicked while also sending itself as a parameter

func _on_sleeping_state_changed() -> void:
	if sleeping and is_in_air:
		is_in_air = false
		whoosh_sfx.stop()
		plop_solid_sfx.play()
		landed.emit(self)
		

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
