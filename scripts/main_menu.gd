extends Control

@onready var start_button = $CenterContainer/VBoxContainer/start_button
@onready var settings_button = $CenterContainer/VBoxContainer/settings_button
@onready var exit_button = $CenterContainer/VBoxContainer/exit_button

signal start_pressed
signal settings_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_start_button_pressed() -> void:
	print('start pressed')
	# This works for now (but the emit approach might be better to work with in level manager
	# get_tree().change_scene_to_file("res://scenes/level_manager.tscn")
	start_pressed.emit()
	# May need to add some more code to make animated sprites to work for all of these
	

func _on_settings_button_pressed() -> void:
	print('settings pressed')
	#get_tree().change_scene_to_file("res://scenes/Settings_Menu.tscn")
	settings_pressed.emit()

func _on_exit_button_pressed() -> void:
	print('exit pressed')
	get_tree().quit()

func _on_visibility_changed(): 
	if visible:
		start_button.grab_focus()
