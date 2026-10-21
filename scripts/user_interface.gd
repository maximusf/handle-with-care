extends CanvasLayer

signal start_game_requested(level_index: int)
signal quit_to_menu_requested
signal level_select_requested # from the result screen's back button
signal retry_requested

# Drag a different track onto these in the Inspector to change the music
@export var title_music: AudioStream # plays on the title screen
@export var level_music: AudioStream # plays in levels, including the pause menu and result screen

@onready var main_menu = $Main_Menu
@onready var level_select = $Level_Select
@onready var credits_menu = $Credits_Menu
@onready var settings_menu = $Settings_Menu
@onready var result_menu = $Result_Menu
@onready var hud = $HUD
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var music: AudioStreamPlayer = $Music

func _ready() -> void:
	play_music(title_music)
	main_menu.settings_pressed.connect(show_settings)
	main_menu.credits_pressed.connect(show_credits)
	credits_menu.back_pressed.connect(show_main_menu)
	settings_menu.back_pressed.connect(close_settings)
	
	main_menu.start_pressed.connect(show_level_select)
	level_select.level_chosen.connect(start_game_requested.emit)
	level_select.back_pressed.connect(show_main_menu)
	main_menu.resume_pressed.connect(resume_game)
	main_menu.quit_to_menu_pressed.connect(quit_to_menu_requested.emit)
	result_menu.back_pressed.connect(level_select_requested.emit)
	result_menu.retry_pressed.connect(retry_requested.emit)
	result_menu.hud = hud
	hud.level_finished.connect(show_result)
	close_settings()
	# every button and checkbox in the menus clicks when pressed
	for button in find_children("*", "BaseButton", true, false):
		button.pressed.connect(click_sound.play)

func _exit_tree() -> void:
	# stop the music before shutdown or godot reports it as leaked
	music.stop()
	music.stream = null
	title_music = null
	level_music = null

func _hide_all() -> void:
	main_menu.hide()
	level_select.hide()
	credits_menu.hide()
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
	elif level_select.visible or credits_menu.visible:
		show_main_menu()
	elif hud.visible:
		# The HUD is only visible while playing a level.
		show_pause_menu()
	elif main_menu.visible and main_menu.can_resume:
		resume_game()
	else:
		return
	get_viewport().set_input_as_handled()

# Starts a track unless it's already playing, so menus don't restart the music
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

# fills the level select screen, the level manager owns the levels so it says how many can be played and how many boxes to show
func set_level_slots(available: int, total: int) -> void:
	level_select.set_level_slots(available, total)
	for button in level_select.level_buttons:
		if not button.disabled:
			button.pressed.connect(click_sound.play)

func show_credits() -> void:
	_hide_all()
	credits_menu.show()

func show_level_select() -> void:
	_hide_all()
	level_select.show()

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
