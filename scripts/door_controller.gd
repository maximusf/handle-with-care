extends Node2D

# script handles the "door" preventing the player from progressing
# the door opens only while every trigger in the list is on

# paths to the levers and pressure plates that must all be on, if empty it uses the node named lever
@export var trigger_paths: Array[NodePath]
# the tile layer that is drawn as the door, if empty it uses the node named door_tiles
@export var door: TileMapLayer
@export var show_door_when_on := false

var triggers: Array[Node] = []

func _ready() -> void:
	for path in trigger_paths:
		triggers.append(get_node(path))
	if triggers.is_empty():
		triggers.append(get_node("../lever"))
	if door == null:
		door = get_node("../door_tiles")

	for trigger in triggers:
		if trigger.has_signal("pressed"):
			trigger.pressed.connect(_update_door)
			trigger.released.connect(_update_door)
		else:
			trigger.turned_on.connect(_update_door)
			trigger.turned_off.connect(_update_door)
	_update_door()

# a pressure plate is on while something sits on it, a lever stays on until flipped again
func _is_on(trigger: Node) -> bool:
	if trigger.has_signal("pressed"):
		return trigger.is_pressed()
	return trigger.is_on()

func _update_door() -> void:
	var all_on := true
	for trigger in triggers:
		if not _is_on(trigger):
			all_on = false
	door.enabled = (all_on == show_door_when_on)
