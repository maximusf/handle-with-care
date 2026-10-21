extends Control
## credits screen, reached from the title screen
## designed in a 240x135 view and scaled to fit the window, like the title screen

const BASE_SIZE := Vector2(240, 135)

signal back_pressed

@onready var screen: Control = $Screen
@onready var back_button: Button = %back_button

func _ready() -> void:
	resized.connect(_layout)
	_layout()
	visibility_changed.connect(_on_visibility_changed)

# scales the 240x135 design to fit the window and centres it, the background covers the whole window
func _layout() -> void:
	var fit := minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
	screen.scale = Vector2.ONE * fit
	screen.position = (size - BASE_SIZE * fit) / 2.0

func _on_visibility_changed() -> void:
	if visible:
		back_button.grab_focus()

func _on_back_button_pressed() -> void:
	back_pressed.emit()
