extends Camera2D

@export var player: CharacterBody2D
@onready var camera_2d: Camera2D = $"."
var camera_target: Node2D = null
var camera_offset_direction: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_camera_target(player)
	for package in get_tree().get_nodes_in_group("packages"):
		register_package(package)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):
		camera_offset_direction = -1
	if Input.is_action_just_pressed("move_right"):
		camera_offset_direction = 1
	if is_instance_valid(camera_target):
		camera_2d.global_position = Vector2(camera_target.global_position.x + (camera_offset_direction * 80), camera_target.global_position.y)
	else:
		print("huhuhuh")
	pass

func set_camera_target(new_target: Node2D) -> void:
	camera_target = new_target
	
func register_package(package: RigidBody2D) -> void:
	if not package.kicked.is_connected(_on_package_kicked):
		package.kicked.connect(_on_package_kicked)
		
	if not package.landed.is_connected(_on_package_landed):
		package.landed.connect(_on_package_landed)
		
func _on_package_kicked(kicked_package: Variant) -> void:
	set_camera_target(kicked_package)
	pass # Replace with function body.
	
func _on_package_landed(kicked_package: Variant) -> void:
	set_camera_target(player)
	pass # Replace with function body.
