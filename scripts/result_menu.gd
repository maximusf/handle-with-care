extends Control

signal back_pressed

@export var success_texture: Texture2D
@export var fail_texture: Texture2D
@onready var ribbon: TextureRect

var hud : Node

func _on_back_button_pressed() -> void:
	back_pressed.emit()

func _show_result(success: bool) -> void:
	pass

func _present(success: bool) -> void:
	
	var stats : Dictionary = hud.get_stats() if hud else {}
	
	
