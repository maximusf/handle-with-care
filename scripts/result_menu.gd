extends Control
## Win / lose screen (layout A2, see assets/ui/screens/README.md).
## Designed in a 480x270 logical view and scaled to fit the viewport, like the HUD.

signal back_pressed

const BASE_SIZE := Vector2(480, 270)
const DOTS_GAP := 4.0 # Space between the leader dots and the text on either side

const COLOR_BACKDROP_WIN := Color("080808b3") # 70 percent
const COLOR_BACKDROP_LOSE := Color("3a0a10a8") # 66 percent
const COLOR_CAPTION_WIN := Color("a96b32")
const COLOR_CAPTION_LOSE := Color("bc292c")
const COLOR_DELIVERED_WIN := Color("1a8a28")
const COLOR_DELIVERED_LOSE := Color("787b7e")
const COLOR_DESTROYED := Color("bc292c")
const COLOR_TEXT := Color("080808")

@export var success_texture: Texture2D
@export var fail_texture: Texture2D

@onready var backdrop: ColorRect = $Backdrop
@onready var screen: Control = $Screen
@onready var ribbon: TextureRect = %ribbon
@onready var star_1: AnimatedSprite2D = %star_1
@onready var star_2: AnimatedSprite2D = %star_2
@onready var star_3: AnimatedSprite2D = %star_3
@onready var caption_label: Label = %caption_label
@onready var delivered_row: Control = %delivered_row
@onready var destroyed_row: Control = %destroyed_row
@onready var kicks_row: Control = %kicks_row
@onready var time_row: Control = %time_row
@onready var back_button: Button = %back_button

# User_Interface gets HUD for us
var hud : Node

func _ready() -> void:
	hide()
	resized.connect(_layout)
	_layout()

# Scales the 480x270 design to fit the window and centres it.
func _layout() -> void:
	var fit := minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
	screen.scale = Vector2.ONE * fit
	screen.position = (size - BASE_SIZE * fit) / 2.0

func _on_back_button_pressed() -> void:
	back_pressed.emit()

func show_result(success: bool) -> void:
	var stats : Dictionary = hud.get_stats() if hud else {}

	if success:
		ribbon.texture = success_texture
		backdrop.color = COLOR_BACKDROP_WIN
		caption_label.text = "CUSTOMER SATISFACTION"
		caption_label.add_theme_color_override("font_color", COLOR_CAPTION_WIN)
	else:
		ribbon.texture = fail_texture
		backdrop.color = COLOR_BACKDROP_LOSE
		caption_label.text = "CUSTOMER NOT SATISFIED"
		caption_label.add_theme_color_override("font_color", COLOR_CAPTION_LOSE)

	# One star per objective, in the same order as the HUD list.
	_set_star(star_1, success)
	_set_star(star_2, stats.get("under_time_limit", false))
	_set_star(star_3, stats.get("no_package_destroyed", false))

	var delivered_color := COLOR_DELIVERED_LOSE
	if success:
		delivered_color = COLOR_DELIVERED_WIN
	var delivered_text := "%d/%d" % [stats.get("delivered", 0), stats.get("required", 0)]
	_set_row(delivered_row, delivered_text, delivered_color)
	_set_row(destroyed_row, str(stats.get("destroyed", 0)), COLOR_DESTROYED)
	_set_row(kicks_row, str(stats.get("kicks", 0)), COLOR_TEXT)

	var seconds := floori(stats.get("time_taken", 0.0))
	_set_row(time_row, "%d:%02d" % [floori(seconds / 60.0), seconds % 60], COLOR_TEXT)

	show()
	back_button.grab_focus()

func _set_star(star: AnimatedSprite2D, earned: bool) -> void:
	if earned:
		star.play(&"full")
	else:
		star.play(&"empty")

# Sets a stat row's value and stretches its leader dots between the name and the value.
func _set_row(row: Control, value_text: String, value_color: Color) -> void:
	var name_label: Label = row.get_node("Name")
	var value_label: Label = row.get_node("Value")
	var dots: TextureRect = row.get_node("Dots")

	value_label.text = value_text
	value_label.add_theme_color_override("font_color", value_color)

	var name_right := name_label.position.x + name_label.get_minimum_size().x
	var value_left := value_label.position.x + value_label.size.x - value_label.get_minimum_size().x
	dots.position.x = name_right + DOTS_GAP
	dots.size.x = maxf(value_left - DOTS_GAP - dots.position.x, 0.0)
