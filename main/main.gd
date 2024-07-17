class_name Main
extends Node

const MAIN_NODE_PATH: NodePath = "/root/Main"
const CONFIG_GUI_TAB_NAME := &"Config"

const CONFIG_DIALOG_SCRIPT: GDScript = preload("./scripts/config_loader.gd")
const CONFIG_DIALOG_NODE_NAME := &"ConfigLoader"

signal save_config_toggle(toggled: bool, propagate: bool)
signal load_config_toggle(toggled: bool, propagate: bool)

## Default path that all dialogs should open at
var _default_dialog_path: String = OS.get_executable_path()

func _on_config_file_selected(file_name: String, config_loader: ConfigLoader):
	if config_loader.is_save_mode():
		self.save_config(file_name)
	else:
		self.load_config(file_name)

#func _on_config_dialog_canceled(config_loader: ConfigLoader):
	## We're checking owner instead of the parent because, for some reason,
	## the dialog is cancelled twice before the node can be removed from the tree, 
	## causing a node busy error.
	#if config_loader.owner == self:
		#config_loader.owner = null
		#config_loader.hide()
		#self.remove_child(config_loader)
		#config_loader.queue_free()

## Open config file dialog. If [param_name save_mode] is true, save the config. Else, load it.
func _on_config_pressed(toggle: bool, save_mode: bool):
	if not toggle:
		return
	
	var config_loader: ConfigLoader = self.find_child(CONFIG_DIALOG_NODE_NAME, false)
	if not config_loader:
		var file_dialog_close = Gui.FILE_DIALOG_CLOSE_SCENE.instantiate()
		file_dialog_close.set_script(CONFIG_DIALOG_SCRIPT)
		config_loader = file_dialog_close
		config_loader.name = CONFIG_DIALOG_NODE_NAME
		self.add_child(config_loader)
		config_loader.owner = self
		
		config_loader.initialize(
			func(selected_file: String):
				self._on_config_file_selected(selected_file, config_loader),
			func(config_dir: String):
				self._default_dialog_path = config_dir + "/",
			save_mode
		)
		
		config_loader.current_dir = self.get_default_config_dialog_path()
	else:	
		# Set save/load mode of dialog
		config_loader.set_save_file_mode(save_mode)

func _init_input():
	InputSetup.set_input_default_key(&"save_config", KEY_S, true)
	InputSetup.set_input_default_key(&"load_config", KEY_L, true)

func _init_gui():
	var gui_menu: GuiTabMenuBase = self.get_node(Gui.GUI_NODE_PATH).get_gui_menu()
	var elements: Array[GuiElement.ElementData] = []
	
	var save_button := GuiElement.ElementData.new()
	save_button.Name = "Save Configuration"
	save_button.OnDataChangedCallable = func(toggle: bool): self._on_config_pressed(toggle, true)
	save_button.SetDataSignal = [ self, &"save_config_toggle" ]
	save_button.Data = GuiElement.ButtonData.new()
	(save_button.Data as GuiElement.ButtonData).Text = save_button.Name
	
	var load_button := GuiElement.ElementData.new()
	load_button.Name = "Load Configuration"
	load_button.OnDataChangedCallable = func(toggle: bool): self._on_config_pressed(toggle, false)
	load_button.SetDataSignal = [ self, &"load_config_toggle" ]
	load_button.Data = GuiElement.ButtonData.new()
	(load_button.Data as GuiElement.ButtonData).Text = load_button.Name
	
	elements.append_array([save_button, load_button])
	gui_menu.add_elements_to_tab(CONFIG_GUI_TAB_NAME, elements)
	#gui_menu.push_tab_to_front(CONFIG_GUI_TAB_NAME)

func _init_default_dialog_path():
	var path: String = OS.get_executable_path()
	
	# Remove executable name from end of path
	var split = path.rsplit("/", false, 1)
	if not split.is_empty():
		path = split[0]
	
	# If vtube_project is started in a Flatpak, set user's home directory as default
	if path.begins_with("/app"):
		self._default_dialog_path = "~"
	else:
		self._default_dialog_path = path

func _input(event):
	if event.is_action_pressed(&"save_config"):
		self.emit_signal(&"save_config_toggle", true, true)
	elif event.is_action_pressed(&"load_config"):
		self.emit_signal(&"load_config_toggle", true, true)

func _ready():
	get_tree().get_root().set_transparent_background(true)
	
	self._init_default_dialog_path()
	self._init_gui()
	self._init_input()
	
	# Open gui once program has finished loading
	var root_node: = get_node("/root")
	root_node.connect(&"ready", func():
		var gui := get_node(Gui.GUI_NODE_PATH)
		gui.call_deferred(&"open_gui_window")
	)

func get_avatar_viewport() -> SubViewport:
	return %AvatarViewport

func get_avatar_viewport_container() -> SubViewportContainer:
	return %AvatarViewportContainer

func connect_avatar_loaded(fcn: Callable) -> Error:
	return %AvatarRoot.connect(&"avatar_loaded", fcn)

func connect_avatar_unloaded(fcn: Callable) -> Error:
	return %AvatarRoot.connect(&"avatar_unloaded", fcn)

func is_avatar_loaded() -> bool:
	return %AvatarRoot.is_avatar_loaded()

func get_avatar_root_node() -> Node:
	return %AvatarRoot

func get_post_processing_node() -> Control:
	return %PostProcessing

func set_default_config_dialog_path(path: String):
	self._default_dialog_path = path

func get_default_config_dialog_path():
	return self._default_dialog_path

func load_config(file_name: String):
	var gui: GuiTabMenuBase = self.get_node(Gui.GUI_NODE_PATH).get_gui_menu()
	ConfigLoader.load_config(file_name, gui)

func save_config(file_name: String):
	var gui: GuiTabMenuBase = self.get_node(Gui.GUI_NODE_PATH).get_gui_menu()
	ConfigLoader.save_config(file_name, gui)
