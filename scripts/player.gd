extends CharacterBody2D
@onready var body: AnimatedSprite2D = $Visuals/Body
@onready var head: AnimatedSprite2D = $Visuals/Head
@onready var kickrange: Area2D = $Kickrange
@onready var kick_collider: CollisionShape2D = $Kickrange/KickCollider

enum animation_states {
	IDLE,
	MOVE,
	JUMP,
	KICK
}

var animation_state: animation_states = animation_states.IDLE

const SPEED = 300.0
const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if not is_on_floor():
		set_animation_state(animation_states.JUMP)
	elif velocity.x != 0:
		set_animation_state(animation_states.MOVE)
	else:
		set_animation_state(animation_states.IDLE)
	
func set_animation_state(new_state: animation_states) -> void:
	if animation_state == new_state:
		return
	animation_state = new_state
	
	match animation_state:
		animation_states.IDLE:
			body.play("Body_Idle")
			head.play("Head_Idle")
		animation_states.MOVE:
			body.play("Body_Walking")
			head.play("Head_Idle")
		animation_states.JUMP:
			body.play("Body_Jumping")
			head.play("Head_Idle")
		animation_states.KICK:
			body.play("Body_Kicking")
			head.play("Head_Idle")


func _on_kickrange_body_entered(body: Node2D) -> void:
	if body.is_in_group("packages"):
		print("Package can be kicked")
