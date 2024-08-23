class_name MediaPipeFace
extends MediaPipeBase

const TASK_FILE := &"res://addons/GDMP/face_landmarker_v2_with_blendshapes.task"

signal data_received(projection: Projection, blend_shapes: Array[MediaPipeCategory])

var _task: MediaPipeFaceLandmarker = null
var _camera_helper: MediaPipeCameraHelper = null

static func create_new(camera_helper: MediaPipeCameraHelper) -> MediaPipeFace:
	var r := MediaPipeFace.new()
	
	var delegate := MediaPipeTaskBaseOptions.DELEGATE_CPU #\
	#	if OS.get_name().to_lower().contains("linux") else MediaPipeTaskBaseOptions.DELEGATE_CPU
	var base_options := MediaPipeTaskBaseOptions.new()
	base_options.delegate = delegate

	var file := FileAccess.open(TASK_FILE, FileAccess.READ)
	base_options.model_asset_buffer = file.get_buffer(file.get_length())

	r._task = MediaPipeFaceLandmarker.new()
	r._task.initialize(base_options, MediaPipeTask.RUNNING_MODE_LIVE_STREAM, 1, 0.5, 0.5, 0.5, true, true)
	
	r._camera_helper = camera_helper
	r._camera_helper.new_frame.connect(func(image: MediaPipeImage) -> void:
		if delegate == MediaPipeTaskBaseOptions.DELEGATE_CPU and image.is_gpu_image():
			image.convert_to_cpu()

		r._task.detect_async(image, Time.get_ticks_msec())
	)
	
	r._task.result_callback.connect(func(result: MediaPipeFaceLandmarkerResult, _image: MediaPipeImage, _timestamp_ms: int) -> void:
		if !result.facial_transformation_matrixes.is_empty():
			r.data_received.emit(
				result.facial_transformation_matrixes[0],
				result.face_blendshapes[0].categories
			)
	)
	
	return r

func stop() -> Error:
	return OK
