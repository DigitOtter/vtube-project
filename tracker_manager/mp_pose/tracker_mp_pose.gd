class_name TrackerMpPose
extends TrackerBase

const TRACKER_NAME := &"MpPose"
const DEFAULT_LERP_RATE := 0.10 * 60

class ArmBones:
	# Bones should be shoulder, upper arm, forearm
	var idx := PackedInt64Array()
	var rest_pos := PackedVector3Array()
	var local_positions := PackedVector3Array()
	var lengths := PackedFloat64Array()
	
	var t_pose_tfs: Array[Transform3D] = []
	var t_pose_shoulder_norm := Vector3.ZERO
	var t_pose_shoulder_tf := Basis.IDENTITY
	var t_pose_elbow_rot_axis := Vector3.DOWN

var puppeteer_skel_direct: PuppeteerSkeletonDirect = null
var media_pipe_pose: MediaPipePose = null

var _left_arm_bones := ArmBones.new()
var _right_arm_bones := ArmBones.new()

#static func _compute_rot_basis(norm_a: Vector3, norm_b: Vector3) -> Basis:
	##https://math.stackexchange.com/questions/180418/calculate-rotation-matrix-to-align-vector-a-to-vector-b-in-3d
	#var v: Vector3 = norm_a.cross(norm_b)
	#var c: float = norm_a.dot(norm_b)
	#
	#var ct: float = 1/(1+c)
	#if is_zero_approx(ct):
		## Get any rotation with 180deg
		#v = norm_a.cross(Vector3(1,0,0))
		#if is_zero_approx(v.length_squared()):
			#v = norm_a.cross(Vector3(0,1,0))
		#
		#return Basis(v, PI)
	#
	#var v_x := Vector3(0, v.z, -v.y)
	#var v_y := Vector3(-v.z, 0, v.x)
	#var v_z := Vector3(v.y, -v.x, 0)
	#
	#v_x = Vector3(1,0,0) + v_x + -ct * Vector3(v_x.dot(v_x), v_y.dot(v_x), v_z.dot(v_x))
	#v_y = Vector3(0,1,0) + v_y + -ct * Vector3(v_x.dot(v_y), v_y.dot(v_y), v_z.dot(v_y))
	#v_z = Vector3(0,0,1) + v_z + -ct * Vector3(v_x.dot(v_z), v_y.dot(v_z), v_z.dot(v_z))
	#
	#return Basis(v_x, v_y, v_z).orthonormalized()

static func _compute_rot_basis(vec_a: Vector3, vec_b: Vector3) -> Basis:
	var rot_axis: Vector3 = vec_a.cross(vec_b)
	var rot_axis_l: float = rot_axis.length()
	
	if is_zero_approx(rot_axis_l):
		return Basis.IDENTITY
	
	var rot_angle: float = atan2(rot_axis_l, vec_a.dot(vec_b))
	return Basis(rot_axis/rot_axis_l, rot_angle)

static func _project_onto_plane(plane_origin: Vector3, plane_normal: Vector3, point: Vector3) -> Vector3:
	var plane_dist: float = plane_normal.dot(point - plane_origin)
	return point - plane_dist * plane_normal

