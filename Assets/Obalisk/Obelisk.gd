extends Spatial

# Outside world objects
export(NodePath) var target_path # User defined path to target
export(NodePath) var player_path # User defined path to player (for testing)
export(NodePath) var checkbox_path # User defined path to checkbox (for testing)
var target   # Path node
var player   # Player node for testing. TODO: Trigger after player finishes puzzle
var checkbox # Checkbox node for testing. TODO: Trigger after player finishes puzzle

# Inside this compound object objects
var rotator   # Rotating base for the obelisk
var projector # Laser projector!
var spinner   # Spinning thing that looks cool

# Other variables
var once = 0 # For things that happen only once

# Test nodes
var suz1
var suz2
var suz3


func _ready():
	var suz = get_node("Suzanne")
	suz1 = suz.duplicate()
	suz2 = suz.duplicate()
	suz3 = suz.duplicate()
	add_child(suz1)
	add_child(suz2)
	add_child(suz3)
	
	if (target_path == null) or (target_path.is_empty()): breakpoint
	if (player_path == null) or (player_path.is_empty()): breakpoint
	if (checkbox_path == null) or (checkbox_path.is_empty()): breakpoint
	
	target   = self.get_node(target_path)
	player   = self.get_node(player_path)
	checkbox = self.get_node(checkbox_path)
	
	rotator = get_node("Rotator")
	projector = get_node("Rotator/Projector")
	spinner = get_node("Rotator/Projector/Spinner")
	
	# Initialize rotation of the obelisk to starting position
	# TODO: replace player with target
	var pos = rotator.global_transform.origin * 2
	pos.y = rotator.global_transform.origin.y
	var tf = rotator.global_transform.looking_at(pos, Vector3(0,1,0))
	rotator.global_transform = tf
	
	# Initialize rotation of the projector
	projector.transform = projector.transform.rotated(Vector3(1,0,0), PI/2)
	
	set_physics_process(true)


func _physics_process(delta):
	# TODO: replace player with target
	
	# Rotate the rotator
	if checkbox.is_pressed():
		# Point towards player
		var pos = player.global_transform.origin
		pos.y = rotator.global_transform.origin.y
		var tf = rotator.global_transform.looking_at(pos, Vector3(0,1,0))
		rotator.global_transform = rotator.global_transform.interpolate_with(tf, delta*0.5)
	else:
		# Point away from origin
		# Pick a spot twice the distance away from our current position and point to it
		var pos = rotator.global_transform.origin * 2
		pos.y = rotator.global_transform.origin.y
		var tf = rotator.global_transform.looking_at(pos, Vector3(0,1,0))
		rotator.global_transform = rotator.global_transform.interpolate_with(tf, delta*0.5)
	
	# Rotate the projector
	var projector_target
	if checkbox.is_pressed():
		# Vector from projector to player relative to the projector
		projector_target = (player.get_camera_pos() - projector.global_transform.origin)
	else:
		# Point streight up
		projector_target = Vector3(0,1,0)
	# Normal vector for the projector's rotation plane
	var normal = (Quat(rotator.transform.basis) * Vector3(1,0,0)).normalized()
	var forward_normal = (Quat(rotator.transform.basis) * Vector3(0,0,-1)).normalized()
	var proj_normal = (Quat(projector.global_transform.basis) * Vector3(0,0,-1)).normalized()
	# Distance between projector and player
	var dist = projector_target.dot(normal)
	# Point on the projector's plane of rotation. Thanks to:
	# https://stackoverflow.com/questions/9605556/how-to-project-a-point-onto-a-plane-in-3d
	var proj_point = projector_target - dist*normal
	var relative_proj_point = proj_point + (projector.global_transform.origin)
	# Angle needed to rotate to target
	var det_a = Basis(proj_normal, proj_point, normal).determinant()
	var dot_a = proj_normal.dot(proj_point)
	var angle = atan2(det_a, dot_a)
	# Max angle projector should rotate (prevent from rotating backwards
	var det_ma = Basis(proj_point, forward_normal, normal).determinant()
	var dot_ma = proj_point.dot(forward_normal)
	var max_angle = atan2(det_ma, dot_ma)
	# Apply interpolated rotation
	var tf = projector.transform.rotated(Vector3(1,0,0), angle)
	if abs(max_angle) < PI/2+0.01:
		projector.transform = projector.transform.interpolate_with(tf, delta*0.5)
	
	# Debugging stuff, Keep!
#	suz1.global_transform.origin = forward_normal + rotator.global_transform.origin
	#####
#	if Input.is_action_just_pressed("breakpoint"):
#		breakpoint
