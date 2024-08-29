class_name MediaPipePose
extends MediaPipeBase

const TASK_FILE := &"res://addons/GDMP/pose_landmarker_full.task"

const LEFT_SHOULDER_IDX:  int = 11
const RIGHT_SHOULDER_IDX: int = 12

const LEFT_ELBOW_IDX:  int = 13
const RIGHT_ELBOW_IDX: int = 14

const LEFT_WRIST_IDX:  int = 15
const RIGHT_WRIST_IDX: int = 16

const LEFT_PINKY_IDX:  int = 17
const RIGHT_PINKY_IDX: int = 18

const LEFT_INDEX_IDX:  int = 19
const RIGHT_INDEX_IDX: int = 20

const LEFT_THUMB_IDX:  int = 21
const RIGHT_THUMB_IDX: int = 22

const LEFT_HIP_IDX:  int = 23
const RIGHT_HIP_IDX: int = 24

const NOSE_IDX: int      = 0
const LEFT_EAR_IDX: int  = 7
const RIGHT_EAR_IDX: int = 8

class ArmJointAngles:
	var shoulder := Quaternion.IDENTITY
	var elbow: float = 0.0
	var wrist := Quaternion.IDENTITY

class JointAngles:
	var hip := Quaternion.IDENTITY
	var shoulder := Quaternion.IDENTITY
	var neck := Quaternion.IDENTITY
	var left_arm := ArmJointAngles.new()
	var right_arm := ArmJointAngles.new()

signal data_received(pose_landmarks: MediaPipeLandmarks)

var _task: MediaPipePoseLandmarker = null
var _camera_helper: MediaPipeCameraHelper = null

static func create_new(camera_helper: MediaPipeCameraHelper) -> MediaPipePose:
	var r := MediaPipePose.new()
	
	var delegate := MediaPipeTaskBaseOptions.DELEGATE_CPU #\
	#	if OS.get_name().to_lower().contains("linux") else MediaPipeTaskBaseOptions.DELEGATE_CPU
	var base_options := MediaPipeTaskBaseOptions.new()
	base_options.delegate = delegate

	var file := FileAccess.open(TASK_FILE, FileAccess.READ)
	base_options.model_asset_buffer = file.get_buffer(file.get_length())

	r._task = MediaPipePoseLandmarker.new()
	r._task.initialize(base_options, MediaPipeTask.RUNNING_MODE_LIVE_STREAM, 1, 0.6, 0.6, 0.6, false)
	
	r._camera_helper = camera_helper
	r._camera_helper.new_frame.connect(func(image: MediaPipeImage) -> void:
		if delegate == MediaPipeTaskBaseOptions.DELEGATE_CPU and image.is_gpu_image():
			image.convert_to_cpu()
		
		r._task.detect_async(image, Time.get_ticks_msec())
	)
	
	r._task.result_callback.connect(func(result: MediaPipePoseLandmarkerResult, _image: MediaPipeImage, _timestamp_ms: int) -> void:
		r.call_deferred(&"_on_new_poses_received", result, _image, _timestamp_ms)
	)
	
	return r

func stop() -> Error:
	return OK

static func get_landmark_pos(pose_landmarks: MediaPipeLandmarks, idx: int) -> Vector3:
	var landmark: MediaPipeLandmark = pose_landmarks.landmarks[idx]
	return Vector3(landmark.x, landmark.y, landmark.z)

func _on_new_poses_received(result: MediaPipePoseLandmarkerResult, _image: MediaPipeImage, _timestamp_ms: int) -> void:
	if !result.pose_world_landmarks.is_empty():
		self.data_received.emit(
			result.pose_world_landmarks[0],
		)

static func _project_onto_line(line_orig: Vector3, line_norm: Vector3, point: Vector3) -> Vector3:
	var dist: float = (point - line_orig).dot(line_norm)
	return line_orig + dist * line_norm

static func _project_onto_plane(plane_orig: Vector3, plane_norm: Vector3, point: Vector3) -> Vector3:
	var dist: float = (point - plane_orig).dot(plane_norm)
	return point - dist * plane_norm

