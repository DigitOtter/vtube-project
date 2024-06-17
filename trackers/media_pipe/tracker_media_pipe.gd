class_name TrackerMediaPipe
extends TrackerBase

class InitialPoses:
	var head:= Transform3D.IDENTITY
	var hip:= Transform3D.IDENTITY
	var left_hand:= Transform3D.IDENTITY
	var right_hand:= Transform3D.IDENTITY
	var left_leg:= Transform3D.IDENTITY
	var right_leg:= Transform3D.IDENTITY

var mediapipe: MediaPipe = null

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

func _setup_ik(avatar_root: Node) -> Error:
	var skeleton = avatar_root.find_child("GeneralSkeleton", false)
	self.puppeteer_skeleton.initialize(skeleton, TrackerVrmUtils.get_vrm_ik_bone_names(avatar_root), {})
	
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

func _setup_blend_shapes(avatar_root: Node, reset_track: StringName) -> void:
	var animations: AnimationPlayer = avatar_root.find_child("AnimationPlayer", true)
	if animations:
		var animation_tracks: Array[String] = Array(Array(animations.get_animation_list()), TYPE_STRING, &"", null)
		animation_tracks.erase(reset_track as String)
		self.puppeteer_track.initialize(animations, animation_tracks, reset_track)

func _setup_puppeteers(avatar_scene: Node):
	var puppeteer_manager = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH)
	# Remove old puppeteers
	if self.puppeteer_track:
		puppeteer_manager.remove_puppeteer(self.puppeteer_track)
	self.puppeteer_track = puppeteer_manager.request_new_puppeteer(self, PuppeteerBase.Type.TRACK_TREE)
	
	if self.puppeteer_skeleton:
		puppeteer_manager.remove_puppeteer(self.puppeteer_skeleton)
	self.puppeteer_skeleton = puppeteer_manager.request_new_puppeteer(self, PuppeteerBase.Type.SKELETON_IK)
	
	# Initialize skeleton and blendshape puppeteers
	# TODO: For now, only one avatar is loaded. Maybe change this in the future?
	var avatar_root = avatar_scene.get_child(0)
	self._setup_blend_shapes(avatar_root, "RESET")
	self._setup_ik(avatar_root)

func _on_avatar_loaded(avatar_scene: Node):
	self.restart_tracker(avatar_scene)

func start_tracker(avatar_scene: Node) -> void:
	if self.mediapipe:
		self.mediapipe.stop()
	
	self._setup_puppeteers(avatar_scene)
	
	self.mediapipe = MediaPipe.start(null)
	self.mediapipe.connect("data_received", self.handle_mediapipe)
	
	super(avatar_scene)

func stop_tracker() -> void:
	if self.mediapipe:
		self.mediapipe.stop()
	
	super()

func set_media_pipe_base_head():
	self._media_pipe_base_head_pose = null

static func compute_gaze_blend_shapes(blend_shapes: Array[MediaPipeCategory]) -> Array[PuppeteerTrackTree.TrackTarget]:
	const TrackTarget = PuppeteerTrackTree.TrackTarget
	var gaze: Array[float] = MediaPipe.get_gaze_direction(blend_shapes)
	var gaze_shapes: Array[PuppeteerTrackTree.TrackTarget] = [
		TrackTarget.new(), TrackTarget.new(), TrackTarget.new(), TrackTarget.new()
	]
	gaze_shapes[0].name = "lookdown"
	gaze_shapes[1].name = "lookleft"
	gaze_shapes[2].name = "lookright"
	gaze_shapes[3].name = "lookup"
	
	if gaze[0] < 0:
		gaze_shapes[1].target = -gaze[0]
		gaze_shapes[2].target = 0
	else:
		gaze_shapes[1].target = 0
		gaze_shapes[2].target = gaze[0]
	if gaze[1] < 0:
		gaze_shapes[0].target = -gaze[1]
		gaze_shapes[3].target = 0
	else:
		gaze_shapes[0].target = 0
		gaze_shapes[3].target = gaze[1]
	
	return gaze_shapes

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
	
	var gaze_shapes := self.compute_gaze_blend_shapes(blend_shapes)
	self.puppeteer_track.call_deferred(
		"set_track_targets",
		gaze_shapes
	)
