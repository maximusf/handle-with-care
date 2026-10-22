extends Node2D

# script handles the "door" preventing the player from progressing

@onready var lever: Node = $"../lever"
@onready var door: TileMapLayer = $"../door_tiles"
@export var show_door_when_on := false

func _ready() -> void:
	lever.turned_on.connect(_set_on.bind(true))
	lever.turned_off.connect(_set_on.bind(false))
	_set_on(lever.is_on())

func _set_on(on : bool) -> void:
	door.enabled = (on == show_door_when_on)