static func _compute_t_pose(arm_bones: ArmBones, skeleton: Skeleton3D, 
		tpose_shoulder_norm: Vector3, local_elbow_x_direction: Vector3):
	var bone_poses: Array[Transform3D] = []
	bone_poses.resize(arm_bones.idx.size())
	for id in range(0, bone_poses.size()):
		bone_poses[id] = skeleton.get_bone_global_rest(arm_bones.idx[id])
	
	var upper_arm_norm: Vector3 = \
		(bone_poses[1].origin - bone_poses[0].origin).normalized()
	var forearm_norm: Vector3 = \
		(bone_poses[2].origin - bone_poses[1].origin).normalized()
	
	var elbow_rot_axis = bone_poses[1].basis.x
	var pose_update := Transform3D.IDENTITY
	
	##############################################################################
	## Adjust elbow. Rotate elbow joint so that upper arm and forearm are aligned
	# Project forearm_norm and upper_arm_norm onto elbow rotation plane
	var forearm_proj: Vector3 = TrackerMpPose._project_onto_plane(Vector3.ZERO, elbow_rot_axis, forearm_norm)
	var upper_arm_proj: Vector3 = TrackerMpPose._project_onto_plane(Vector3.ZERO, elbow_rot_axis, upper_arm_norm)
	var elbow_rot: Basis = TrackerMpPose._compute_rot_basis(forearm_proj, upper_arm_proj)
	
	# Update chain after elbow
	pose_update = bone_poses[1]
	bone_poses[1].basis = elbow_rot * bone_poses[1].basis
	pose_update = bone_poses[1] * pose_update.inverse()
	for id in range(2, arm_bones.idx.size()):
		var cur_bone_pose: Transform3D = bone_poses[id]
		var updated_bone_pose: Transform3D = pose_update * cur_bone_pose
		bone_poses[id] = updated_bone_pose
		pose_update = updated_bone_pose * cur_bone_pose.inverse()
	
	##############################################################################
	## After aligning elbow, align shoulder with tpose_shoulder_norm
	var shoulder_rot: Basis = TrackerMpPose._compute_rot_basis(upper_arm_norm, tpose_shoulder_norm)
	pose_update = bone_poses[0]
	bone_poses[0].basis = shoulder_rot * bone_poses[0].basis
	pose_update = bone_poses[0] * pose_update.inverse()
	for id in range(1, arm_bones.idx.size()):
		var cur_bone_pose: Transform3D = bone_poses[id]
		var updated_bone_pose: Transform3D = pose_update * cur_bone_pose
		bone_poses[id] = updated_bone_pose
		pose_update = updated_bone_pose * cur_bone_pose.inverse()
	
	##############################################################################
	## Ensure that elbow rot axis is aligned with local_elbow_x_direction
	upper_arm_norm = (bone_poses[1].origin - bone_poses[0].origin).normalized()
	elbow_rot_axis = bone_poses[1].basis.x
	var elbow_rot_axis_proj: Vector3 = TrackerMpPose._project_onto_plane(Vector3.ZERO, \
			upper_arm_norm, elbow_rot_axis)
	var target_elbow_rot_axis_proj: Vector3 = TrackerMpPose._project_onto_plane(Vector3.ZERO, \
			upper_arm_norm, bone_poses[0].basis * local_elbow_x_direction)
	shoulder_rot = TrackerMpPose._compute_rot_basis(elbow_rot_axis_proj, target_elbow_rot_axis_proj)
	
	pose_update = bone_poses[0]
	bone_poses[0].basis = shoulder_rot * bone_poses[0].basis
	pose_update = bone_poses[0] * pose_update.inverse()
	for id in range(1, arm_bones.idx.size()):
		var cur_bone_pose: Transform3D = bone_poses[id]
		var updated_bone_pose: Transform3D = pose_update * cur_bone_pose
		bone_poses[id] = updated_bone_pose
		pose_update = updated_bone_pose * cur_bone_pose.inverse()
	
	##############################################################################
	## Store local tfs
	#bone_poses[2].basis = Basis.IDENTITY
	#bone_poses[2].origin += Vector3.UP
	arm_bones.t_pose_shoulder_norm = (bone_poses[1].origin - bone_poses[0].origin).normalized()
	arm_bones.t_pose_elbow_rot_axis = bone_poses[1].basis.x
	arm_bones.t_pose_tfs.resize(arm_bones.idx.size())
	var base_pose: Transform3D = skeleton.get_bone_global_rest(arm_bones.idx[0]) * skeleton.get_bone_rest(arm_bones.idx[0]).inverse()
	for id in range(0, arm_bones.idx.size()):
		arm_bones.t_pose_tfs[id] = base_pose.inverse() * bone_poses[id]
		base_pose = bone_poses[id]
	
	arm_bones.t_pose_shoulder_tf = arm_bones.t_pose_tfs[0].basis * skeleton.get_bone_global_rest(arm_bones.idx[0]).basis.inverse()

static func _compute_rest_shoulder_rl_norm(skeleton: Skeleton3D, bone_map: BoneMap) -> Vector3:
	var prof_names: Array[StringName] = [ &"LeftUpperArm", &"RightUpperArm" ]
	var bone_pos: Array[Vector3] = []
	for prof_name: StringName in prof_names:
		var idx: int = bone_map.profile.find_bone(prof_name)
		var bone_name: StringName = bone_map.profile.get_bone_name(idx) if idx>=0 else prof_name
		bone_pos.push_back(skeleton.get_bone_global_rest(skeleton.find_bone(bone_name)).origin)
	
	return (bone_pos[0] - bone_pos[1]).normalized()

