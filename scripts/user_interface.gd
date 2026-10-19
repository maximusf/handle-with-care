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
	result_menu.back_pressed.connect(quit_to_menu_requested.emit)
	result_menu.hud = hud
	hud.level_finished.connect(show_result)
	close_settings()

func _hide_all() -> void:
	main_menu.hide()
	settings_menu.hide()
	result_menu.hide()
	hud.hide()

func show_main_menu() -> void:
	_hide_all()
	main_menu.show()

func show_settings() -> void: 
	settings_menu.show()

func close_settings() -> void:
	settings_menu.hide()

func show_hud() -> void:
	_hide_all()
	hud.show()

func show_result(won: bool) -> void:
	# Pause the level so the player can't keep moving or kicking behind the result screen.
	get_tree().paused = true
	result_menu.show_result(won)
	# The HUD is drawn above the result screen, so hide it.
	hud.hide()
