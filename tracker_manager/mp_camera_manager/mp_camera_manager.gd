class_name MpCameraManager
extends Resource

const DEFAULT_CAMERA_INDEX: int = 0
const DEFAULT_CAMERA_SIZE := Vector2(640, 480)

class CameraData:
	var mp_helper: MediaPipeCameraHelper = null
	var index: int = -1
	var size := Vector2.ZERO

## Available cameras. Should be of the form { <cam_index as int>: CameraData }
var _camera_helpers: Dictionary = {}

## Startup threads. Should be of the form { <cam_index as int>: Thread }
var _start_threads: Dictionary = {}

func init_camera(cam_index: int, cam_size: Vector2, mirrored: bool) -> CameraData:
	# Erase previous camera
	var cam_start_thread: Thread = self._start_threads.get(cam_index, null)
	if cam_start_thread:
		cam_start_thread.wait_to_finish()
		self._start_threads.erase(cam_index)
		cam_start_thread = null
	
	self._camera_helpers.erase(cam_index)
	
	# Start new camera
	cam_start_thread = Thread.new()
	var camera_helper := MediaPipeCameraHelper.new()
	camera_helper.set_mirrored(mirrored)
	cam_start_thread.start(func():
		camera_helper.start(cam_index, cam_size))
	
	var camera_data := CameraData.new()
	camera_data.index = cam_index
	camera_data.size = cam_size
	camera_data.mp_helper = camera_helper
	
	self._start_threads[cam_index]  = cam_start_thread
	self._camera_helpers[cam_index] = camera_data
	
	return camera_data

func get_camera(cam_index: int) -> CameraData:
	return self._camera_helpers.get(cam_index, null)

func is_camera_ready(cam_index: int) -> bool:
	var camera_helper: CameraData = self._camera_helpers.get(cam_index, null)
	if camera_helper == null:
		return false
	
	# Start thread was deleted already, so camera_helper is ready
	var cam_start_thread: Thread = self._start_threads.get(cam_index, null)
	if cam_start_thread == null:
		return true
	
	# Still starting
	if cam_start_thread.is_alive():
		return false
	
	# Start finished, erase thread data
	cam_start_thread.wait_to_finish()
	self._start_threads.erase(cam_index)
	return true

func wait_for_camera_ready(cam_index: int) -> bool:
	var camera_helper: CameraData = self._camera_helpers.get(cam_index, null)
	if camera_helper == null:
		return false
	
	# Start thread was deleted already, so camera_helper is ready
	var cam_start_thread: Thread = self._start_threads.get(cam_index, null)
	if cam_start_thread == null:
		return true
	
	cam_start_thread.wait_to_finish()
	self._start_threads.erase(cam_index)
	return true

func cleanup():
	for thread: Thread in self._start_threads.values():
		thread.wait_to_finish()
	self._start_threads.clear()
	
	self._camera_helpers.clear()