static func _setup_arm_bones(skeleton: Skeleton3D, bone_names: Array[StringName]) -> ArmBones:
	assert(bone_names.size() == 3)
	
	var arm_bones := ArmBones.new()
	for id: int in range(0, bone_names.size()):
		var idx: int = skeleton.find_bone(bone_names[id])
		
		arm_bones.idx.push_back(idx)
		arm_bones.rest_pos.push_back(skeleton.get_bone_rest(idx).origin)
		arm_bones.lengths.push_back(arm_bones.rest_pos[id].length())
	
	return arm_bones

static func _setup_arm_bones_map(skeleton: Skeleton3D, bone_map: BoneMap, profile_bone_names: Array[StringName]) -> ArmBones:
	var bone_names: Array[StringName] = []
	for prof_name: StringName in profile_bone_names:
		var idx: int = bone_map.profile.find_bone(prof_name)
		bone_names.push_back(bone_map.profile.get_bone_name(idx) if idx>=0 else prof_name)
	
	return TrackerMpPose._setup_arm_bones(skeleton, bone_names)

static func _setup_left_arm_bones(skeleton: Skeleton3D, bone_map: BoneMap,
			rest_shoulder_norm: Vector3) -> ArmBones:
	var prof_names: Array[StringName] = [ &"LeftUpperArm", &"LeftLowerArm", &"LeftHand" ]
	var arm_bones: ArmBones = TrackerMpPose._setup_arm_bones_map(skeleton, bone_map, prof_names)
	
	TrackerMpPose._compute_t_pose(arm_bones, skeleton, rest_shoulder_norm, Vector3.DOWN)
	return arm_bones

static func _setup_right_arm_bones(skeleton: Skeleton3D, bone_map: BoneMap,
			rest_shoulder_norm: Vector3) -> ArmBones:
	var prof_names: Array[StringName] = [ &"RightUpperArm", &"RightLowerArm", &"RightHand" ]
	var arm_bones: ArmBones = TrackerMpPose._setup_arm_bones_map(skeleton, bone_map, prof_names)
	
	TrackerMpPose._compute_t_pose(arm_bones, skeleton, rest_shoulder_norm, Vector3.UP)
	return arm_bones

func _setup_arm_data(skeleton: Skeleton3D, bone_map: BoneMap):
	var rest_shoulder_rl_norm: Vector3 = \
		TrackerMpPose._compute_rest_shoulder_rl_norm(skeleton, bone_map)
	self._left_arm_bones = \
		TrackerMpPose._setup_left_arm_bones(skeleton, bone_map, rest_shoulder_rl_norm)
	self._right_arm_bones = \
		TrackerMpPose._setup_right_arm_bones(skeleton, bone_map, -rest_shoulder_rl_norm)
	
	for bone_idx: int in self._left_arm_bones.idx + self._right_arm_bones.idx:
		self.puppeteer_skel_direct.set_bone_lerp_rate(bone_idx, DEFAULT_LERP_RATE)

