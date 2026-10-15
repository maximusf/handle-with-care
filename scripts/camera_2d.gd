extends Camera2D

@export var player: CharacterBody2D
@onready var camera_2d: Camera2D = $"."
var camera_target: Node2D = null
var camera_offset_direction: int = 1

@export var free_cam_speed := 1500.0
@export var free_cam_dead_zone := 20.0
@export var main_tilemap : TileMapLayer

const ZOOM_STEP := 0.1
const MIN_ZOOM := 1.5
const MAX_ZOOM := 4.0
const REGULAR_ZOOM: Vector2 = Vector2(2.5, 2.5)

var is_free_cam := false
var target: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().connect("level_loaded", _on_level_loaded)
	

func _on_level_loaded(level: Node2D) -> void:
	player = level.get_node_or_null("Player")
	
	main_tilemap = level.get_node_or_null("MainTileMap") as TileMapLayer
	if main_tilemap != null:
		set_limits_from_tilemap(main_tilemap)
		
	for package in level.get_tree().get_nodes_in_group("packages"):
		register_package(package)
	if player != null:
		set_camera_target(player)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_free_cam:
		move_free_camera(delta)
	else:
		if Input.is_action_just_pressed("move_left"):
			camera_offset_direction = -1
		if Input.is_action_just_pressed("move_right"):
			camera_offset_direction = 1
		if is_instance_valid(camera_target):
			camera_2d.global_position = Vector2(camera_target.global_position.x + (camera_offset_direction * 80), camera_target.global_position.y)
		else:
			pass # Means we're in the menu

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toogle_free_cam"):
		is_free_cam = not is_free_cam
	
	if not is_free_cam:
		zoom = REGULAR_ZOOM
		return
	
	if event.is_action_pressed("zoom_in"):
		var new_zoom := clampf(zoom.x + ZOOM_STEP, MIN_ZOOM, MAX_ZOOM)
		zoom = Vector2(new_zoom, new_zoom)
	
	if event.is_action_pressed("zoom_out"):
		var new_zoom := clampf(zoom.x - ZOOM_STEP, MIN_ZOOM, MAX_ZOOM)
		zoom = Vector2(new_zoom, new_zoom)
	
func move_free_camera(delta: float) -> void:
	var screen_center := get_viewport_rect().size / 2.0
	var mouse_offset := get_viewport().get_mouse_position() - screen_center
	if mouse_offset.length() < free_cam_dead_zone:
		return
	var strength := clampf(mouse_offset.length() / screen_center.length(), 0.0, 1.0)
	global_position += mouse_offset.normalized() * free_cam_speed * strength * delta
	global_position = Vector2(
		clampf(global_position.x, limit_left, limit_right),
		clampf(global_position.y, limit_top, limit_bottom)
	)
func set_limits_from_tilemap(tilemap: TileMapLayer) -> void:
	var used_rect := tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return
	var tile_size := Vector2(tilemap.tile_set.tile_size)
	
	# Top-left edge of the first used tile.
	var top_left := tilemap.to_global(
		tilemap.map_to_local(used_rect.position) - tile_size / 2.0
	)

	# Bottom-right edge of the last used tile.
	var last_cell := used_rect.end - Vector2i.ONE
	var bottom_right := tilemap.to_global(
		tilemap.map_to_local(last_cell) + tile_size / 2.0
	)
	limit_left = floori(top_left.x)
	limit_top = floori(top_left.y)
	limit_right = ceili(bottom_right.x)
	limit_bottom = ceili(bottom_right.y)
		
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
