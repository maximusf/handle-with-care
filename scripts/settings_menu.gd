extends Control

@onready var music_slider = $VBoxContainer/split_container/vbox_left/hbox_music/music_slider
@onready var sfx_slider = $VBoxContainer/split_container/vbox_left/hbox_sfx/sfx_slider
@onready var back_button = $VBoxContainer/back_button

signal back_pressed
signal zoom_changed(zoom_level: float) # Higher zoom_level means the camera is closer

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		back_button.grab_focus()

func _process(delta: float) -> void:
	pass

func _on_back_button_pressed() -> void:
	# not sure what to put here yet... (either a scene change or hide settings ui)
	print("back button pressed")
	back_pressed.emit()

func _on_music_slider_drag_ended(value_changed: bool) -> void:
	print(music_slider.value)

func _on_sfx_slider_drag_ended(value_changed: bool) -> void:
	print(sfx_slider.value)

func _on_zoom_slider_value_changed(value: float) -> void:
	zoom_changed.emit(value)
