extends CanvasLayer

signal start_game_requested
signal quit_to_menu_requested
signal retry_requested

const CURSOR := preload("res://assets/ui/cursor_2x.png")

# Drag a different track onto these in the Inspector to change the music.
@export var title_music: AudioStream # Plays on the title screen
@export var level_music: AudioStream # Plays in levels, including the pause menu and result screen

@onready var main_menu = $Main_Menu
@onready var settings_menu = $Settings_Menu
@onready var result_menu = $Result_Menu
@onready var hud = $HUD
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var music: AudioStreamPlayer = $Music

func _ready() -> void:
	Input.set_custom_mouse_cursor(CURSOR)
	play_music(title_music)
	main_menu.settings_pressed.connect(show_settings)
	settings_menu.back_pressed.connect(close_settings)
	
	main_menu.start_pressed.connect(start_game_requested.emit)
	main_menu.resume_pressed.connect(resume_game)
	main_menu.quit_to_menu_pressed.connect(quit_to_menu_requested.emit)
	result_menu.back_pressed.connect(quit_to_menu_requested.emit)
	result_menu.retry_pressed.connect(retry_requested.emit)
	result_menu.hud = hud
	hud.level_finished.connect(show_result)
	close_settings()
	# Every button and checkbox in the menus clicks when pressed.
	for button in find_children("*", "BaseButton", true, false):
		button.pressed.connect(click_sound.play)

func _exit_tree() -> void:
	# Release the cursor and stop the music before shutdown, otherwise Godot reports them as leaked.
	Input.set_custom_mouse_cursor(null)
	music.stop()
	music.stream = null
	title_music = null
	level_music = null

func _hide_all() -> void:
	main_menu.hide()
	settings_menu.hide()
	result_menu.hide()
	hud.hide()

func _unhandled_input(event: InputEvent) -> void:
	# F11 works everywhere: menus, paused, or in a level.
	if event.is_action_pressed("toggle_fullscreen"):
		settings_menu.toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return

	if not event.is_action_pressed("main_menu"):
		return

	if settings_menu.visible:
		close_settings()
	elif hud.visible:
		# The HUD is only visible while playing a level.
		show_pause_menu()
	elif main_menu.visible and main_menu.can_resume:
		resume_game()
	else:
		return
	get_viewport().set_input_as_handled()

# Starts a track, unless it's already the one playing (so menus don't restart the music).
func play_music(stream: AudioStream) -> void:
	if music.stream == stream and music.playing:
		return
	music.stream = stream
	music.play()

func show_main_menu() -> void:
	play_music(title_music)
	_hide_all()
	main_menu.set_can_resume(false)
	main_menu.show()

func show_pause_menu() -> void:
	get_tree().paused = true
	_hide_all()
	main_menu.set_can_resume(true)
	main_menu.show()

func resume_game() -> void:
	show_hud()
	get_tree().paused = false

func show_settings() -> void: 
	settings_menu.show()

func close_settings() -> void:
	settings_menu.hide()
	# Give keyboard focus back to the menu underneath.
	if main_menu.visible:
		main_menu.start_button.grab_focus()

func show_hud() -> void:
	play_music(level_music)
	_hide_all()
	hud.show()

func show_result(won: bool) -> void:
	# Pause the level so the player can't keep moving or kicking behind the result screen.
	get_tree().paused = true
	result_menu.show_result(won)
	# The HUD is drawn above the result screen, so hide it.
	hud.hide()
