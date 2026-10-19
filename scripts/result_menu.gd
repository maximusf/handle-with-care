extends Control

signal back_pressed

@export var success_texture: Texture2D
@export var fail_texture: Texture2D

@onready var ribbon: TextureRect = $CenterContainer/PanelContainer/VBoxContainer/ribbon_texture
@onready var delivered_label = $CenterContainer/PanelContainer/VBoxContainer/delivered_label
@onready var destroyed_label = $CenterContainer/PanelContainer/VBoxContainer/destroyed_label
@onready var kicks_label = $CenterContainer/PanelContainer/VBoxContainer/kicks_label
@onready var time_label = $CenterContainer/PanelContainer/VBoxContainer/time_label
@onready var time_goal_label = $CenterContainer/PanelContainer/VBoxContainer/time_goal_label
@onready var clean_goal_label = $CenterContainer/PanelContainer/VBoxContainer/clean_goal_label
@onready var back_button = $CenterContainer/PanelContainer/VBoxContainer/back_button

# User_Interface gets HUD for us
var hud : Node

func _ready() -> void:
	hide()

func _on_back_button_pressed() -> void:
	back_pressed.emit()

func show_result(success: bool) -> void:
	ribbon.texture = success_texture if success else fail_texture
	
	var stats : Dictionary = hud.get_stats() if hud else {}
	delivered_label.text = "Packages delivered: %d" % stats.get("delivered", 0)
	destroyed_label.text = "Packages destroyed: %d" % stats.get("destroyed", 0)
	kicks_label.text = "Kicks: %d" % stats.get("kicks",0)
	
	var seconds := ceili(stats.get("time_left", 0.0))
	time_label.text = "Time left: %d:%02d" % [floori(seconds / 60.0), seconds % 60]

	var minutes : int = stats.get("time_limit_minutes", 0)
	time_goal_label.text = "Under %d minutes: %s" % [minutes, _goal_text(stats.get("under_time_limit", false))]
	clean_goal_label.text = "No package destroyed: %s" % _goal_text(stats.get("no_package_destroyed", false))
	
	show()
	back_button.grab_focus()

func _goal_text(goal_done: bool) -> String:
	if goal_done:
		return "Done"
	return "Failed"
