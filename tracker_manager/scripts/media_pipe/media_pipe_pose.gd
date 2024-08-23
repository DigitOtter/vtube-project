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
	r._task.initialize(base_options, MediaPipeTask.RUNNING_MODE_LIVE_STREAM, 1, 0.5, 0.5, 0.5, false)
	
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
