extends GuiContainerBase

signal value_changed

# Callable of the form on_save_data_fcn(gui_value: float)
var on_save_data_fcn: Callable

# Callable of the form on_load_data_fcn(stored_value) -> float
var on_load_data_fcn: Callable

@export 
var value: float = 0.0 :
	get:
		return $HSlider.value
	set(value):
		$HSlider.value = value
		$SpinBox.value = value

@export 
var min_value: float = 0.0 :
	get:
		return $HSlider.min_value
	set(min):
		self.set_min_value(min)

@export 
var max_value: float = 1.0 :
	get:
		return $HSlider.max_value
	set(max):
		self.set_max_value(max)

@export 
var step: float = 0.1 :
	get:
		return $HSlider.step
	set(step):
		self.set_step_size(step)

func set_min_value(vmin: float):
	var text: SpinBox = $SpinBox
	var slider: HSlider = $HSlider
	
	text.min_value   = vmin
	slider.min_value = vmin

func set_max_value(vmax: float):
	var text: SpinBox = $SpinBox
	var slider: HSlider = $HSlider
	
	text.max_value   = vmax
	slider.max_value = vmax

func set_step_size(vstep: float):
	var text: SpinBox = $SpinBox
	var slider: HSlider = $HSlider
	
	text.step   = vstep
	slider.step = vstep

########################################################################
## Signals
func _on_slider_value_changed(_value: float):
	var text: SpinBox = $SpinBox
	text.set_value_no_signal(_value)
	self.emit_signal("value_changed", _value)

func _on_text_changed(_value: float):
	var slider: HSlider = $HSlider
	slider.set_value_no_signal(_value)
	self.emit_signal("value_changed", _value)

func _on_external_data_changed(new_val: float, propagate: bool):
	var slider: HSlider = $HSlider
	var text: SpinBox = $SpinBox
	slider.set_value_no_signal(new_val)
	text.set_value_no_signal(new_val)
	
	if propagate:
		self.emit_signal("value_changed", value)

func save_data():
	var save_value = self.value
	if self.on_save_data_fcn:
		save_value = self.on_save_data_fcn.call(save_value)
	
	return save_value

func load_data(stored_value):
	if self.on_load_data_fcn:
		stored_value = self.on_load_data_fcn.call(stored_value)
	
	self._on_external_data_changed(stored_value, true)
