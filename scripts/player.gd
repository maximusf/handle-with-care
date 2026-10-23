extends CharacterBody2D
@onready var body: AnimatedSprite2D = $Visuals/Body
@onready var head: AnimatedSprite2D = $Visuals/Head
@onready var power_arrow: AnimatedSprite2D = $Visuals/PowerArrow
@onready var kickrange: Area2D = $Kickrange
@onready var kick_collider: CollisionShape2D = $Kickrange/KickCollider
@onready var visuals: Node2D = $Visuals

@onready var step_timer: Timer = $SFX/Step_Timer
@onready var walking_sfx: AudioStreamPlayer2D = $SFX/WalkingSFX
@onready var jump_sfx: AudioStreamPlayer2D = $SFX/JumpSFX
@onready var kick_sfx: AudioStreamPlayer2D = $SFX/KickSFX
@onready var impact_sfx: AudioStreamPlayer2D = $SFX/ImpactSFX # only plays when a kick hits something
@onready var arrow_sfx: AudioStreamPlayer2D = $SFX/ArrowSFX


enum animation_states {
	IDLE,
	MOVE,
	JUMP,
	KICK
}

var animation_state: animation_states = animation_states.IDLE

var kick_power: float = 100.0
var is_kicking: bool = false
var kick_animation_playing: bool = false
var arrow_sfx_counter: int = 0
const MAX_KICK_POWER: float = 2200.0
const CHARGE_SPEED = 300.0
const AIM_RADIUS = 40.0 # The arrow's tail sits on a ring this far from the player, pointing at the cursor
# How see-through the aim arrow is when not charging a kick (stronger when a kick would hit a package)
const AIM_OUT_OF_RANGE_ALPHA = 0.2
const AIM_IN_RANGE_ALPHA = 0.35

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
# Tallest step the player walks up on their own. Lower than a package (27px) so they can't walk onto one.
const STEP_HEIGHT = 17.0
# how fast the sprites glide to catch up with the body after a stair step
# same as walking speed so 45 degree stairs look like one smooth diagonal
const STAIR_GLIDE_SPEED = 300.0
# Only show the jump animation when clearly moving up or down, so small drops (like settling onto a step) don't flash it.
const AIR_ANIMATION_MIN_SPEED = 50.0


# when on, the player stands on and bumps into signs marked solid for the player
# packages stay walk through
@export var collides_with_signs := false

# extra physics layer a solid sign sits on, see kickable_sign.gd
const SOLID_SIGN_LAYER_BIT := 8

func _ready() -> void:
	# Stick to the ground when walking down steps, instead of falling off each one.
	floor_snap_length = STEP_HEIGHT
	if collides_with_signs:
		collision_mask |= SOLID_SIGN_LAYER_BIT


func _physics_process(delta: float) -> void:
	var kick_direction = (get_global_mouse_position() - global_position).normalized()
	var kick_percentage = (kick_power / MAX_KICK_POWER) * 100
	power_arrow.rotation = kick_direction.angle()
	# undo the stair glide offset so the arrow stays centred on the body
	power_arrow.position = kick_direction * AIM_RADIUS - visuals.position
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump_sfx.play()
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
	var was_on_floor := is_on_floor()
	var height_before := global_position.y
	var stepped_up := step_up_if_blocked(delta)
	move_and_slide()
	update_footsteps() # Used to start and stop footstep timer
	
	smooth_stair_steps(was_on_floor, stepped_up, height_before, delta)
	
	# Handle Kicking ------------------------------------------------------
	# Ignore new kicks until the current kick animation is done, otherwise both kicks land at once.
	if Input.is_action_just_pressed("kick") and not kick_animation_playing:
		arrow_sfx_counter = -1
		power_arrow.play("20")
		power_arrow.scale = Vector2(0.09, 0.07)
		is_kicking = true
		
	if is_kicking and Input.is_action_just_pressed("cancel_kick"):
		is_kicking = false
		kick_power = 100
	elif is_kicking and Input.is_action_pressed("kick"): # Only charge if the kick wasn't cancelled
		kick_power += CHARGE_SPEED * delta
		kick_power = min(kick_power, MAX_KICK_POWER)
	
	update_power_arrow_visibility()
		
	if Input.is_action_just_released("kick") and is_kicking:
		is_kicking = false
		kick_animation_playing = true
		power_arrow.visible = false
		set_animation_state(animation_states.KICK)
		await body.animation_finished
		var kickable_package := get_kickable_package()
		if kickable_package != null:
			impact_sfx.play()
			kickable_package.get_kicked(kick_direction, kick_power)
		kick_animation_playing = false
		kick_power = 100
	#-----------------------------------------------------------------------
	
	# Player Animations
	# Let the kick animation finish first. If walking or jumping replaced it,
	# "animation_finished" would never fire and the kick would get stuck.
	if kick_animation_playing:
		return
	elif not is_on_floor() and absf(velocity.y) > AIR_ANIMATION_MIN_SPEED:
		set_animation_state(animation_states.JUMP)
	elif velocity.x != 0:
		set_animation_state(animation_states.MOVE)
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
			arrow_sfx.pitch_scale = 3.5
			arrow_sfx.play()
	elif kick_percentage >= 60:
		power_arrow.play("60")
		power_arrow.scale = Vector2(0.12, 0.09)
		if (arrow_sfx_counter == 2):
			arrow_sfx_counter = 3
			arrow_sfx.pitch_scale = 3.0
			arrow_sfx.play()
	elif kick_percentage >= 40:
		power_arrow.play("40")
		power_arrow.scale = Vector2(0.1, 0.08)
		if (arrow_sfx_counter == 1):
			arrow_sfx_counter = 2
			arrow_sfx.pitch_scale = 2.5
			arrow_sfx.play()
	elif kick_percentage >= 20:
		power_arrow.play("20")
		power_arrow.scale = Vector2(0.09, 0.07)
		if (arrow_sfx_counter == 0):
			arrow_sfx_counter = 1
			arrow_sfx.pitch_scale = 2.0
			arrow_sfx.play()
	else:
		power_arrow.play("10")
		power_arrow.scale = Vector2(0.04, 0.04)
		if (arrow_sfx_counter == -1):
			arrow_sfx_counter = 0
			arrow_sfx.pitch_scale = 1.5
			arrow_sfx.play()
	
