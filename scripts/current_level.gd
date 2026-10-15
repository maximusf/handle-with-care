extends Node2D

signal level_completed

var delivery_zones: Array[Node] = []
var completed_zones: Array[bool] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
		

func _on_delivery_zone_completed(zone: Area2D) -> void:
	completed_zones.append(true)
	if completed_zones.size() == delivery_zones.size():
		level_completed.emit()

func _on_level_manager_level_loaded(level: Node2D) -> void:
	delivery_zones.clear()
	completed_zones.clear()
	for zone in level.find_children("*", "", true, false):
		if zone.is_in_group("delivery_zones"):
			delivery_zones.append(zone)
			zone.connect("complete", _on_delivery_zone_completed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
