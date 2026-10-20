extends Area2D
## Speech bubble over an NPC. Fades in while the player is close and fades out shortly after they walk away.
## Place the origin just above the NPC's head; the bubble sits above that point.

@export_multiline var text := ""
@export var speaker := ""
@export var bubble_offset := Vector2.ZERO # Nudge the bubble if it covers something important, like a delivery zone

const FADE_TIME := 0.2

@onready var bubble: PanelContainer = $Bubble
@onready var text_label: Label = %text_label
@onready var speaker_label: Label = %speaker_label
@onready var hide_timer: Timer = $HideTimer

func _ready() -> void:
	text_label.text = text
	speaker_label.text = "- " + speaker
	bubble.modulate.a = 0.0
	# Only the player is on the layer this area watches, so any body here is the player.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	_place_bubble.call_deferred()

# The bubble's size depends on its text, so position it once the size is known.
func _place_bubble() -> void:
	bubble.reset_size()
	bubble.position = Vector2(-bubble.size.x / 2.0, -bubble.size.y) + bubble_offset

func _on_body_entered(_body: Node2D) -> void:
	hide_timer.stop()
	_fade_bubble_to(1.0)

func _on_body_exited(_body: Node2D) -> void:
	hide_timer.start()

func _on_hide_timer_timeout() -> void:
	_fade_bubble_to(0.0)

func _fade_bubble_to(alpha: float) -> void:
	create_tween().tween_property(bubble, "modulate:a", alpha, FADE_TIME)
