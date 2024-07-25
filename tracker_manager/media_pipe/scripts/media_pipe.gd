class_name MediaPipe
extends AbstractTracker

# TODO camera helper on MacOS needs to work with permissions

const TASK_FILE := &"res://addons/GDMP/face_landmarker_v2_with_blendshapes.task"

var _task: MediaPipeFaceLandmarker = null
var _camera_helper: MediaPipeCameraHelper = null

## Starting the camera helper takes a while, so use a thread instead.
var _start_thread: Thread = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			_clean_up_thread()

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _clean_up_thread() -> void:
	if self._start_thread != null and self._start_thread.is_alive():
		self._start_thread.wait_to_finish()

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func get_name() -> StringName:
	return &"MediaPipe"

static func get_type() -> BuiltinTrackers:
	return BuiltinTrackers.MEDIA_PIPE

static func start(_data: Resource) -> AbstractTracker:
	var r := MediaPipe.new()

	# TODO switch based off of OS, Linux can use GPU i think
	var delegate := MediaPipeTaskBaseOptions.DELEGATE_CPU
	var base_options := MediaPipeTaskBaseOptions.new()
	base_options.delegate = delegate

	var file := FileAccess.open(TASK_FILE, FileAccess.READ)
	base_options.model_asset_buffer = file.get_buffer(file.get_length())

	r._task = MediaPipeFaceLandmarker.new()
	r._task.initialize(base_options, MediaPipeTask.RUNNING_MODE_LIVE_STREAM, 1, 0.5, 0.5, 0.5, true, true)

	r._camera_helper = MediaPipeCameraHelper.new()
	r._camera_helper.new_frame.connect(func(image: MediaPipeImage) -> void:
		if delegate == MediaPipeTaskBaseOptions.DELEGATE_CPU and image.is_gpu_image():
			image.convert_to_cpu()

		r._task.detect_async(image, Time.get_ticks_msec())
	)

	r._camera_helper.set_mirrored(true)
	
	#r._task = task
	#r._camera_helper = camera_helper
	
	r._task.result_callback.connect(func(result: MediaPipeFaceLandmarkerResult, _image: MediaPipeImage, _timestamp_ms: int) -> void:
		if !result.facial_transformation_matrixes.is_empty():
			r.data_received.emit(
				result.facial_transformation_matrixes[0],
				result.face_blendshapes[0].categories
			)
	)
	
	r._start_thread = Thread.new()
	r._start_thread.start(func() -> void:
		r._camera_helper.start(MediaPipeCameraHelper.FACING_FRONT, Vector2(640, 480))
	)
	
	return r

func stop() -> Error:
	# Wait for camera helper to finish starting before closing it
	self._clean_up_thread()
	self._camera_helper.close()
	
	return OK
