extends Area2D
## A sign the player reads by standing next to it and pressing E.
## Place it with its origin on the floor; the text opens in the dialogue box.

@export_multiline var text := ""

@onready var prompt: Sprite2D = $Prompt

var _player_nearby := false

func _ready() -> void:
	# Only the player is on the layer this area watches, so any body here is the player.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.hide()

func _on_body_entered(_body: Node2D) -> void:
	_player_nearby = true
	prompt.show()

func _on_body_exited(_body: Node2D) -> void:
	_player_nearby = false
	prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
		dialogue_box.show_text(text)
