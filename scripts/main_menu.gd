extends Control
## Title screen, also used as the pause menu
## in a level it hides the logo and background so the frozen game shows behind the buttons (darkened like the credits screen)
## designed in a 240x135 view and scaled to fit the window, like the HUD

const BASE_SIZE := Vector2(240, 135)
const BUTTONS_TOP := 67.0 # below the logo
const PAUSE_BUTTONS_TOP := 49.0 # roughly centred since there's no logo
const BUTTONS_WIDTH := 88.0 # fits OPTIONS and CREDITS
const PAUSE_BUTTONS_WIDTH := 108.0 # MAIN MENU is longer
const PAUSE_DIM_ALPHA := 0.7 # how dark the frozen game gets, same as the credits screen

@onready var screen: Control = $Screen
@onready var background: TextureRect = $Background
@onready var dim: ColorRect = $Dim
@onready var title: TextureRect = $Screen/title
@onready var buttons: VBoxContainer = %Buttons
@onready var start_button = %start_button
@onready var settings_button = %settings_button
@onready var main_menu_button = %main_menu_button
@onready var credits_button = %credits_button
@onready var exit_button = %exit_button

signal start_pressed
signal resume_pressed
signal settings_pressed
signal credits_pressed
signal quit_to_menu_pressed

var can_resume := false # True when opened from inside a level (the pause menu)
var _title_dim_alpha := 0.0 # dim strength from the scene, used on the title screen

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_title_dim_alpha = dim.color.a
	resized.connect(_layout)
	_layout()
	visibility_changed.connect(_on_visibility_changed)
	# The menu is already visible when the game boots, so focus it now as well.
	_on_visibility_changed()

# scales the 240x135 design to fit the window and centres it, the background covers the whole window
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
	var on_title_screen := not can_resume
	# the pause menu is just the buttons over the frozen game, and the only place you can leave the level from
	main_menu_button.visible = can_resume
	credits_button.visible = on_title_screen
	# exit_button.visible = on_title_screen
	background.visible = on_title_screen
	title.visible = on_title_screen
	if can_resume:
		start_button.text = "RESUME"
		dim.color.a = PAUSE_DIM_ALPHA
		buttons.position.y = PAUSE_BUTTONS_TOP
		_set_buttons_width(PAUSE_BUTTONS_WIDTH)
	else:
		start_button.text = "START"
		dim.color.a = _title_dim_alpha
		buttons.position.y = BUTTONS_TOP
		_set_buttons_width(BUTTONS_WIDTH)

# keeps the buttons centred on the 240 wide view, the pivot is in the middle so the scale doesn't shift them
func _set_buttons_width(width: float) -> void:
	buttons.offset_left = (BASE_SIZE.x - width) / 2.0
	buttons.offset_right = buttons.offset_left + width
	buttons.pivot_offset.x = width / 2.0

func _on_settings_button_pressed() -> void:
	settings_pressed.emit()

func _on_credits_button_pressed() -> void:
	credits_pressed.emit()

func _on_main_menu_button_pressed() -> void:
	quit_to_menu_pressed.emit()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_visibility_changed() -> void:
	if visible:
		start_button.grab_focus()
