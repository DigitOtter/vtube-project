#class_name Trackers
extends Node

const TRACKERS_NODE_PATH = "/root/Trackers"

const VMC_RECEIVER_NAME = &"VmcReceiver"
const MEDIA_PIPE_NAME = &"MediaPipe"

signal toggle_vmc_receiver(enabled: bool, propagate: bool)
signal toggle_media_pipe(enabled: bool, propagate: bool)

var _tracker_gui_elements := GuiElements.new()

func _on_tracker_toggle(enabled: bool, tracker: GDScript, tracker_name: StringName):
	var tracker_node: TrackerBase = self.find_child(tracker_name)
	if enabled and not tracker_node:
		tracker_node = tracker.new()
		tracker_node.name = tracker_name
		self.add_child(tracker_node)
		tracker_node.owner = self
		tracker_node.init_tracker()
	elif tracker_node:
		tracker_node.queue_free()

func _init_tracker_gui(tracker_name: StringName, tracker: GDScript, tracker_toggle_signal: StringName, 
					   default_enable: bool = false) -> GuiElements.ElementData:
	var tracker_checkbox: GuiElements.ElementData = GuiElements.ElementData.new()
	tracker_checkbox.Name = tracker_name + " Enabled"
	tracker_checkbox.OnDataChangedCallable = func(enabled: bool):
		self._on_tracker_toggle(enabled, tracker, tracker_name)
	tracker_checkbox.SetDataSignal = [ self, tracker_toggle_signal ]
	tracker_checkbox.Data = GuiElements.CheckBoxData.new()
	tracker_checkbox.Data.Default = default_enable
	
	return tracker_checkbox

func _init_gui():
	var elements: Array[GuiElements.ElementData] = []
	elements.append(self._init_tracker_gui(VMC_RECEIVER_NAME, TrackerVmcReceiver, &"toggle_vmc_receiver", false))
	elements.append(self._init_tracker_gui(MEDIA_PIPE_NAME, TrackerMediaPipe, &"toggle_media_pipe", false))
	
	var gui_elements_data := GuiElements.ElementData.new()
	gui_elements_data.Name = "Tracker Settings"
	gui_elements_data.Data = GuiElements.GuiElementsData.new()
	gui_elements_data.Data.GuiElementsNode = self._tracker_gui_elements 
	elements.append(gui_elements_data)
	
	Gui.get_gui_elements().add_element_tab("Trackers", elements)

func _on_avatar_loaded(avatar_root: Node):
	# Restart all trackers
	for child in self.get_children():
		if child is TrackerBase:
			var c = child as TrackerBase
			c.restart_tracker(avatar_root)

func _on_avatar_unloaded(avatar_root: Node):
	# Stop all trackers
	for child in self.get_children():
		if child is TrackerBase:
			var c = child as TrackerBase
			c.stop_tracker()

func _ready():
	self._init_gui()
	
	var main: Main = get_node(Main.MAIN_NODE_PATH)
	main.connect_avatar_loaded(self._on_avatar_loaded)
	main.connect_avatar_unloaded(self._on_avatar_unloaded)

func get_tracker_gui() -> GuiElements:
	return self._tracker_gui_elements
