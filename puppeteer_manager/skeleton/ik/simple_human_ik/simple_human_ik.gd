class_name SimpleHumanIk
extends Node

class SpineChain:
	var bone_chain: Array[int] = []
	var bone_lengths: Array[float] = []
	var chain_length: float = 0.0
	var root_leaf_projection_dists: Array[float] = []
	var root_leaf_dist: float = 0.0
	
	var root_leaf_normal: Vector3
	var local_bone_normals: Array[Vector3] = []

## Use rest_bone_poses as initial skeleton pose when computing ik 
@export var use_rest_bone_poses: bool = true 

@export var target_head: Node3D = null
@export var target_hip: Node3D = null

@export var head_bone_name: String = ""
@export var hip_bone_name: String = ""

@export var skeleton: Skeleton3D = null

var _spine_chain := SpineChain.new()

static func _find_chain(p_skeleton: Skeleton3D, root_bone: int, leaf_bone: int) -> Array[int]:
	# Recursively iterate over children until leaf_bone is found
	var bone_chain: Array[int] = []
	var child_bones := p_skeleton.get_bone_children(root_bone)
	for bone_idx: int in child_bones:
		if bone_idx == leaf_bone:
			bone_chain = [ leaf_bone ] as Array[int]
		else:
			bone_chain = SimpleHumanIk._find_chain(p_skeleton, bone_idx, leaf_bone)
		
		# If leaf bone was found, add this bone_idx and stop searching
		if not bone_chain.is_empty():
			bone_chain.push_front(root_bone)
			break
	
	return bone_chain

func _init_skeleton_bones(head_bone: String, hip_bone: String):
	if not self.skeleton:
		return
	
	var head_idx: int = self.skeleton.find_bone(head_bone)
	var hip_idx: int = self.skeleton.find_bone(hip_bone)
	if head_idx < 0 or hip_idx < 0:
		return
	
	var spine_bone_chain := SimpleHumanIk._find_chain(self.skeleton, hip_idx, head_idx)
	if spine_bone_chain.size() < 2:
		return
	
	# Calculate individual link lengths
	var bone_lengths: Array[float] = []
	for id: int in range(0, spine_bone_chain.size()):
		var link_length: float = self.skeleton.get_bone_pose_position(spine_bone_chain[id]).length()
		bone_lengths.push_back(link_length)
	
	# When calculating length of entire chain, ignore length to root bone
	# TODO: Shoule chain_length include 0-th bone length?
	var chain_length: float = 0.0
	for id: int in range(1, spine_bone_chain.size()):
		chain_length += bone_lengths[id]
	
	# Compute root-leaf bone distances
	var root_pose: Transform3D = self.skeleton.get_bone_global_pose(spine_bone_chain[0])
	var root_leaf_norm: Vector3 = (self.skeleton.get_bone_global_pose(spine_bone_chain[-1]).origin - root_pose.origin)
	var root_leaf_dist: float = root_leaf_norm.length()
	root_leaf_norm /= root_leaf_dist
	
	var root_leaf_projection_dists: Array[float] = []
	root_leaf_projection_dists.resize(spine_bone_chain.size())
	for id: int in range(0, spine_bone_chain.size()):
		var cur_bone_pos: Vector3 = self.skeleton.get_bone_global_pose(spine_bone_chain[id]).origin
		var project_dist: float = SimpleHumanIk._project_line_origin_point_dist(root_pose.origin, root_leaf_norm, cur_bone_pos)
		root_leaf_projection_dists[id] = project_dist
	
	var local_bone_normals: Array[Vector3] = []
	for id: int in range(0, spine_bone_chain.size()):
		var bone_normal: Vector3 = self.skeleton.get_bone_pose_position(spine_bone_chain[id]).normalized()
		local_bone_normals.push_back(bone_normal)
	
	var spine_chain := SpineChain.new()
	spine_chain.bone_chain = spine_bone_chain
	spine_chain.bone_lengths = bone_lengths
	spine_chain.chain_length = chain_length
	spine_chain.root_leaf_dist = root_leaf_dist
	spine_chain.root_leaf_projection_dists = root_leaf_projection_dists
	spine_chain.root_leaf_normal = root_leaf_norm
	spine_chain.local_bone_normals = local_bone_normals
	
	self._spine_chain = spine_chain

## Get distance between line origin and projected point
static func _project_line_origin_point_dist(line_origin: Vector3, line_normal: Vector3, point: Vector3):
	return line_normal.dot(point - line_origin)

static func _project_point_onto_line(line_origin: Vector3, line_normal: Vector3, point: Vector3):
	return _project_line_origin_point_dist(line_origin, line_normal, point) * line_normal + line_origin

