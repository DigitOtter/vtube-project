extends Node

const EFFECTS_NODE_PATH: NodePath = "/root/Effects"

func _input(event):
	%ExternalLightingViewport._handle_input(event)

func _ready():
	pass

func set_render_camera(camera: Camera3D) -> bool:
	%PropsControl.camera = camera
	return true

func get_props_control() -> PropsControl:
	return %PropsControl
