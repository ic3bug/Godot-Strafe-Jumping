# Ported from https://github.com/WiggleWizard/quake3-movement-unity3d/blob/master/CPMPlayer.cs

extends KinematicBody
class_name Player

# For input
const MOUSE_SENS : float = 3.0
var rot : Vector2 = Vector2.ZERO
var move_input : Vector2 = Vector2.ZERO

# Movement variables
class MovementSettings:
	var max_speed : float = 0.0
	var acceleration : float = 0.0
	var deceleration : float = 0.0
	
	func _init(_max_speed, _acceleration, _deceleration):
		max_speed = _max_speed
		acceleration = _acceleration
		deceleration = _deceleration

var FRICTION : float = 6.0
var GRAVITY : float = 20.0
var JUMP_FORCE : float = 8.5
var AIR_CONTROL : float = 0.3
var AUTO_JUMP : bool = true

var GROUND_SETTINGS : MovementSettings = MovementSettings.new(10.0, 14.0, 10.0)
var AIR_SETTINGS : MovementSettings = MovementSettings.new(7.0, 2.0, 2.0)
var STRAFE_SETTINGS : MovementSettings = MovementSettings.new(1.0, 50.0, 50.0)

var dir : Vector3 = Vector3.ZERO
var vel : Vector3 = Vector3.ZERO
var dir_norm : Vector3 = Vector3.ZERO
var friction : float = 0.0
var jump_queued : bool = false
var is_on_slope : bool = false

func _physics_process(delta):
	process_input()
	process_movement(delta)
	process_rotations()

# Mouse input for rotations
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rot = Vector2(event.relative.y * MOUSE_SENS * -0.001, event.relative.x * MOUSE_SENS * -0.001)

func process_input():
	# Applying movement variables based on input
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		move_input.x = (int(Input.is_action_pressed("backward")) - int(Input.is_action_pressed("forward")))
		move_input.y = (int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left")))
	
	# Setting the mouse mode
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("primary"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func process_movement(delta):
	# Setting the direction
	dir = move_input.x * $Head.global_transform.basis.z
	dir += move_input.y * $Head.global_transform.basis.x
	
	queue_jump()
	if is_on_floor():
		ground_move(delta)
	else:
		air_move(delta)
	vel = move_and_slide(vel, Vector3.UP, true, 4, 0.8, false)

# Player can queue the next jump before hitting the ground
func queue_jump() -> void:
	if AUTO_JUMP:
		jump_queued = Input.is_action_pressed("jump")
		return
	if Input.is_action_pressed("jump") and !jump_queued:
		jump_queued = true
	if Input.is_action_pressed("jump"):
		jump_queued = false

# Air movement
func air_move(delta : float) -> void:
	var accel : float = 0.0
	var wishdir : Vector3 = Vector3(dir.x, 0.0, dir.z)
	var wishspeed : float = wishdir.length()
	wishspeed *= AIR_SETTINGS.max_speed
	dir_norm = wishdir.normalized()
	# CPM air control
	var wishspeed2 : float = wishspeed
	if vel.dot(wishdir) < 0.0:
		accel = AIR_SETTINGS.deceleration
	else:
		accel = AIR_SETTINGS.acceleration
	# Left or right strafing only
	if dir.z == 0.0 and dir.x != 0.0:
		if wishspeed > STRAFE_SETTINGS.max_speed:
			wishspeed = STRAFE_SETTINGS.max_speed
		accel = STRAFE_SETTINGS.acceleration
	accelerate(wishdir, wishspeed, accel, delta)
	if AIR_CONTROL > 0:
		air_control(wishdir, wishspeed2, delta)
	# Apply gravity
	vel.y -= GRAVITY * delta

# Allows strafing while airborne
func air_control(target_dir : Vector3, target_speed : float, delta : float) -> void:
	if abs(dir.z) < 0.001 or abs(target_speed) < 0.001:
		return
	var z_speed : float = vel.y
	vel.y = 0.0
	var speed : float = vel.length()
	vel = vel.normalized()
	var dot : float = vel.dot(target_dir)
	var k : float = 32.0
	k *= AIR_CONTROL * dot * dot * delta
	# Change direction while slowing down
	if dot > 0:
		vel.x *= speed + target_dir.x * k
		vel.y *= speed + target_dir.y * k
		vel.z *= speed + target_dir.z * k
		vel = vel.normalized()
		dir_norm = vel
	vel.x *= speed
	vel.y = z_speed
	vel.z *= speed

# Ground movement
func ground_move(delta : float) -> void:
	apply_friction(float(!jump_queued), delta)
	var wishdir : Vector3 = Vector3(dir.x, 0.0, dir.z)
	wishdir = wishdir.normalized()
	dir_norm = wishdir
	var wishspeed : float = wishdir.length()
	wishspeed *= GROUND_SETTINGS.max_speed
	accelerate(wishdir, wishspeed, GROUND_SETTINGS.acceleration, delta)
	# Slope handling
	if get_slide_count() > 0:
		if get_slide_collision(0).normal.dot(Vector3.DOWN) > -0.9:
			is_on_slope = true
		else:
			# Apply gravity
			is_on_slope = false
			vel.y = -GRAVITY * delta
	# Jumping
	if jump_queued:
		vel.y = JUMP_FORCE
		jump_queued = false

# Both air and ground friction
func apply_friction(t : float, delta : float) -> void:
	var vec : Vector3 = vel
	vec.y = 0.0
	var speed : float = vec.length()
	var drop : float = 0.0
	# Only apply friction when grounded
	if is_on_floor():
		var control : float
		if speed < GROUND_SETTINGS.deceleration:
			control = GROUND_SETTINGS.deceleration
		else:
			control = speed
		drop = control * FRICTION * delta * t
	var new_speed = speed - drop
	friction = new_speed
	if new_speed < 0:
		new_speed = 0
	if new_speed > 0:
		new_speed /= speed
	vel.x *= new_speed
	vel.z *= new_speed

func accelerate(target_dir : Vector3, target_speed : float, accel : float, delta : float) -> void:
	var current_speed : float = vel.dot(target_dir)
	var add_speed : float = target_speed - current_speed
	if add_speed <= 0:
		return
	var accel_speed = accel * delta * target_speed
	if accel_speed > add_speed:
		accel_speed = add_speed
	vel.x += accel_speed * target_dir.x
	vel.z += accel_speed * target_dir.z

# Head rotations base on mouse movement
func process_rotations():
	$Head.rotate_x(rot.x)
	var head_rot_x = clamp($Head.rotation_degrees.x, -85.0, 85.0)
	$Head.rotation_degrees.x = head_rot_x
	rotate_y(rot.y)
	rot = Vector2.ZERO
