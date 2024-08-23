class_name MediaPipeBase
extends RefCounted

enum Type {
	FACE_LANDMARKER,
	POSE_LANDMARKER,
}

static func create_new(_camera_helper: MediaPipeCameraHelper) -> MediaPipeBase:
	return null

func stop() -> Error:
	return OK
