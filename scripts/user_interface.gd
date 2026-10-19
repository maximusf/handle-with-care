extends CanvasLayer

signal start_game_requested
signal quit_to_menu_requested

@onready var main_menu = $Main_Menu
@onready var settings_menu = $Settings_Menu
@onready var result_menu = $Result_Menu
@onready var hud = $HUD

func _ready() -> void:
	main_menu.settings_pressed.connect(show_settings)
	settings_menu.back_pressed.connect(close_settings)
	
	main_menu.start_pressed.connect(start_game_requested.emit)
	main_menu.resume_pressed.connect(resume_game)
	result_menu.back_pressed.connect(quit_to_menu_requested.emit)
	result_menu.hud = hud
	hud.level_finished.connect(show_result)
	close_settings()

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

func show_main_menu() -> void:
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
	_hide_all()
	hud.show()

func show_result(won: bool) -> void:
	# Pause the level so the player can't keep moving or kicking behind the result screen.
	get_tree().paused = true
	result_menu.show_result(won)
	# The HUD is drawn above the result screen, so hide it.
	hud.hide()
