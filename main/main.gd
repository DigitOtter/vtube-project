class_name Main
extends Node

const MAIN_NODE_PATH: NodePath = "/root/Main"
const CONFIG_GUI_TAB_NAME := &"Config"
const CONFIG_LOADER_NODE := preload("./scenes/config_loader.tscn")

signal save_config(toggled: bool, propagate: bool)
signal load_config(toggled: bool, propagate: bool)
signal save_file_change(name: String, propagate: bool)

func _on_config_file_selected(file_name: String, config_loader: ConfigLoader):
	var gui: GuiElements = self.get_node(Gui.GUI_NODE_PATH).get_gui_elements()
	if config_loader.is_save_mode():
		config_loader.save_config(file_name, gui)
	else:
		config_loader.load_config(file_name, gui)

func _on_config_dialog_canceled(config_loader: ConfigLoader):
	# We're checking owner instead of the parent because, for some reason,
	# the dialog is cancelled twice before the node can be removed from the tree, 
	# causing a node busy error.
	if config_loader.owner == self:
		config_loader.owner = null
		config_loader.hide()
		self.remove_child(config_loader)
		config_loader.queue_free()

func _on_config_pressed(toggle: bool, save_config: bool):
	if not toggle:
		return
	
	var config_loader: ConfigLoader = self.find_child("ConfigLoader", false)
	if not config_loader:
		config_loader = CONFIG_LOADER_NODE.instantiate()
		self.add_child(config_loader)
		config_loader.owner = self
		
		# Connect signals
		config_loader.connect(&"canceled", func(): self._on_config_dialog_canceled(config_loader))
		config_loader.connect(&"file_selected", func(file): self._on_config_file_selected(file, config_loader))
	
	# Set save/load mode
	if save_config: 
		config_loader.set_save_mode()
	else:
		config_loader.set_load_mode()

func _init_gui():
	var gui: GuiElements = self.get_node(Gui.GUI_NODE_PATH).get_gui_elements()
	var elements: Array[GuiElements.ElementData] = []
	
	var save_button := GuiElements.ElementData.new()
	save_button.Name = "Save Configuration"
	save_button.OnDataChangedCallable = func(toggle: bool): self._on_config_pressed(toggle, true)
	save_button.SetDataSignal = [ self, &"save_config" ]
	save_button.Data = GuiElements.ButtonData.new()
	(save_button.Data as GuiElements.ButtonData).Text = save_button.Name
	
	var load_button := GuiElements.ElementData.new()
	load_button.Name = "Load Configuration"
	load_button.OnDataChangedCallable = func(toggle: bool): self._on_config_pressed(toggle, false)
	load_button.SetDataSignal = [ self, &"load_config" ]
	load_button.Data = GuiElements.ButtonData.new()
	(load_button.Data as GuiElements.ButtonData).Text = load_button.Name
	
	elements.append_array([save_button, load_button])
	gui.add_or_create_elements_to_tab_name(CONFIG_GUI_TAB_NAME, elements)

func _input(event):
	if event.is_action_pressed("save_avatar"):
		var data: Dictionary = Gui.get_gui_elements().save_data()
		print(data)

func _ready():
	get_tree().get_root().set_transparent_background(true)
	
	self._init_gui()
	
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
