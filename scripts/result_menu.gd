extends Control

signal back_pressed

@export var success_texture: Texture2D
@export var fail_texture: Texture2D

@onready var ribbon: TextureRect = $CenterContainer/PanelContainer/VBoxContainer/ribbon_texture
@onready var delivered_label = $CenterContainer/PanelContainer/VBoxContainer/delivered_label
@onready var destroyed_label = $CenterContainer/PanelContainer/VBoxContainer/destroyed_label
@onready var kicks_label = $CenterContainer/PanelContainer/VBoxContainer/kicks_label
@onready var time_label = $CenterContainer/PanelContainer/VBoxContainer/time_label

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
	
	show()
