extends CanvasLayer

signal start_game_requested
signal quit_to_menu_requested

@onready var main_menu = $Main_Menu
@onready var settings_menu = $Settings_Menu
@onready var winlose_menu = $WinLose_Menu
@onready var hud = $HUD

func _ready() -> void:
	main_menu.start_pressed.connect(start_game_requested.emit)
	main_menu.settings_pressed.connect(settings_menu.show)
	settings_menu.back_pressed.connect(settings_menu.hide)
	
	main_menu.show()
	settings_menu.hide()
