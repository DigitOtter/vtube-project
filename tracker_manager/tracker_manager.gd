#class_name TrackerManager
extends Node

const TRACKER_MANAGER_NODE_PATH: NodePath = "/root/TrackerManager"

signal toggle_vmc_receiver(enabled: bool, propagate: bool)
signal toggle_media_pipe(enabled: bool, propagate: bool)

var _tracker_gui_menu := Gui.GUI_TAB_MENU_SCENE.instantiate()

func _on_tracker_toggle(enabled: bool, tracker_type: TrackerBase.Type):
	var tracker_name := TrackerBase.get_tracker_name(tracker_type)
	var tracker_node: TrackerBase = self.find_child(tracker_name)
	if enabled and not tracker_node:
		tracker_node = TrackerBase.create_new(tracker_type)
		tracker_node.name = tracker_name
		self.add_child(tracker_node)
		tracker_node.owner = self
		tracker_node.init_tracker()
	elif tracker_node:
		tracker_node.queue_free()

func _init_tracker_gui(tracker_type: TrackerBase.Type, tracker_toggle_signal: StringName, 
					   default_enable: bool = false) -> GuiElement.ElementData:
	var tracker_checkbox := GuiElement.ElementData.new()
	tracker_checkbox.Name = TrackerBase.get_tracker_name(tracker_type) + " Enabled"
	tracker_checkbox.OnDataChangedCallable = func(enabled: bool):
		self._on_tracker_toggle(enabled, tracker_type)
	tracker_checkbox.SetDataSignal = [ self, tracker_toggle_signal ]
	tracker_checkbox.Data = GuiElement.CheckBoxData.new()
	tracker_checkbox.Data.Default = default_enable
	
	return tracker_checkbox

func _init_gui():
	var gui_menu: GuiTabMenuBase = get_node(Gui.GUI_NODE_PATH).get_gui_menu()
	var elements: Array[GuiElement.ElementData] = []
	elements.append(self._init_tracker_gui(TrackerBase.Type.VMC_RECEIVER, &"toggle_vmc_receiver", false))
	elements.append(self._init_tracker_gui(TrackerBase.Type.MEDIA_PIPE, &"toggle_media_pipe", false))
	
	var tracker_menu_data := GuiElement.ElementData.new()
	tracker_menu_data.Name = "Tracker Settings"
	tracker_menu_data.Data = GuiElement.GuiTabMenuData.new()
	tracker_menu_data.Data.GuiTabMenuNode = self._tracker_gui_menu
	elements.append(tracker_menu_data)
	
	gui_menu.add_elements_to_tab("Trackers", elements)

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

func get_tracker_gui() -> GuiTabMenuBase:
	return self._tracker_gui_menu