func _update_arm(arm_bone_data: ArmBones, 
					shoulder_pos: Vector3, shoulder_vec: Vector3, 
					elbow_pos: Vector3, 
					wrist_pos: Vector3, wrist_vec: Vector3):
	
	######
	## TODO: Remove test stuff
	#TrackerMpPose._compute_t_pose(arm_bone_data, self.puppeteer_skel_direct.skeleton, shoulder_vec, Vector3.UP)
	for id: int in range(0, arm_bone_data.idx.size()):
		self.puppeteer_skel_direct.set_bone_tf(arm_bone_data.idx[id], arm_bone_data.t_pose_tfs[id])
	#return
	######
	
	shoulder_vec = arm_bone_data.t_pose_shoulder_tf * shoulder_vec
	var upper_arm_vec: Vector3 = arm_bone_data.t_pose_shoulder_tf * (elbow_pos - shoulder_pos)
	var forearm_vec: Vector3 = arm_bone_data.t_pose_shoulder_tf * (wrist_pos - elbow_pos)
	var elbow_rot_axis: Vector3 = arm_bone_data.t_pose_shoulder_tf * arm_bone_data.t_pose_elbow_rot_axis
	
	## Rotate shoulder to align upper_arm_vec
	var shoulder_rot: Basis = TrackerMpPose._compute_rot_basis(shoulder_vec, upper_arm_vec)
	#shoulder_rot = Basis(arm_bone_data.t_pose_shoulder_tf * arm_bone_data.t_pose_shoulder_norm, PI/180*0)
	
	elbow_rot_axis = shoulder_rot * elbow_rot_axis
	upper_arm_vec = shoulder_rot * upper_arm_vec
	forearm_vec   = shoulder_rot * forearm_vec
	
	## Rotate shoulder to align elbow_rot_axis
	var shoulder_adjust_rot := Basis.IDENTITY
	var elbow_rot := Basis.IDENTITY
	
	var elbow_rot_plane_normal: Vector3 = upper_arm_vec.cross(forearm_vec)
	var elbow_rot_plane_normal_l: float = elbow_rot_plane_normal.length()
	if not is_zero_approx(elbow_rot_plane_normal_l):
		elbow_rot_plane_normal /= elbow_rot_plane_normal_l
		
		var shoulder_rotate_axis: Vector3 = shoulder_rot * arm_bone_data.t_pose_shoulder_tf * arm_bone_data.t_pose_shoulder_norm
		elbow_rot_axis = TrackerMpPose._project_onto_plane(Vector3.ZERO, shoulder_rotate_axis, elbow_rot_axis)
		elbow_rot_plane_normal = TrackerMpPose._project_onto_plane(Vector3.ZERO, shoulder_rotate_axis, elbow_rot_plane_normal)
		shoulder_adjust_rot = TrackerMpPose._compute_rot_basis(elbow_rot_axis, elbow_rot_plane_normal)
		
		## Get elbow rotation
		var elbow_rot_angle: float = atan2(elbow_rot_plane_normal_l, upper_arm_vec.dot(forearm_vec))
		elbow_rot = Basis(Vector3(1,0,0), elbow_rot_angle)
	
	upper_arm_vec = shoulder_adjust_rot * upper_arm_vec
	forearm_vec = shoulder_adjust_rot * forearm_vec
	
	var wrist_rot: Basis = TrackerMpPose._compute_rot_basis(forearm_vec, wrist_vec)
	
	var shoulder_tf: Transform3D = arm_bone_data.t_pose_tfs[0]
	#shoulder_tf.basis = shoulder_adjust_rot * shoulder_rot * shoulder_tf.basis
	shoulder_tf.basis = shoulder_adjust_rot * shoulder_rot * shoulder_tf.basis
	self.puppeteer_skel_direct.set_bone_tf(arm_bone_data.idx[0], shoulder_tf)
	
	var elbow_tf: Transform3D = arm_bone_data.t_pose_tfs[1]
	elbow_tf.basis = elbow_tf.basis * elbow_rot
	self.puppeteer_skel_direct.set_bone_tf(arm_bone_data.idx[1], elbow_tf)
	
	#var wrist_tf: Transform3D = arm_bone_data.t_pose_tfs[2]
	#wrist_tf.basis *= wrist_rot
	#self.puppeteer_skel_direct.set_bone_tf(arm_bone_data.idx[2], wrist_tf)

func _on_mp_data_received(pose_landmarks: MediaPipeLandmarks):
	#self.set_test_poses(pose_landmarks)
	
	var coordinate_system_tf := Basis(Vector3(1,0,0), Vector3(0,-1,0), Vector3(0,0,-1)) # Basis(Vector3(1,0,0), Vector3(0,0,-1), Vector3(0,1,0))
	var left_shoulder := coordinate_system_tf * MediaPipePose.get_landmark_pos(pose_landmarks, MediaPipePose.LEFT_SHOULDER_IDX)
	var right_shoulder := coordinate_system_tf * MediaPipePose.get_landmark_pos(pose_landmarks, MediaPipePose.RIGHT_SHOULDER_IDX)
	var lr_shoulder_vec = right_shoulder - left_shoulder
	
	var left_elbow := coordinate_system_tf *  MediaPipePose.get_landmark_pos(pose_landmarks, MediaPipePose.LEFT_ELBOW_IDX)
	var left_wrist := coordinate_system_tf * MediaPipePose.get_landmark_pos(pose_landmarks, MediaPipePose.LEFT_WRIST_IDX)
	var left_palm := coordinate_system_tf * MediaPipePose.get_landmark_pos(pose_landmarks, MediaPipePose.LEFT_INDEX_IDX)
	self._update_arm(self._left_arm_bones, left_shoulder, -lr_shoulder_vec, \
					left_elbow, left_wrist, left_palm - left_wrist)
	
	var right_elbow := coordinate_system_tf * MediaPipePose.get_landmark_pos(pose_landmarks, MediaPipePose.RIGHT_ELBOW_IDX)
	var right_wrist := coordinate_system_tf * MediaPipePose.get_landmark_pos(pose_landmarks, MediaPipePose.RIGHT_WRIST_IDX)
	var right_palm  := coordinate_system_tf * MediaPipePose.get_landmark_pos(pose_landmarks, MediaPipePose.RIGHT_INDEX_IDX)
	self._update_arm(self._right_arm_bones, right_shoulder, lr_shoulder_vec, \
					right_elbow, right_wrist, right_palm - right_wrist)
	#self._update_arm(self._right_arm_bones, Vector3(0,0,0), Vector3(-1,0,0), \
					#Vector3(-1,0,-1), Vector3(-2,0,2), Vector3(1,0,0))

