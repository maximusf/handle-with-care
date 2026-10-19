extends Control

# These use % (unique names) so moving them around in the layout doesn't break the script.
@onready var music_slider = %music_slider
@onready var sfx_slider = %sfx_slider
@onready var zoom_slider = %zoom_slider
@onready var music_value_label = %music_value_label
@onready var sfx_value_label = %sfx_value_label
@onready var zoom_value_label = %zoom_value_label
@onready var fullscreen_checkbox = %fullscreen_checkbox
@onready var back_button = %back_button

signal back_pressed
signal zoom_changed(zoom_level: float) # Higher zoom_level means the camera is closer

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	# Fill in the value labels with the sliders' starting values.
	_on_music_slider_value_changed(music_slider.value)
	_on_sfx_slider_value_changed(sfx_slider.value)
	zoom_value_label.text = "%.1fx" % zoom_slider.value
	fullscreen_checkbox.set_pressed_no_signal(is_fullscreen())

func _on_visibility_changed() -> void:
	if visible:
		back_button.grab_focus()

func _process(delta: float) -> void:
	pass

func _on_back_button_pressed() -> void:
	# not sure what to put here yet... (either a scene change or hide settings ui)
	print("back button pressed")
	back_pressed.emit()

func _on_music_slider_value_changed(value: float) -> void:
	set_bus_volume("Music", value)
	music_value_label.text = "%d%%" % value

func _on_sfx_slider_value_changed(value: float) -> void:
	set_bus_volume("SFX", value)
	sfx_value_label.text = "%d%%" % value

func _on_zoom_slider_value_changed(value: float) -> void:
	zoom_value_label.text = "%.1fx" % value
	zoom_changed.emit(value)

# percent goes from 0 (silent) to 100 (full volume).
func set_bus_volume(bus_name: String, percent: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(percent / 100.0))
	AudioServer.set_bus_mute(bus_index, percent == 0)

func _on_fullscreen_checkbox_toggled(enabled: bool) -> void:
	set_fullscreen(enabled)

func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func set_fullscreen(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Keep the checkbox right when fullscreen is changed with F11.
	fullscreen_checkbox.set_pressed_no_signal(enabled)

func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())
