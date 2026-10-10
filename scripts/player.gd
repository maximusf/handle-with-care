extends CharacterBody2D
@onready var body: AnimatedSprite2D = $Visuals/Body
@onready var head: AnimatedSprite2D = $Visuals/Head
@onready var power_arrow: AnimatedSprite2D = $Visuals/PowerArrow
@onready var kickrange: Area2D = $Kickrange
@onready var kick_collider: CollisionShape2D = $Kickrange/KickCollider
@onready var visuals: Node2D = $Visuals

@onready var walking_sfx: AudioStreamPlayer2D = $SFX/WalkingSFX
@onready var jump_sfx: AudioStreamPlayer2D = $SFX/JumpSFX
@onready var kick_sfx: AudioStreamPlayer2D = $SFX/KickSFX
@onready var arrow_sfx: AudioStreamPlayer2D = $SFX/ArrowSFX


enum animation_states {
	IDLE,
	MOVE,
	JUMP,
	KICK
}

var animation_state: animation_states = animation_states.IDLE

var kickable_package: RigidBody2D = null
var kick_power: float = 100.0
var is_kicking: bool = false
var kick_animation_playing: bool = false
var arrow_sfx_counter: int = 0
const MAX_KICK_POWER: float = 2200.0
const CHARGE_SPEED = 300.0

const SPEED = 300.0
const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:
	var kick_direction = (get_global_mouse_position() - global_position).normalized()
	var kick_percentage = (kick_power / MAX_KICK_POWER) * 100
	power_arrow.rotation = kick_direction.angle()
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		head.scale.x = sign(direction)
		body.scale.x = sign(direction)
		kick_collider.position.x = (abs(kick_collider.position.x)) * sign(direction)
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	
	# Handle Kicking ------------------------------------------------------
	if Input.is_action_just_pressed("kick"):
		power_arrow.play("20")
		power_arrow.scale = Vector2(0.09, 0.07)
		power_arrow.visible = true
		is_kicking = true
		
	if is_kicking and Input.is_action_just_pressed("cancel_kick"):
		power_arrow.visible = false
		is_kicking = false
		kick_power = 100
	elif Input.is_action_pressed("kick"):
		kick_power += CHARGE_SPEED * delta
		kick_power = min(kick_power, MAX_KICK_POWER)
		
	if Input.is_action_just_released("kick") and is_kicking:
		kick_animation_playing = true
		power_arrow.visible = false
		set_animation_state(animation_states.KICK)
		await body.animation_finished
		if kickable_package != null:
			kickable_package.get_kicked(kick_direction, kick_power)
		kick_animation_playing = false
		arrow_sfx_counter = 0
		kick_power = 100
	#-----------------------------------------------------------------------
	
	# Player Animations
	if not is_on_floor():
		set_animation_state(animation_states.JUMP)
	elif velocity.x != 0:
		set_animation_state(animation_states.MOVE)
	elif kick_animation_playing:
		return
	else:
		set_animation_state(animation_states.IDLE)
		
	# Arrow Animation
	if kick_percentage >= 100:
		power_arrow.play("100")
		power_arrow.scale = Vector2(0.25, 0.20)
		if (arrow_sfx_counter == 4):
			arrow_sfx_counter = 5
			arrow_sfx.pitch_scale = 4.0
			arrow_sfx.play()
	elif kick_percentage >= 80:
		power_arrow.play("80")
		power_arrow.scale = Vector2(0.16, 0.13)
		if (arrow_sfx_counter == 3):
			arrow_sfx_counter = 4
			arrow_sfx.pitch_scale = 3.0
			arrow_sfx.play()
	elif kick_percentage >= 60:
		power_arrow.play("60")
		power_arrow.scale = Vector2(0.12, 0.09)
		if (arrow_sfx_counter == 2):
			arrow_sfx_counter = 3
			arrow_sfx.pitch_scale = 2.5
			arrow_sfx.play()
	elif kick_percentage >= 40:
		power_arrow.play("40")
		power_arrow.scale = Vector2(0.1, 0.08)
		if (arrow_sfx_counter == 1):
			arrow_sfx_counter = 2
			arrow_sfx.pitch_scale = 2.0
			arrow_sfx.play()
	else:
		power_arrow.play("20")
		power_arrow.position = get_local_mouse_position()
		power_arrow.scale = Vector2(0.09, 0.07)
		if (arrow_sfx_counter == 0):
			arrow_sfx_counter = 1
			arrow_sfx.pitch_scale = 1.0
			arrow_sfx.play()
	
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
			walking_sfx.play()
			head.play("Head_Idle")
		animation_states.JUMP:
			body.play("Body_Jumping")
			jump_sfx.play()
			head.play("Head_Idle")
		animation_states.KICK:
			body.play("Body_Kicking")
			kick_sfx.play()
			head.play("Head_Idle")


func _on_kickrange_body_entered(body: Node2D) -> void:
	if body.is_in_group("packages"):
		kickable_package = body
		print("Package can be kicked")
		
func _on_kickrange_body_exited(body: Node2D) -> void:
	if body.is_in_group("packages"):
		kickable_package = null
		print("Package out of range")
	pass # Replace with function body.
