extends Area2D
@onready var completion: AnimatedSprite2D = $Completion
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label
@onready var countdown_timer: Timer = $CountdownTimer

var packages_inside: Array[Node2D] = []
var delivered_packages: Array[Node2D] = [] # Read by the HUD to know which packages this zone accepted
var is_complete = false # Once complete, the zone is locked and ignores packages coming in or out
const REQUIRED_PACKAGES = 2

signal complete(completed_delivery)
signal incomplete(incomplete_delivery)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("packages"):
		packages_inside.append(body)
		check_delivery_status()
		print("Package Has entered zone")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("packages"):
		packages_inside.erase(body)
		check_delivery_status()
		print("Package Has left zone")

# Destroyed packages and packages already delivered to another zone don't count.
func get_deliverable_packages() -> Array[Node2D]:
	var deliverable: Array[Node2D] = []
	for package in packages_inside:
		if not package.is_destroyed and not package.is_delivered:
			deliverable.append(package)
	return deliverable

func check_delivery_status() -> void:
	if is_complete:
		return

	var deliverable_count = get_deliverable_packages().size()
	label.text = str(deliverable_count) + " / " + str(REQUIRED_PACKAGES)

	if deliverable_count >= REQUIRED_PACKAGES:
		if countdown_timer.is_stopped():
			completion.show()
			completion.play("Timer")
			countdown_timer.start()
	else:
		incomplete.emit(self)
		countdown_timer.stop()
		completion.stop()
		completion.hide()

func _on_countdown_timer_timeout() -> void:
	# Check again, a package may have been destroyed during the countdown.
	var deliverable = get_deliverable_packages()
	if deliverable.size() >= REQUIRED_PACKAGES:
		is_complete = true
		for package in deliverable:
			package.is_delivered = true
			delivered_packages.append(package)
		completion.play("Completion")
		complete.emit(self)
	else:
		completion.play("Failed")
