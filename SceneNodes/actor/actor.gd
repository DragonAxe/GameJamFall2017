extends KinematicBody

var flying = false

# Looking movement controls:
var view_sensitivity = 0.15
var yaw = 0
var pitch = 0

# Cubio Member variables
var g = -9.8*1.5
var vel = Vector3()
const MAX_SPEED = 5
const SPRINT_SPEED = 10
const JUMP_SPEED = 6
const ACCEL= 5
const DEACCEL= 10

const up_vector = Vector3(0,1,0)
const slope_stop_min_vel=0.05 # 0.05
const max_slides=4 # 4
const floor_max_angle=0.7 # 0.785398


func get_camera_pos():
	return get_node("yaw/camera").global_transform.origin


func _input(ev):
	if Input.is_action_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("enable_flying"):
		flying = not flying
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if ev is InputEventMouseMotion:
			yaw = fmod(yaw - ev.relative.x * view_sensitivity, 365)
			pitch = max(min(pitch - ev.relative.y * view_sensitivity, 90), -90)
			get_node("yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
			get_node("yaw/camera").set_rotation(Vector3(deg2rad(pitch), 0, 0))


func _physics_process(delta):
#	var debug = ""
#	for i in range(get_slide_count()):
#		var kc = get_slide_collision(i)
#		debug = debug + " + " + str(kc.collider.get_name())
#	if (get_slide_count() == 0):
#		debug = "None"
#	get_node("/root/Root/DebugLabel").set_text(debug)
#	walk(delta)
	if flying:
		fly(delta)
	else:
		if is_on_floor():
			walk(delta)
		else:
			airbound(delta)

func _ready():
	set_physics_process(true)
	set_process_input(true)


func fly(delta):
	var dir = Vector3() # Where does the player intend to walk to
	var cam_xform = get_node("yaw").get_global_transform()
	
	if (Input.is_action_pressed("move_forward")):
		dir += -cam_xform.basis[2]
	if (Input.is_action_pressed("move_backward")):
		dir += cam_xform.basis[2]
	if (Input.is_action_pressed("move_left")):
		dir += -cam_xform.basis[0]
	if (Input.is_action_pressed("move_right")):
		dir += cam_xform.basis[0]
	
	# Jump
	if (Input.is_action_pressed("jump")):
		dir += Vector3(0,1,0)
	if (Input.is_action_pressed("crouch")):
		dir += Vector3(0,-1,0)
	
	dir = dir.normalized()
	# dir is a unit vector on the horizontial plane
	# representing the direction the player wants to move.

	# accel determines the acceleration factor positive or negative
	# if the player controls are pressed or not pressed respectively.
	var target = 0
	if (Input.is_action_pressed("sprint")):
#		target = dir*(SPRINT_SPEED - (SPRINT_SPEED*slope_angle_sum))
		target = dir*SPRINT_SPEED
	else:
		target = dir*MAX_SPEED
	
	var accel
	if (dir.dot(vel) > 0): # Check if player is pressing any movement buttons
		accel = ACCEL
	else:
		accel = DEACCEL
	
	# Move the player's horizontial velocity towards the target
	# by interpolating by the acceleration ammount.
	vel = vel.linear_interpolate(target, accel*delta)
	
	# Actually move the player in the physics environment,
	# sliding along other physics objects.
	# New 'vel' is the remaining vector distance to target that used to be 'vel'.
	vel = move_and_slide(vel, up_vector, slope_stop_min_vel,
	                     max_slides, floor_max_angle)



func airbound(delta):
	var dir = Vector3() # Where does the player intend to walk to
	var cam_xform = get_node("yaw").get_global_transform()
	
	if (Input.is_action_pressed("move_forward")):
		dir += -cam_xform.basis[2]
	if (Input.is_action_pressed("move_backward")):
		dir += cam_xform.basis[2]
	if (Input.is_action_pressed("move_left")):
		dir += -cam_xform.basis[0]
	if (Input.is_action_pressed("move_right")):
		dir += cam_xform.basis[0]
	
	dir.y = 0
	dir = dir.normalized()
	
	vel.y += delta*g
	
	var hvel = vel
	hvel.y = 0
	
	var target = dir*MAX_SPEED
	var accel
	if (dir.dot(hvel) > 0):
		accel = ACCEL
	else:
		accel = DEACCEL
	
	hvel = hvel.linear_interpolate(target, accel*delta*0.1)
	
	vel.x = hvel.x
	vel.z = hvel.z
	
	vel = move_and_slide(vel, up_vector, slope_stop_min_vel, max_slides, floor_max_angle)
	
	if (is_on_floor() and Input.is_action_pressed("jump")):
		vel.y = JUMP_SPEED


func walk(delta):
	var dir = Vector3() # Where does the player intend to walk to
	var cam_xform = get_node("yaw").get_global_transform()
	
	if (Input.is_action_pressed("move_forward")):
		dir += -cam_xform.basis[2]
	if (Input.is_action_pressed("move_backward")):
		dir += cam_xform.basis[2]
	if (Input.is_action_pressed("move_left")):
		dir += -cam_xform.basis[0]
	if (Input.is_action_pressed("move_right")):
		dir += cam_xform.basis[0]
	
	dir.y = 0
	dir = dir.normalized()
	# dir is a unit vector on the horizontial plane
	# representing the direction the player wants to move.
	
	# Add gravity to the actor's velocity for each physics frame.
	vel.y += delta*g
	
	# hvel is the player's current velocity in the horizontal plane.
	var hvel = vel
	hvel.y = 0
	
	# Calculate angle away from flat that player is standing on,
	# So it can later be used to slow down the player on steep slopes.
	var slope_angle_sum = 0
	for i in range(get_slide_count()):
		var kc_normal = get_slide_collision(i).get_normal()
		var angle = kc_normal.angle_to(up_vector)
		if (angle < floor_max_angle):
			slope_angle_sum += angle
	
	# accel determines the acceleration factor positive or negative
	# if the player controls are pressed or not pressed respectively.
	var target = 0
	if (Input.is_action_pressed("sprint")):
		target = dir*(SPRINT_SPEED - (SPRINT_SPEED*slope_angle_sum))
	else:
		target = dir*(MAX_SPEED - (MAX_SPEED*slope_angle_sum))
	#                              ^^^^^^^^^^^^^^^^^^^^^^^^^
	# The last part will slow the player down on a slope.
	
	var accel
	if (dir.dot(hvel) > 0): # Check if player is pressing any movement buttons
		accel = ACCEL
	else:
		accel = DEACCEL
	
	# Move the player's horizontial velocity towards the target
	# by interpolating by the acceleration ammount.
	hvel = hvel.linear_interpolate(target, accel*delta)
	
	# Replace the player's previous velocity with the
	# new horizontal velocity that was just calculated.
	vel.x = hvel.x
	vel.z = hvel.z
	
	# Prevent player from sliding down small slopes
	for i in range(get_slide_count()):
		var kc_normal = get_slide_collision(i).get_normal()
		var grav_vec = Vector3(0, delta*g, 0) # The gravity vector
		var grav_result = grav_vec.reflect(kc_normal)
		# Add the result of reflecting the gravity vector away from the collision normal
		vel = vel + grav_result
	
	# Actually move the player in the physics environment,
	# sliding along other physics objects.
	# New 'vel' is the remaining vector distance to target that used to be 'vel'.
	vel = move_and_slide(vel, up_vector, slope_stop_min_vel,
	                     max_slides, floor_max_angle)
	
	# Jump
	if (is_on_floor() and Input.is_action_pressed("jump")):
		vel.y = JUMP_SPEED
