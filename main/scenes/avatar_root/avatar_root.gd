extends Node

const LOAD_AVATAR_DIALOG = preload("./scenes/load_model_dialog.tscn")
const MODEL_IMPORTER = preload("./scripts/model_importer.gd")

signal open_dialog_requested(toggle: bool, propagate: bool)
signal avatar_loaded(avatar_node: Node)
signal avatar_unloaded(avatar_node: Node)

var _load_avatar_dialog: FileDialog = null
var _loaded_model_path: String = ""

func _on_load_model_request(toggled: bool):
	if not toggled:
		return
	
	if self._load_avatar_dialog:
		return
	
	self._load_avatar_dialog = LOAD_AVATAR_DIALOG.instantiate()
	
	# Set dialog path
	if not self._loaded_model_path.is_empty():
		# If a model has already been loaded, set it as currently selected
		self._load_avatar_dialog.current_path = self._loaded_model_path
	else:
		# If no model was loaded yet, use default dialog path
		var main: Main = get_node(Main.MAIN_NODE_PATH)
		self._load_avatar_dialog.current_dir = main.get_default_config_dialog_path()
	
	self._load_avatar_dialog.connect("model_file_selected", _on_model_file_selected)
	
	self.add_child(self._load_avatar_dialog)

func _on_model_file_selected(model_path: String):
	if self._load_avatar_dialog:
		self._load_avatar_dialog.queue_free()
		self._load_avatar_dialog = null
	
	if not model_path.is_empty():
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
