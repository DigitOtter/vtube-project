class_name TrackerMediaPipe
extends TrackerBase

const TRACKER_NAME := &"MediaPipe"

class InitialPoses:
	var head:= Transform3D.IDENTITY
	var hip:= Transform3D.IDENTITY
	var left_hand:= Transform3D.IDENTITY
	var right_hand:= Transform3D.IDENTITY
	var left_leg:= Transform3D.IDENTITY
	var right_leg:= Transform3D.IDENTITY

var mediapipe_face: MediaPipeFace = null

var puppeteer_skeleton: PuppeteerSkeletonIk = null
var puppeteer_track: PuppeteerTrackTree = null

var initial_head       := Transform3D.IDENTITY
var initial_hip        := Transform3D.IDENTITY
var initial_left_hand  := Transform3D.IDENTITY
var initial_right_hand := Transform3D.IDENTITY
var initial_left_foot  := Transform3D.IDENTITY
var initial_right_foot := Transform3D.IDENTITY

## Either null or Transform3D
var _media_pipe_base_head_pose = null

static func get_type_name() -> StringName:
	return &"MediaPipeFace"

func _setup_ik(avatar_base: AvatarBase) -> Error:
	var skeleton = avatar_base.get_skeleton()
	self.puppeteer_skeleton.initialize(skeleton, TrackerVrmUtils.get_vrm_ik_bone_names(avatar_base), {})
	
	# Get initial poses
	var initial_poses := self.puppeteer_skeleton.get_skeleton_poses()
	self.initial_head = initial_poses.get(PuppeteerSkeletonIk.IkTarget.HEAD, Transform3D.IDENTITY)
	self.initial_hip = initial_poses.get(PuppeteerSkeletonIk.IkTarget.HIP, Transform3D.IDENTITY)
	self.initial_left_hand = initial_poses.get(PuppeteerSkeletonIk.IkTarget.LEFT_HAND, Transform3D.IDENTITY)
	self.initial_right_hand = initial_poses.get(PuppeteerSkeletonIk.IkTarget.RIGHT_HAND, Transform3D.IDENTITY)
	self.initial_left_foot = initial_poses.get(PuppeteerSkeletonIk.IkTarget.LEFT_FOOT, Transform3D.IDENTITY)
	self.initial_right_foot = initial_poses.get(PuppeteerSkeletonIk.IkTarget.RIGHT_FOOT, Transform3D.IDENTITY)
	
	# Move target nodes to skeleton poses
	self.puppeteer_skeleton.ren_ik.head_target_spatial.global_transform = self.initial_head
	self.puppeteer_skeleton.ren_ik.hip_target_spatial.global_transform = self.initial_hip
	self.puppeteer_skeleton.ren_ik.hand_left_target_spatial.global_transform = self.initial_left_hand
	self.puppeteer_skeleton.ren_ik.hand_right_target_spatial.global_transform = self.initial_right_hand
	self.puppeteer_skeleton.ren_ik.foot_left_target_spatial.global_transform = self.initial_left_foot
	self.puppeteer_skeleton.ren_ik.foot_right_target_spatial.global_transform = self.initial_right_foot
	
	self.puppeteer_skeleton.head_target.align_target_with_node_pose()
	self.puppeteer_skeleton.hip_target.align_target_with_node_pose()
	
	self.puppeteer_skeleton.left_hand_target.align_target_with_node_pose()
	self.puppeteer_skeleton.left_hand_target.global_target.origin.y = -164
	self.puppeteer_skeleton.left_hand_target.global_target.origin.x = 164
	
	self.puppeteer_skeleton.right_hand_target.align_target_with_node_pose()
	self.puppeteer_skeleton.right_hand_target.global_target.origin.y = -164
	self.puppeteer_skeleton.right_hand_target.global_target.origin.x = -164
	
	self.puppeteer_skeleton.left_foot_target.align_target_with_node_pose()
	self.puppeteer_skeleton.right_foot_target.align_target_with_node_pose()
	
	self.puppeteer_skeleton.ren_ik.live_preview = true
	
	return OK

func _setup_blend_shapes(avatar_base: AvatarBase, reset_track: StringName) -> void:
	var anim_player: AnimationPlayer = avatar_base.get_animation_player()
	var anim_tree: AvatarAnimationTree = avatar_base.get_animation_tree()
	if anim_tree:
		var animation_tracks: Array[String] = Array(Array(anim_player.get_animation_list()), TYPE_STRING, &"", null)
		animation_tracks.erase(reset_track as String)
		self.puppeteer_track.initialize(anim_tree, animation_tracks, reset_track)

func _setup_puppeteers(avatar_base: AvatarBase):
	var puppeteer_manager = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH)
	# Remove old puppeteers
	if self.puppeteer_track:
		puppeteer_manager.remove_puppeteer(self.puppeteer_track)
	self.puppeteer_track = puppeteer_manager.request_new_puppeteer(self, PuppeteerBase.Type.TRACK_TREE, "blend_shapes")
	
	if self.puppeteer_skeleton:
		puppeteer_manager.remove_puppeteer(self.puppeteer_skeleton)
	self.puppeteer_skeleton = puppeteer_manager.request_new_puppeteer(self, PuppeteerBase.Type.SKELETON_IK, "skel")
	
	# Initialize skeleton and blendshape puppeteers
	# TODO: For now, only one avatar is loaded. Maybe change this in the future?
	self._setup_blend_shapes(avatar_base, "")
	self._setup_ik(avatar_base)

func _on_avatar_loaded(avatar_base: AvatarBase):
	self.restart_tracker(avatar_base)

func start_tracker(avatar_base: AvatarBase) -> void:
	if self.mediapipe_face:
		self.mediapipe_face.stop()
	
	self._setup_puppeteers(avatar_base)
	
	var mp_camera_manager: MpCameraManager = \
		get_node(TrackerManager.TRACKER_MANAGER_NODE_PATH).get_mp_camera_manager()
	var mp_camera_helper := mp_camera_manager.get_camera(MpCameraManager.DEFAULT_CAMERA_INDEX)
	if not mp_camera_helper:
		mp_camera_helper = mp_camera_manager.init_camera(MpCameraManager.DEFAULT_CAMERA_INDEX, \
			MpCameraManager.DEFAULT_CAMERA_SIZE, true)
	
	self.mediapipe_face = MediaPipeFace.create_new(mp_camera_helper.mp_helper)
	self.mediapipe_face.connect("data_received", self.handle_mediapipe)
	
	super(avatar_base)

func stop_tracker() -> void:
	if self.mediapipe_face:
		self.mediapipe_face.stop()
	
	super()

func set_media_pipe_base_head():
	self._media_pipe_base_head_pose = null

func handle_mediapipe(projection: Projection, blend_shapes: Array[MediaPipeCategory]) -> void:
	var tx := Transform3D(projection).inverse()
	
	if not self._media_pipe_base_head_pose:
		self._media_pipe_base_head_pose = tx
	
	# Follow head movement
	var head_tf = self.puppeteer_skeleton.reset_head * tx * self._media_pipe_base_head_pose.inverse()
	self.puppeteer_skeleton.head_target.call_deferred(
		"set_target_pose",
		head_tf
	)
	
	# Set blend shapes
	self.puppeteer_track.call_deferred(
		"set_track_targets_mp", 
		blend_shapes
	)