static func _perform_head_ik(spine_chain: SpineChain, leaf_pose: Transform3D, bone_poses: Array[Transform3D]):
	var original_head_normal: Vector3 = (bone_poses[-1].origin - bone_poses[0].origin).normalized()
	var target_head_normal: Vector3 = (leaf_pose.origin - bone_poses[0].origin).normalized()
	
	# Check if there's an angle between target and original position
	var rotation_axis: Vector3 = original_head_normal.cross(target_head_normal)
	var tot_rotation_angle: float = rotation_axis.length()
	if not is_finite(tot_rotation_angle):
		push_warning("Invalid rotation angle when performing simple head ik")
		return
	
	# Ensure that angle is large enough for accurate rotations
	if tot_rotation_angle >= PI/180.0*0.5: #not is_zero_approx(tot_rotation_angle):
		# Get total rotation axis in radians
		rotation_axis /= tot_rotation_angle
		tot_rotation_angle = asin(tot_rotation_angle)
		
		# Store current tf from bone's old to new global pose
		var prev_old_to_new_global_tf := Transform3D.IDENTITY
		for id: int in range(0, bone_poses.size()-1):
			# Store current global pose
			var cur_bone_global_pose: Transform3D = bone_poses[id]
			
			# Compute adjusted bone pose
			var new_bone_global_pose: Transform3D = prev_old_to_new_global_tf * cur_bone_global_pose
			
			# Add new rotation
			var cur_chain_length: float = spine_chain.root_leaf_projection_dists[id+1] - spine_chain.root_leaf_projection_dists[id]
			var rot_angle: float = tot_rotation_angle * cur_chain_length / spine_chain.root_leaf_dist
			new_bone_global_pose.basis *=  Basis(rotation_axis, rot_angle)
			
			# Save new global rot
			bone_poses[id] = new_bone_global_pose
			
			# Update bone global tf
			prev_old_to_new_global_tf = new_bone_global_pose * cur_bone_global_pose.inverse()
		
		# Compute adjusted pose of last bone
		bone_poses[-1] = prev_old_to_new_global_tf * bone_poses[-1]

static func _compute_total_twist(__spine_chain: SpineChain, leaf_pose: Transform3D, bone_poses: Array[Transform3D]) -> float:
	var rot_tf: Basis = bone_poses[-1].basis.inverse() * leaf_pose.basis
	var rot_angle: float = rot_tf.get_euler(EULER_ORDER_YXZ)[1]
	return rot_angle
	#var rot_axis_dot: float = bone_poses[-1].basis.z.dot(leaf_pose.basis.z)
	#var rot_axis: Vector3 = bone_poses[-1].basis.z.cross(leaf_pose.basis.z)
	#var rot_axis_det: float = rot_axis.length()
	#var rot_angle: float = atan2(rot_axis_det, rot_axis_dot)
	#print(bone_poses[-1].basis.z)
	#print(leaf_pose.basis.z)
	#rot_angle = rot_angle if bone_poses[-1].basis.y.dot(rot_axis) >= 0 else -rot_angle
	#print(rot_angle/PI*180)
	#return rot_angle

static func _perform_twist(spine_chain: SpineChain, total_twist: float, bone_poses: Array[Transform3D]):
	var prev_twist_rot := Basis.IDENTITY
	var cur_length: float = 0
	for id: int in range(0, bone_poses.size() - 1):
		cur_length += spine_chain.bone_lengths[id+1]
		var cur_twist: float = total_twist * cur_length / spine_chain.chain_length
		
		var cur_twist_rot := Basis(spine_chain.local_bone_normals[id+1], cur_twist)
		bone_poses[id].basis = prev_twist_rot.inverse() * bone_poses[id].basis * cur_twist_rot
		
		prev_twist_rot = bone_poses[id].basis

static func _perform_ccd_ik(__spine_chain:SpineChain, leaf_pose: Transform3D, bone_poses: Array[Transform3D]):
	var prev_old_to_new_tf := Transform3D.IDENTITY
	var old_bone_leaf_pose: Transform3D = bone_poses[-1]
	for id: int in range(0, bone_poses.size()-1):
		var cur_bone_pose: Transform3D = bone_poses[id]
		
		var new_bone_pose: Transform3D = prev_old_to_new_tf * cur_bone_pose
		var bone_leaf_pos: Vector3 = prev_old_to_new_tf * old_bone_leaf_pose.origin
		
		var bone_norm: Vector3 = (bone_leaf_pos - new_bone_pose.origin).normalized()
		var leaf_norm: Vector3 = (leaf_pose.origin - new_bone_pose.origin).normalized()
		
		var rot_axis: Vector3 = bone_norm.cross(leaf_norm)
		var rot_angle: float = rot_axis.length()
		if not is_zero_approx(rot_angle):
			rot_axis /= rot_angle
			rot_angle = asin(rot_angle)#, bone_norm.dot(leaf_norm))
			#if id > bone_poses.size()-2:
			#	rot_angle = clampf(rot_angle, 0,0)
			new_bone_pose.basis *= Basis(rot_axis, rot_angle)
		
		bone_poses[id] = new_bone_pose.orthonormalized()
		prev_old_to_new_tf = (new_bone_pose * cur_bone_pose.inverse())
	
	bone_poses[-1] = prev_old_to_new_tf * bone_poses[-1]