static func _compute_rot(vec_a: Vector3, vec_b: Vector3) -> Quaternion:
	var rot_axis: Vector3 = vec_a.cross(vec_b)
	var rot_l: float = rot_axis.length()
	if is_zero_approx(rot_l):
		return Quaternion.IDENTITY
	
	var rot_angle: float = atan2(rot_l, vec_a.dot(vec_b))
	return Quaternion(rot_axis/rot_l, rot_angle)

static func compute_arm_angles(joint_poses: Array[Vector3], 
		base_vec: Vector3, base_elbow_rot_axis: Vector3) -> ArmJointAngles:
	var arm_joint_angles := ArmJointAngles.new()
	var base_tf: Quaternion = MediaPipePose._compute_rot(Vector3(0,1,0), base_vec)
	
	var upper_arm_vec: Vector3 = joint_poses[1] - joint_poses[0]
	var forearm_vec: Vector3 = joint_poses[2] - joint_poses[1]
	var shoulder_rot: Quaternion = MediaPipePose._compute_rot(base_vec, upper_arm_vec)
	
	base_elbow_rot_axis = shoulder_rot * base_elbow_rot_axis
	var elbow_rot_axis: Vector3 = upper_arm_vec.cross(forearm_vec)
	var elbow_rot: float = atan2(elbow_rot_axis.length(), upper_arm_vec.dot(forearm_vec))
	
	var shoulder_adjust_rot: Quaternion = MediaPipePose._compute_rot(
		MediaPipePose._project_onto_plane(Vector3.ZERO, upper_arm_vec, base_elbow_rot_axis),
		MediaPipePose._project_onto_plane(Vector3.ZERO, upper_arm_vec, elbow_rot_axis))
	
	arm_joint_angles.shoulder = shoulder_adjust_rot * shoulder_rot * base_tf
	arm_joint_angles.elbow = elbow_rot
	
	return arm_joint_angles

static func compute_joint_angles(mp_poses: MediaPipeLandmarks) -> JointAngles:
	var joint_angles := JointAngles.new()
	
	const TOP_TO_RIGHT_TF := Quaternion(Vector3(0,0,1), -PI/2)
	
	var left_hip: Vector3 = MediaPipePose.get_landmark_pos(mp_poses, LEFT_HIP_IDX)
	var right_hip: Vector3 = MediaPipePose.get_landmark_pos(mp_poses, RIGHT_HIP_IDX)
	joint_angles.hip = TOP_TO_RIGHT_TF.inverse() \
		* MediaPipePose._compute_rot(Vector3(1,0,0), right_hip - left_hip) * TOP_TO_RIGHT_TF
	
	var left_shoulder: Vector3 = MediaPipePose.get_landmark_pos(mp_poses, LEFT_SHOULDER_IDX)
	var right_shoulder: Vector3 = MediaPipePose.get_landmark_pos(mp_poses, RIGHT_SHOULDER_IDX)
	joint_angles.shoulder = TOP_TO_RIGHT_TF.inverse() \
		* MediaPipePose._compute_rot(Vector3(1,0,0), right_shoulder - left_shoulder) * TOP_TO_RIGHT_TF
	
	joint_angles.left_arm = MediaPipePose.compute_arm_angles(\
		[left_shoulder, MediaPipePose.get_landmark_pos(mp_poses, LEFT_ELBOW_IDX), MediaPipePose.get_landmark_pos(mp_poses, LEFT_WRIST_IDX)],
		Vector3(1,0,0), Vector3(0,-1,0))
	
	joint_angles.right_arm = MediaPipePose.compute_arm_angles(\
		[right_shoulder, MediaPipePose.get_landmark_pos(mp_poses, RIGHT_ELBOW_IDX), MediaPipePose.get_landmark_pos(mp_poses, RIGHT_WRIST_IDX)],
		Vector3(-1,0,0), Vector3(0,1,0))
	
	return joint_angles
