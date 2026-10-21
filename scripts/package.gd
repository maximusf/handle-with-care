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
var is_delivered = false # Set by the delivery zone that accepted this package, so it can't count twice
var is_in_air = false # To know when to put the camera on the package

# a package this far outside the level goes back to where it started
const OUT_OF_BOUNDS_MARGIN := 256.0
var _level_bounds := Rect2() # empty if the level has no main tilemap to measure
var _start_transform := Transform2D.IDENTITY

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_start_transform = global_transform
	_level_bounds = _find_level_bounds()

# area covered by the main tilemap in world coordinates, plus a margin
func _find_level_bounds() -> Rect2:
	var tilemap := get_parent().get_node_or_null("MainTileMap") as TileMapLayer
	if tilemap == null or tilemap.get_used_rect().size == Vector2i.ZERO:
		return Rect2()
	var used_rect := tilemap.get_used_rect()
	var tile_size := Vector2(tilemap.tile_set.tile_size)
	var top_left := tilemap.to_global(tilemap.map_to_local(used_rect.position) - tile_size / 2.0)
	var bottom_right := tilemap.to_global(tilemap.map_to_local(used_rect.end - Vector2i.ONE) + tile_size / 2.0)
	return Rect2(top_left, bottom_right - top_left).grow(OUT_OF_BOUNDS_MARGIN)

# Safety net: if a hard kick still gets a package out of the level, put it back instead of letting it fall forever
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _level_bounds.has_area() and not _level_bounds.has_point(state.transform.origin):
		state.transform = _start_transform
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		is_in_air = false
		whoosh_sfx.stop()
		landed.emit(self) # lets the camera go back to the player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
		landed.emit(self)
	
func _on_body_entered(body: Node) -> void:
	if linear_velocity.length() > 70.0 and not plop_solid_sfx.playing:
		plop_solid_sfx.play()
	pass # Replace with function body.


func hp_check() -> bool:
	package_hp -= 1
	if (package_hp <= 0):
		self.rotation = 0.0
		sprite_2d.texture = PACKAGE_DESTROYED
		return false
	elif (package_hp <= 3):
		sprite_2d.texture = PACKAGE_DAMAGED
	elif (package_hp <= 5):
		sprite_2d.texture = PACKAGE_INTACT
	return true
