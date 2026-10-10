extends Area2D
@onready var completion: AnimatedSprite2D = $Completion
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label
@onready var countdown_timer: Timer = $CountdownTimer

var num_packages = 0
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
		num_packages += 1
		check_delivery_status() 
		label.text = str(num_packages) + " / " + str(REQUIRED_PACKAGES)
		print("Package Has entered zone")
	
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("packages"):
		num_packages -= 1
		check_delivery_status() 
		label.text = str(num_packages)  + " / " + str(REQUIRED_PACKAGES)
		print("Package Has left zone")
	pass # Replace with function bod
	
func check_delivery_status() -> void:
	if num_packages == REQUIRED_PACKAGES:
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
	if num_packages == REQUIRED_PACKAGES:
		completion.play("Completion")
		complete.emit(self)
		print("Done")
	else:
		completion.play("Failed")
	pass # Replace with function body.
