extends Control
## In-level HUD (layout A, see assets/ui/screens/README.md).
## Designed in a 480x270 logical view and scaled to fit the viewport.
## Level_Manager calls bind_level() every time a level is loaded.

const BASE_SIZE := Vector2(480, 270)
const TRAY_HEIGHT := 26.0
const HINT_SIZE := Vector2(78, 16)
const SCREEN_MARGIN := Vector2(6, 4) # Gap to the screen edge: x for left/right, y for bottom

const SLOT_FRAMES := preload("res://assets/ui/screens/hud_package_slot.tres")
const SLOT_PITCH := 22.0
const SLOT_OFFSET := Vector2(4, 3)
const TRAY_PADDING := 8.0

const COLOR_MAIN := Color("fafafa")
const COLOR_OPTIONAL := Color("ffd23f")
const COLOR_FAILED := Color("d0686c")
const COLOR_DELIVERED := Color("3ddc4b")
const COLOR_TIMER := Color("c3c3bd")

enum Slot { WAITING, ACTIVE, DELIVERED, LOST }
const SLOT_ANIMS: Array[StringName] = [&"waiting", &"active", &"delivered", &"lost"]

enum Goal { PENDING, DONE, FAILED }
const GOAL_ANIMS: Array[StringName] = [&"pending", &"done", &"failed"]

signal level_finished(won: bool) # Emitted once per level, when the main goal is done or can no longer be done

@export var time_limit: float = 300.0 # Seconds for the optional "under N minutes" objective

@onready var objectives: Control = $Objectives
@onready var main_row: Control = $Objectives/MainRow
@onready var time_row: Control = $Objectives/TimeRow
@onready var clean_row: Control = $Objectives/CleanRow
@onready var tray: Control = $PackageTray
@onready var tray_panel: NinePatchRect = $PackageTray/Panel
@onready var slots: Control = $PackageTray/Slots
@onready var restart_hint: Control = $RestartHint

var _packages: Array[Node] = []
var _zones: Array[Node] = []
var _slot_states: Array[int] = [] # One entry per package, same order as _packages
var _active := 0 # Index of the package the player is currently working with
var _required := 0 # Packages that must be delivered to finish the level
var _elapsed := 0.0
var _running := false
var _time_failed := false
var _package_destroyed := false
var _won := false
var _shown_seconds := -1
var _kicks := 0


func _ready() -> void:
	resized.connect(_layout)
	_layout()
	main_row.get_node("Text").text = "DELIVER PACKAGES"
	time_row.get_node("Text").text = "UNDER %d MINUTES" % roundi(time_limit / 60.0)
	clean_row.get_node("Text").text = "NO PACKAGE DESTROYED"
	_reset()


func _process(delta: float) -> void:
	# This node keeps processing while the tree is paused, so check for that here.
	if not _running or _time_failed or get_tree().paused or not is_visible_in_tree():
		return
	_elapsed += delta
	if _elapsed >= time_limit:
		_elapsed = time_limit
		_time_failed = true
		_refresh_goals()
	_refresh_time()


## Hooks the HUD up to the packages and delivery zones of a freshly loaded level.
func bind_level(level: Node) -> void:
	_unbind()
	_packages.assign(get_tree().get_nodes_in_group(&"packages").filter(level.is_ancestor_of))
	_zones.assign(get_tree().get_nodes_in_group(&"delivery_zones").filter(level.is_ancestor_of))

	for package in _packages:
		package.kicked.connect(_on_package_kicked)
		package.destroy.connect(_on_package_destroyed)
	for zone in _zones:
		zone.complete.connect(_on_zone_complete)
		_required += zone.REQUIRED_PACKAGES
	if _zones.is_empty():
		_required = _packages.size()

	_slot_states.resize(_packages.size())
	_slot_states.fill(Slot.WAITING)
	_build_slots()
	_running = true
	_refresh_slots()
	_refresh_goals()
	_refresh_time()


func _unbind() -> void:
	for package in _packages:
		if is_instance_valid(package):
			package.kicked.disconnect(_on_package_kicked)
			package.destroy.disconnect(_on_package_destroyed)
	for zone in _zones:
		if is_instance_valid(zone):
			zone.complete.disconnect(_on_zone_complete)
	_reset()


func _reset() -> void:
	_packages.clear()
	_zones.clear()
	_slot_states.clear()
	_active = 0
	_required = 0
	_elapsed = 0.0
	_running = false
	_time_failed = false
	_package_destroyed = false
	_won = false
	_build_slots()
	_refresh_goals()
	_refresh_time()
	_kicks = 0


# Layout -------------------------------------------------------------------

