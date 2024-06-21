class_name Main
extends Node

const MAIN_NODE_PATH: NodePath = "/root/Main"

func _input(event):
	if event.is_action_pressed("save_avatar"):
		var data: Dictionary = Gui.get_gui_elements().save_data()
		print(data)

func _ready():
	get_tree().get_root().set_transparent_background(true)
	
	# Open gui once program has finished loading
	var root_node: = get_node("/root")
	root_node.connect("ready", func():
		var gui := get_node(Gui.GUI_NODE_PATH)
		gui.call_deferred("open_gui_window")
	)

func get_avatar_viewport() -> SubViewport:
	return %AvatarViewport

func get_avatar_viewport_container() -> SubViewportContainer:
	return %AvatarViewportContainer

func connect_avatar_loaded(fcn: Callable) -> Error:
	return %AvatarRoot.connect("avatar_loaded", fcn)

func connect_avatar_unloaded(fcn: Callable) -> Error:
	return %AvatarRoot.connect("avatar_unloaded", fcn)

func is_avatar_loaded() -> bool:
	return %AvatarRoot.is_avatar_loaded()

func get_avatar_root_node() -> Node:
	return %AvatarRoot

func get_post_processing_node() -> Control:
	return %PostProcessing
