extends Control
## Undertale-style text box along the bottom of the screen. Signs call show_text().
## The game pauses while it's open. E shows the rest of the text, then E (or Esc) closes it.
## Designed in a 480x270 logical view and scaled to fit the viewport, like the HUD.

signal closed

const BASE_SIZE := Vector2(480, 270)
const CHARACTERS_PER_SECOND := 60.0 # How fast the text types out
const CHARACTERS_PER_BLIP := 3 # play the typing sound every few letters, not every one

@onready var screen: Control = $Screen
@onready var text_label: Label = %text_label
@onready var next_prompt: TextureRect = %next_prompt
@onready var type_sound: AudioStreamPlayer = $TypeSound

var _typed_characters := 0.0 # Counts up while typing, kept as a float so slow frame rates still type smoothly
var _characters_since_blip := 0

func _ready() -> void:
	hide()
	resized.connect(_layout)
	_layout()

# Scales the 480x270 design to fit the window and centres it.
func _layout() -> void:
	var fit := minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
	screen.scale = Vector2.ONE * fit
	screen.position = (size - BASE_SIZE * fit) / 2.0

func show_text(text: String) -> void:
	text_label.text = text
	text_label.visible_characters = 0
	_typed_characters = 0.0
	_characters_since_blip = 0
	next_prompt.hide()
	show()
	get_tree().paused = true

func close() -> void:
	hide()
	get_tree().paused = false
	closed.emit()

func _process(delta: float) -> void:
	if not visible or is_done_typing():
		return
	_typed_characters += CHARACTERS_PER_SECOND * delta
	var shown_before: int = text_label.visible_characters
	text_label.visible_characters = int(_typed_characters)
	_characters_since_blip += text_label.visible_characters - shown_before
	if _characters_since_blip >= CHARACTERS_PER_BLIP:
		_characters_since_blip -= CHARACTERS_PER_BLIP
		type_sound.play()
	if is_done_typing():
		next_prompt.show()

func is_done_typing() -> bool:
	return text_label.visible_characters >= text_label.get_total_character_count()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("main_menu"):
		# Esc closes the box instead of opening the pause menu behind it.
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if is_done_typing():
			close()
		else:
			# Skip the typing and show everything.
			text_label.visible_characters = text_label.get_total_character_count()
			next_prompt.show()