func _layout() -> void:
	var fit := minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
	for block: Control in [objectives, tray, restart_hint]:
		block.scale = Vector2.ONE * fit
	objectives.position = SCREEN_MARGIN * fit
	tray.position = Vector2(SCREEN_MARGIN.x, size.y / fit - SCREEN_MARGIN.y - TRAY_HEIGHT) * fit
	restart_hint.position = (size / fit - SCREEN_MARGIN - HINT_SIZE) * fit


func _build_slots() -> void:
	for slot in slots.get_children():
		slots.remove_child(slot)
		slot.queue_free()
	for i in _packages.size():
		var slot := AnimatedSprite2D.new()
		slot.sprite_frames = SLOT_FRAMES
		slot.centered = false
		slot.position = SLOT_OFFSET + Vector2(i * SLOT_PITCH, 0)
		slots.add_child(slot)
	tray.visible = not _packages.is_empty()
	tray_panel.size = Vector2(TRAY_PADDING + _packages.size() * SLOT_PITCH, TRAY_HEIGHT)


# Packages -----------------------------------------------------------------

func _on_package_kicked(package: Node) -> void:
	_kicks += 1
	var index := _packages.find(package)
	if index != -1 and _slot_states[index] == Slot.WAITING:
		_active = index
	_refresh_slots()


func _on_package_destroyed(package: Node) -> void:
	# The kick that destroys a package sends "destroy" instead of "kicked", so count it here.
	_kicks += 1
	var index := _packages.find(package)
	if index != -1:
		_slot_states[index] = Slot.LOST
	_package_destroyed = true
	_refresh_slots()
	_refresh_goals()


func _on_zone_complete(zone: Node) -> void:
	for package in zone.delivered_packages:
		var index := _packages.find(package)
		if index != -1 and _slot_states[index] == Slot.WAITING:
			_slot_states[index] = Slot.DELIVERED
	_refresh_slots()
	_refresh_goals()


func _refresh_slots() -> void:
	# Once the active package is delivered or lost, the next unresolved one takes over.
	if _active >= _slot_states.size() or _slot_states[_active] != Slot.WAITING:
		var next := _slot_states.find(Slot.WAITING)
		if next != -1:
			_active = next
	for i in slots.get_child_count():
		var state: int = _slot_states[i]
		if state == Slot.WAITING and i == _active:
			state = Slot.ACTIVE
		(slots.get_child(i) as AnimatedSprite2D).play(SLOT_ANIMS[state])


# Objectives ---------------------------------------------------------------

func _refresh_goals() -> void:
	var delivered := _slot_states.count(Slot.DELIVERED)
	var waiting := _slot_states.count(Slot.WAITING)

	var main_goal := Goal.PENDING
	if _all_zones_complete():
		main_goal = Goal.DONE
	elif waiting < _packages_still_needed():
		main_goal = Goal.FAILED
	_won = main_goal == Goal.DONE

	# Stop the clock and report the result only once.
	var level_just_ended := _running and main_goal != Goal.PENDING
	if level_just_ended:
		_running = false
		level_finished.emit(_won)

	_set_row(main_row, main_goal, COLOR_MAIN)
	main_row.get_node("Count").text = "%d/%d" % [delivered, _required]
	main_row.get_node("Count").add_theme_color_override("font_color", COLOR_DELIVERED)

	var time_goal := Goal.PENDING
	if _time_failed:
		time_goal = Goal.FAILED
	elif _won:
		time_goal = Goal.DONE
	_set_row(time_row, time_goal, COLOR_OPTIONAL)

	var clean_goal := Goal.PENDING
	if _package_destroyed:
		clean_goal = Goal.FAILED
	elif _won:
		clean_goal = Goal.DONE
	_set_row(clean_row, clean_goal, COLOR_OPTIONAL)


func _all_zones_complete() -> bool:
	if _zones.is_empty():
		return false
	for zone in _zones:
		if not zone.is_complete:
			return false
	return true


func _packages_still_needed() -> int:
	var needed := 0
	for zone in _zones:
		if not zone.is_complete:
			needed += zone.REQUIRED_PACKAGES
	return needed


func _refresh_time() -> void:
	var seconds := ceili(time_limit - _elapsed)
	if seconds == _shown_seconds:
		return
	_shown_seconds = seconds
	var count: Label = time_row.get_node("Count")
	count.text = "%d:%02d" % [floori(seconds / 60.0), seconds % 60]
	count.add_theme_color_override("font_color", COLOR_TIMER)


func _set_row(row: Control, goal: Goal, color: Color) -> void:
	(row.get_node("Bullet") as AnimatedSprite2D).play(GOAL_ANIMS[goal])
	row.get_node("Text").add_theme_color_override("font_color", COLOR_FAILED if goal == Goal.FAILED else color)

func get_stats() -> Dictionary:
	return {
		"delivered" : _slot_states.count(Slot.DELIVERED),
		"destroyed" : _slot_states.count(Slot.LOST),
		"kicks" : _kicks,
		"time_left" : maxf( time_limit - _elapsed, 0.0)
	}