func update_footsteps() -> void:
	var is_walking := is_on_floor() and absf(velocity.x) > 1.0

	if is_walking and step_timer.is_stopped():
		walking_sfx.play()
		step_timer.start()
	elif not is_walking:
		step_timer.stop()
	
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
			kick_sfx.play()
			head.play("Head_Idle")


# Stairs move the body in 16px pops (up by step-up, down by floor snap)
# shift the sprites back by the pop and let them glide to catch up so climbing looks smooth
func smooth_stair_steps(was_on_floor: bool, stepped_up: bool, height_before: float, delta: float) -> void:
	# a step-up can leave the body a pixel above the step for a frame, so count it even when not on the floor yet
	var walked_over_a_step := stepped_up or (was_on_floor and is_on_floor())
	if walked_over_a_step:
		var height_change := global_position.y - height_before
		visuals.position.y -= height_change
	visuals.position.y = move_toward(visuals.position.y, 0.0, STAIR_GLIDE_SPEED * delta)

# Walking into a step: if the way is clear one step higher, lift the player onto it.
# returns true if the player was lifted
func step_up_if_blocked(delta: float) -> bool:
	if not is_on_floor() or velocity.x == 0:
		return false

	var move_forward := Vector2(velocity.x * delta, 0)
	var move_up := Vector2(0, -STEP_HEIGHT)
	var raised_transform := global_transform.translated(move_up)

	var blocked_ahead := test_move(global_transform, move_forward)
	var room_above := not test_move(global_transform, move_up)
	var clear_when_raised := not test_move(raised_transform, move_forward)

	if blocked_ahead and room_above and clear_when_raised:
		global_position += move_up
		return true
	return false

# Solid arrow while charging a kick, see-through arrow while just aiming, hidden during the kick itself.
func update_power_arrow_visibility() -> void:
	if is_kicking:
		power_arrow.visible = true
		power_arrow.modulate.a = 1.0
	elif kick_animation_playing:
		power_arrow.visible = false
	elif get_kickable_package() != null:
		power_arrow.visible = true
		power_arrow.modulate.a = AIM_IN_RANGE_ALPHA
	else:
		power_arrow.visible = true
		power_arrow.modulate.a = AIM_OUT_OF_RANGE_ALPHA

# Returns the closest package in kick range (in front of the player or under their feet), or null.
func get_kickable_package() -> RigidBody2D:
	var closest_package: RigidBody2D = null
	var closest_distance := INF
	for body in kickrange.get_overlapping_bodies():
		if not is_kickable(body):
			continue
		var distance := global_position.distance_to(body.global_position)
		if distance < closest_distance:
			closest_package = body
			closest_distance = distance
	return closest_package

# packages and kickable props can be kicked, unless they're already destroyed
func is_kickable(body: Node) -> bool:
	var is_kickable_type := body.is_in_group("packages") or body.is_in_group("kickable_props")
	return is_kickable_type and not body.is_destroyed

func _notification(what: int) -> void:
	# Drop a half-charged kick when the game pauses, so it doesn't carry over after resuming.
	if what == NOTIFICATION_PAUSED:
		is_kicking = false
		kick_power = 100
		power_arrow.visible = false


func _on_step_timer_timeout() -> void:
	walking_sfx.pitch_scale = randf_range(0.95, 1.05)
	walking_sfx.play()
	pass # Replace with function body.
