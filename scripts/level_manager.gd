extends Node

@export var levels: Array[PackedScene] # shown on the level select screen in this order
@export var total_levels := 3 # boxes on the level select screen, any past the end of levels are grayed out
@onready var current_level_holder: Node2D = $CurrentLevel
@onready var user_interface: CanvasLayer = $User_Interface
@onready var camera: Camera2D = $Camera2D
var current_level_scene: PackedScene

# Smallest window allowed. Below this, text gets hard to read. Small enough to fit laptop screens with display scaling.
const MIN_WINDOW_SIZE := Vector2i(960, 540)

signal level_loaded(level: Node2D)

func _ready() -> void:
	get_window().min_size = MIN_WINDOW_SIZE
	user_interface.start_game_requested.connect(_on_start_game_requested)
	user_interface.set_level_slots(levels.size(), total_levels)
	user_interface.quit_to_menu_requested.connect(_quit_to_menu_requested)
	user_interface.level_select_requested.connect(_on_level_select_requested)
	user_interface.retry_requested.connect(_on_retry_requested)
	level_loaded.connect(user_interface.hud.bind_level)
	user_interface.settings_menu.zoom_changed.connect(camera.set_regular_zoom)
	# The saved zoom was loaded before this connection existed, so apply it once now.
	camera.set_regular_zoom(user_interface.settings_menu.zoom_slider.value)
	
func _on_start_game_requested(level_index: int) -> void:
	load_level(levels[level_index])
	user_interface.show_hud()
	get_tree().paused = false
	
func _on_retry_requested() -> void:
	reload_level()
	user_interface.show_hud()
	get_tree().paused = false

func _on_level_select_requested() -> void:
	unload_level()
	user_interface.show_level_select()

func _quit_to_menu_requested() -> void:
	unload_level()
	user_interface.show_main_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and current_level_scene != null:
		reload_level()

func load_level(level_scene: PackedScene) -> void:
	unload_level()
	current_level_scene = level_scene
	# Add the new level.
	var new_level := level_scene.instantiate()
	current_level_holder.add_child(new_level)
	level_loaded.emit(new_level)

func reload_level() -> void:
	load_level(current_level_scene)

# Removes the current level so nothing is left running behind the menus.
func unload_level() -> void:
	current_level_scene = null
	for child in current_level_holder.get_children():
		child.queue_free()
