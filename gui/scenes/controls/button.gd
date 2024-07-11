extends Button

signal pressed_val

# Name of element. Used during save/load
var element_name: String = ""

# Callable of the form on_save_data_fcn(gui_value: bool)
var on_save_data_fcn: Callable

# Callable of the form on_load_data_fcn(stored_value) -> bool
var on_load_data_fcn: Callable

func _on_external_data_changed(new_val: bool, propagate: bool):
	if propagate:
		#self.set_pressed(new_val)
		# TODO: For some reason, set_pressed doesn't emit a signal, so do that manually
		if new_val:
			self._on_pressed()
	else:
		self.set_pressed_no_signal(new_val)

func _on_pressed():
	self.emit_signal("pressed_val", true)

func save_data():
	var save_value = self.is_pressed()
	if self.on_save_data_fcn:
		save_value = self.on_save_data_fcn.call(save_value)
	
	return save_value

func load_data(stored_value):
	if self.on_load_data_fcn:
		stored_value = self.on_load_data_fcn.call(stored_value)
	
	self._on_external_data_changed(stored_value, true)
