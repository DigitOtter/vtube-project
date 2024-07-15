extends GuiElementBase

signal text_changed_data


# Callable of the form on_save_data_fcn(gui_value: String)
var on_save_data_fcn: Callable

# Callable of the form on_load_data_fcn(stored_value) -> String
var on_load_data_fcn: Callable

func _on_text_changed():
	self.emit_signal(&"text_changed_data", self.text)

func _on_external_data_changed(new_val: String, propagate: bool):
	(self as Control as TextEdit).set_text(new_val)
	
	if propagate:
		self.emit_signal(&"text_changed_data", self.text)

# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect(&"text_changed", _on_text_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func save_data():
	var save_value = self.text
	if self.on_save_data_fcn:
		save_value = self.on_save_data_fcn.call(save_value)
	
	return save_value

func load_data(stored_value):
	if self.on_load_data_fcn:
		stored_value = self.on_load_data_fcn.call(stored_value)
	
	self._on_external_data_changed(stored_value, true)
