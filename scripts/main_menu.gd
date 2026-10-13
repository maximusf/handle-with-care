extends Control

@onready var start_button = $CenterContainer/VBoxContainer/start_button
@onready var settings_button = $CenterContainer/VBoxContainer/settings_button
@onready var exit_button = $CenterContainer/VBoxContainer/exit_button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_button_pressed() -> void:
	print('start pressed')
	# This works for now (but the emit approach might be better to work with in level manager
	
	get_tree().change_scene_to_file("res://scenes/level_manager.tscn")
	#start_pressed.emit() # maybe need to change to this when pressed 
	# May need to add some more code to make animated sprites to work for all of these
	


func _on_settings_button_pressed() -> void:
	print('settings pressed')
	#get_tree().change_scene_to_file()
	#settings_pressed.emit()


func _on_exit_button_pressed() -> void:
	print('exit pressed')
	get_tree().quit()
