extends Node

const MODEL_IMPORTER = preload("./scripts/model_importer.gd")
const MODEL_LOADER_NODE_NAME := &"ModelLoaderDialog"

signal open_dialog_requested(toggle: bool, propagate: bool)
signal avatar_loaded(avatar_node: Node)
signal avatar_unloaded(avatar_node: Node)

var _loaded_model_path: String = ""

func _on_load_model_request(toggled: bool):
	if not toggled:
		return
	
	var load_avatar_dialog: FileDialogClose = self.find_child(MODEL_LOADER_NODE_NAME, false)
	if not load_avatar_dialog:
		load_avatar_dialog = Gui.FILE_DIALOG_CLOSE_SCENE.instantiate()
		load_avatar_dialog.name = MODEL_LOADER_NODE_NAME
		self.add_child(load_avatar_dialog)
		load_avatar_dialog.owner = self
		load_avatar_dialog.initialize(
			self._on_model_file_selected,
			Callable(),
			false
		)
		
		# Set dialog path
		if not self._loaded_model_path.is_empty():
			# If a model has already been loaded, set it as currently selected
			load_avatar_dialog.current_path = self._loaded_model_path
		else:
			# If no model was loaded yet, use default dialog path
			var main: Main = get_node(Main.MAIN_NODE_PATH)
			load_avatar_dialog.current_dir = main.get_default_config_dialog_path()

func _on_model_file_selected(model_path: String):
	self.load_model(model_path)

func _init_gui():
	var button_model_load := GuiElement.ElementData.new()
	button_model_load.Name = "Load Model"
	button_model_load.OnDataChangedCallable = self._on_load_model_request
	button_model_load.SetDataSignal = [self, "open_dialog_requested"]
	button_model_load.OnSaveData = func(_val: bool) -> String:
		return self._loaded_model_path
	button_model_load.OnLoadData = func(model_path: String) -> bool:
		if not model_path.is_empty():
			self.load_model(model_path)
		return false
	
	var button_data := GuiElement.ButtonData.new()
	button_data.Text = "Load Model"
	button_model_load.Data = button_data
	
	Gui.get_gui_menu().add_elements_to_tab("Model Control", [ button_model_load ])
	Gui.get_gui_menu().push_tab_to_front("Model Control")

func _ready():
	self._init_gui()
	#self.emit_signal("avatar_loaded", self)

func open_load_model_dialog():
	self.emit_signal(&"open_dialog_requested", true, true)

func load_model(model_path: String):
	var avatar_model: Node3D = ModelImporter.import_model_infer_extension(model_path)
	if not avatar_model:
		return
	
	self.unload_model()
	
	self.add_child(avatar_model)
	avatar_model.owner = self
	
	self._loaded_model_path = model_path
	
	self.emit_signal(&"avatar_loaded", self)

func unload_model():
	# Remove old avatar
	for child in self.get_children():
		child.owner = null
		self.remove_child(child)
		child.queue_free()
	
	self.emit_signal(&"avatar_unloaded", self)

func is_avatar_loaded() -> bool:
	return !self._loaded_model_path.is_empty()
