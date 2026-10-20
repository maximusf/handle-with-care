extends Control
## Title screen, also used as the pause menu (Start becomes Resume and a Main Menu button appears).
## Designed in a 240x135 logical view and scaled to fit the window, like the HUD.

const BASE_SIZE := Vector2(240, 135)

@onready var screen: Control = $Screen
@onready var start_button = %start_button
@onready var settings_button = %settings_button
@onready var main_menu_button = %main_menu_button
@onready var exit_button = %exit_button

signal start_pressed
signal resume_pressed
signal settings_pressed
signal quit_to_menu_pressed

var can_resume := false # True when opened from inside a level (the pause menu)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resized.connect(_layout)
	_layout()
	visibility_changed.connect(_on_visibility_changed)
	# The menu is already visible when the game boots, so focus it now as well.
	_on_visibility_changed()

# Scales the 240x135 design to fit the window and centres it. The background covers the whole window.
func _layout() -> void:
	var fit := minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
	screen.scale = Vector2.ONE * fit
	screen.position = (size - BASE_SIZE * fit) / 2.0

func _on_start_button_pressed() -> void:
	if can_resume:
		resume_pressed.emit()
	else:
		start_pressed.emit()

func set_can_resume(value: bool) -> void:
	can_resume = value
	# Leaving the level is only possible from the pause menu.
	main_menu_button.visible = can_resume
	if can_resume:
		start_button.text = "RESUME"
	else:
		start_button.text = "START"

func _on_settings_button_pressed() -> void:
	settings_pressed.emit()

func _on_main_menu_button_pressed() -> void:
	quit_to_menu_pressed.emit()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_visibility_changed():
	if visible:
		start_button.grab_focus()
