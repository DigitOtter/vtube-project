extends GuiElementBase

# Callable of the form on_save_data_fcn(gui_value: bool)
var on_save_data_fcn: Callable

# Callable of the form on_load_data_fcn(stored_value) -> bool
var on_load_data_fcn: Callable

func _on_external_data_changed(new_val: bool, propagate: bool):
	var check_button = self as Control as CheckButton
	if propagate:
		check_button.set_pressed(new_val)
	else:
		check_button.set_pressed_no_signal(new_val)

func save_data():
	var save_value = (self as Control as CheckButton).is_pressed()
	if self.on_save_data_fcn:
		save_value = self.on_save_data_fcn.call(save_value)
	
	return save_value

func load_data(stored_value) -> void:
	if self.on_load_data_fcn:
		stored_value = self.on_load_data_fcn.call(stored_value)
	
	self._on_external_data_changed(stored_value, true)