func _perform_simple_head_ik(spine_chain: SpineChain, leaf_pose_node: Node3D):
	# Work in skeleton reference frame
	var skeleton_inv_tx: Transform3D = self.skeleton.global_transform.inverse()
	var leaf_pose: Transform3D = skeleton_inv_tx * leaf_pose_node.global_transform
	
	# Usually, we could just use leaf_pose directly. However, MediaPipe only provides head rotations
	# without translation, and that makes neck movements look weird. Instead, we're adjusting the
	# head movement locally. If you're using this outside of MediaPipe, you can try uncommenting the
	# following three lines and see how it looks.
	var leaf_bone_pos: Vector3 = self.skeleton.get_bone_global_pose(spine_chain.bone_chain[-1]).origin \
		if not self.use_rest_bone_poses else self.skeleton.get_bone_global_rest(spine_chain.bone_chain[-1]).origin
	var root_bone_pose: Transform3D = self.skeleton.get_bone_global_pose(spine_chain.bone_chain[0]) \
		if not self.use_rest_bone_poses else self.skeleton.get_bone_global_rest(spine_chain.bone_chain[0])
	leaf_pose.origin = root_bone_pose * (Basis.IDENTITY.slerp(leaf_pose_node.basis, 0.075) * (root_bone_pose.inverse() * leaf_bone_pos))
	
	var bone_poses: Array[Transform3D] = self._get_bone_poses(spine_chain, self.use_rest_bone_poses)
	
	## Twist the skeleton to align attitude
	var total_twist: float = SimpleHumanIk._compute_total_twist(spine_chain, leaf_pose, bone_poses)
	SimpleHumanIk._perform_twist(spine_chain, total_twist, bone_poses)
	
	## Bend the skeleton to align position
	for iter in range(0,32):
		SimpleHumanIk._perform_head_ik(spine_chain, leaf_pose, bone_poses)
		SimpleHumanIk._perform_ccd_ik(spine_chain, leaf_pose, bone_poses)
	
	#for iter in range(0,32):
		#SimpleHumanIk._perform_ccd_ik_reverse(spine_chain, leaf_pose, bone_poses)
	
	bone_poses[-1].basis = leaf_pose.basis
	self._set_bone_poses(spine_chain, bone_poses)

func _get_bone_poses(spine_chain: SpineChain, use_rest_poses: bool) -> Array[Transform3D]:
	var bone_count: int = spine_chain.bone_chain.size()
	var bone_poses: Array[Transform3D] = []
	bone_poses.resize(bone_count)
	if use_rest_poses:
		for id: int in range(0, bone_count):
			bone_poses[id] = self.skeleton.get_bone_global_rest(spine_chain.bone_chain[id])
	else:
		for id: int in range(0, bone_count):
			bone_poses[id] = self.skeleton.get_bone_global_pose(spine_chain.bone_chain[id])
	return bone_poses

func _set_bone_poses(spine_chain: SpineChain, bone_poses: Array[Transform3D]):
	var bone_chain := spine_chain.bone_chain
	
	# Move bones to computed positions
	var prev_bone_pose: Transform3D = self.skeleton.get_bone_global_pose(bone_chain[0]) * self.skeleton.get_bone_pose(bone_chain[0]).inverse()
	for id: int in range(0, bone_chain.size()):
		# Get bone pose in local space
		var cur_local_pose: Transform3D = prev_bone_pose.inverse() * bone_poses[id]
		#self.skeleton.set_bone_pose_position(bone_chain[id], cur_local_pose.origin)
		self.skeleton.set_bone_pose_rotation(bone_chain[id], cur_local_pose.basis.get_rotation_quaternion())
		prev_bone_pose = bone_poses[id]

func _ready():
	self.setup_ik()

func setup_ik():
	self._init_skeleton_bones(self.head_bone_name, self.hip_bone_name)

func update_ik():
	# TODO: Remove reset_bone_poses
	#self.skeleton.reset_bone_poses()
	self._perform_simple_head_ik(self._spine_chain, self.target_head)
