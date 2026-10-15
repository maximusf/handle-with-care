extends Node

@export var first_level: PackedScene
@onready var current_level_holder: Node2D = $CurrentLevel
@onready var user_interface: CanvasLayer = $User_Interface
var current_level_scene: PackedScene

signal level_loaded(level: Node2D)

func _ready() -> void:
	user_interface.start_game_requested.connect(_on_start_game_requested)
	user_interface.quit_to_menu_requested.connect(_quit_to_menu_requested)
	level_loaded.connect(user_interface.hud.bind_level)
	$CurrentLevel.level_completed.connect(user_interface.result_menu.show_result.bind(true))
	
func _on_start_game_requested() -> void:
	load_level(first_level)
	user_interface.hud.show()
	user_interface.main_menu.hide()
	get_tree().paused = false
	
func _quit_to_menu_requested() -> void:
	print("your mo")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("main_menu") and current_level_scene != null:
		user_interface.show_main_menu()
		get_tree().paused = true
	
	if event.is_action_pressed("restart") and current_level_scene != null:
		reload_level()

func load_level(level_scene: PackedScene) -> void:
	current_level_scene = level_scene
	# Remove the old level.
	for child in current_level_holder.get_children():
		child.queue_free()
	# Add the new level.
	var new_level := level_scene.instantiate()
	current_level_holder.add_child(new_level)
	level_loaded.emit(new_level)

func reload_level() -> void:
	load_level(current_level_scene)
