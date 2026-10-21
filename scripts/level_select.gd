extends Control
## level select screen, reached from Start on the title screen
## designed in a 240x135 view and scaled to fit the window, like the title screen

const BASE_SIZE := Vector2(240, 135)

signal level_chosen(index: int)
signal back_pressed

@onready var screen: Control = $Screen
@onready var level_grid: GridContainer = %level_grid
@onready var back_button: Button = %back_button

var level_buttons: Array[Button] = []

func _ready() -> void:
	resized.connect(_layout)
	_layout()
	visibility_changed.connect(_on_visibility_changed)

# scales the 240x135 design to fit the window and centres it, the background covers the whole window
func _layout() -> void:
	var fit := minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
	screen.scale = Vector2.ONE * fit
	screen.position = (size - BASE_SIZE * fit) / 2.0

# one numbered box per level slot, slots past the available levels are grayed out and can't be pressed
func set_level_slots(available: int, total: int) -> void:
	for button in level_buttons:
		button.queue_free()
	level_buttons.clear()
	for index in total:
		var button := Button.new()
		button.text = str(index + 1)
		button.custom_minimum_size = Vector2(28, 28)
		button.add_theme_font_size_override("font_size", 16)
		if index < available:
			button.pressed.connect(level_chosen.emit.bind(index))
		else:
			button.disabled = true
		level_grid.add_child(button)
		level_buttons.append(button)

func _on_visibility_changed() -> void:
	if not visible:
		return
	# start on the first level that can be played
	for button in level_buttons:
		if not button.disabled:
			button.grab_focus()
			return
	back_button.grab_focus()

func _on_back_button_pressed() -> void:
	back_pressed.emit()