func start_tracker(avatar_base: AvatarBase) -> void:
	super(avatar_base)
	
	var puppeteer_manager = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH)
	if self.puppeteer_skel_direct:
		puppeteer_manager.remove_puppeteer(self.puppeteer_skel_direct)
		self.puppeteer_skel_direct = null
	
	self.puppeteer_skel_direct = puppeteer_manager.request_new_puppeteer(self, 
											PuppeteerBase.Type.SKELETON_DIRECT,
											&"Skeleton")
	
	var skeleton: Skeleton3D = avatar_base.get_skeleton()
	var bone_mapping: BoneMap = avatar_base.get_vrm_meta().humanoid_bone_mapping
	self.puppeteer_skel_direct.initialize(skeleton, bone_mapping)
	
	if self.media_pipe_pose:
		self.media_pipe_pose.stop()
	
	var mp_camera_manager: MpCameraManager = \
		get_node(TrackerManager.TRACKER_MANAGER_NODE_PATH).get_mp_camera_manager()
	var camera_helper := mp_camera_manager.get_camera(MpCameraManager.DEFAULT_CAMERA_INDEX)
	if not camera_helper:
		camera_helper = mp_camera_manager.init_camera(MpCameraManager.DEFAULT_CAMERA_INDEX, 
			MpCameraManager.DEFAULT_CAMERA_SIZE, true)
	self.media_pipe_pose = MediaPipePose.create_new(camera_helper.mp_helper)
	self.media_pipe_pose.connect(&"data_received", self._on_mp_data_received)
	
	self._setup_arm_data(skeleton, bone_mapping)

func stop_tracker():
	super()
	
	if self.media_pipe_pose:
		self.media_pipe_pose.stop()
		self.media_pipe_pose = null
	
	if self.puppeteer_skel_direct:
		var puppeteer_manager = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH)
		puppeteer_manager.remove_puppeteer(self.puppeteer_skel_direct)
		self.puppeteer_skel_direct = null

var test_setup_complete: bool = false

func setup_test_poses():
	var test_mesh := MeshInstance3D.new()
	test_mesh.mesh = BoxMesh.new()
	(test_mesh.mesh as BoxMesh).size = 2.0 * Vector3(0.01, 0.01, 0.01)
	
	var main: Main = get_node(Main.MAIN_NODE_PATH)
	var avatar_root := main.get_avatar_root_node()
	
	var mesh_node_names: Array[StringName] = [
		&"LeftShoulder", 
		&"RightShoulder",
		&"RightElbow",
		&"RightWrist",
	]
	
	for n: StringName in mesh_node_names:
		var tmp_mesh := test_mesh.duplicate()
		avatar_root.add_child(tmp_mesh)
		tmp_mesh.owner = avatar_root
		tmp_mesh.name = n
	
	test_mesh.queue_free()

func set_test_poses(pose_landmarks: MediaPipeLandmarks):
	if not self.test_setup_complete:
		self.setup_test_poses()
		self.test_setup_complete = true
	
	var main: Main = get_node(Main.MAIN_NODE_PATH)
	var avatar_root := main.get_avatar_root_node()
	
	var test_meshes: Array[Array] = [
		[ "LeftShoulder", MediaPipePose.LEFT_SHOULDER_IDX],
		[ "RightShoulder", MediaPipePose.RIGHT_SHOULDER_IDX],
		[ "RightElbow", MediaPipePose.RIGHT_ELBOW_IDX],
		[ "RightWrist", MediaPipePose.RIGHT_WRIST_IDX],
	]
	
	var coordinate_system_tf := Basis(Vector3(1,0,0), Vector3(0,-1,0), Vector3(0,0,-1)) # Basis(Vector3(1,0,0), Vector3(0,0,-1), Vector3(0,1,0))
	for n: Array in test_meshes:
		var test_mesh: MeshInstance3D = avatar_root.find_child(n[0], false)
		test_mesh.global_transform.origin = coordinate_system_tf * MediaPipePose.get_landmark_pos(pose_landmarks, n[1])
	
