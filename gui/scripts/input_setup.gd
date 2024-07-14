class_name InputSetup
## Dynamically set default inputs keys.
##
## This class contains functions that set input keys if no other action with the 
## same name was defined. With this, you can define input keys for a plugin but 
## then let a user override them in Project Settings -> Input Map.

static func set_input_default(action: StringName, default_event: InputEvent) -> bool:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		InputMap.action_add_event(action, default_event)
		return true
	
	return false

static func set_input_default_key(action: StringName, physical_keycode: Key, ctrl_pressed: bool = false, alt_pressed: bool = false, shift_pressed: bool = false) -> bool:
	var ev: InputEventKey = InputEventKey.new()
	ev.physical_keycode = physical_keycode
	ev.ctrl_pressed = ctrl_pressed
	ev.alt_pressed = alt_pressed
	ev.shift_pressed = shift_pressed
	
	return set_input_default(action, ev)

static func set_input_default_mouse_button(action: StringName, button_index: MouseButton, ctrl_pressed: bool = false, alt_pressed: bool = false, shift_pressed: bool = false) -> bool:
	var ev: InputEventMouseButton = InputEventMouseButton.new()
	ev.button_index = button_index
	ev.ctrl_pressed = ctrl_pressed
	ev.alt_pressed = alt_pressed
	ev.shift_pressed = shift_pressed
	
	return set_input_default(action, ev)
