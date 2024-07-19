class_name GuiElement

const CONTROL_SCENES_PATH: String = "./gui_elements"
const SCROLLABLE_ELEMENTS_NODE = preload("./scenes/scrollable_elements.tscn")

## Setup data for slider element.
class SliderData:
	var MinValue: float = 0.0
	var MaxValue: float = 1.0
	var Step:     float = 0.1
	var Default:  float = 0.0

## Setup data for button element
class ButtonData:
	var Text: String = "Button"
	var Icon: Texture2D = null

## Setup data for checkbox element
class CheckBoxData:
	var Default: bool = false

## Setup data for line string input
class LineEditData:
	var Default: String     = ""
	var Placeholder: String = ""

## Setup data for string input text box
class TextEditData:
	var Default: String     = ""
	var Placeholder: String = ""

## Setup data for menu element
class MenuSelectData:
	var Default: int         = -1
	var Items: Array[String] = []
	# External signal used to change items (should emit two values: new Default + new Items)
	# SetDataSignal should be and array [ emitting_node: Node, signal_name: String ]
	var UpdateMenuSignal: Array = []

class GuiTabMenuData:
	var GuiTabMenuNode: GuiTabMenuBase = null

## Setup data for a custom menu element
class CustomData:
	var CustomNode: GuiElementBase
	var SignalConnectCallback = null

## General setup data for all control elements 
class ElementData:
	## Input element name
	var Name: String
	## Input data. Can be any of the above xxxData classes
	var Data
	## Function that's called when the GUI element is changed (of the form OnDataChangedCallback(changed_value: <ValueType>))
	var OnDataChangedCallable: Callable
	## External signal that is emitted when element value should be changed
	## Signal should pass two arguments, the new element value and a boolean flag
	## that signifies whether the update should be propagated to OnDataChangedCallable
	## SetDataSignal should be and array [ emitting_node: Node, signal_name: String ]
	var SetDataSignal: Array
	## Callable that's called when an object is loaded (of the form OnLoadData(stored_value: <ValueType>) -> <ValueType>)
	var OnLoadData: Callable
	## Callable that's called when an object is saved. 
	## Should return the value to save (of the form OnSaveData(gui_value: <ValueType>) -> <ValueType>)
	var OnSaveData: Callable

static func _connect_element_signals(element: Node, data_changed_signal: String, element_data: ElementData):
	if element_data.OnDataChangedCallable:
		element.connect(data_changed_signal, element_data.OnDataChangedCallable)
	if element_data.SetDataSignal:
		element_data.SetDataSignal[0].connect(element_data.SetDataSignal[1], element._on_external_data_changed)
	
	element.set_element_name(element_data.Name)
	element.on_save_data_fcn = element_data.OnSaveData
	element.on_load_data_fcn = element_data.OnLoadData

# ################################################
# The following are various element container 
# creation functions. Each of these functions
# also connect the signal to their callable
static func _create_slider_element(element: ElementData):
	assert(element.Data is SliderData)
	var slider: Node = preload(CONTROL_SCENES_PATH + "/slider.tscn").instantiate()
	
	# Set min_value, max_value, and step before value to prevent unintended rounding
	var slider_data: SliderData = element.Data
	slider.min_value = slider_data.MinValue
	slider.max_value = slider_data.MaxValue
	slider.step      = slider_data.Step
	slider.value = slider_data.Default
	
	GuiElement._connect_element_signals(slider, "value_changed", element)
	
	return slider

static func _create_button_element(element: ElementData):
	assert(element.Data is ButtonData)
	var button: Button = preload(CONTROL_SCENES_PATH + "/button.tscn").instantiate()
	
	var button_data: ButtonData = element.Data
	button.text = button_data.Text
	button.icon = button_data.Icon
	
	GuiElement._connect_element_signals(button, "pressed_val", element)
	
	return button

static func _create_checkbox_element(element: ElementData):
	assert(element.Data is CheckBoxData)
	var checkbox: CheckButton = preload(CONTROL_SCENES_PATH + "/check_button.tscn").instantiate()
	
	var checkbox_data: CheckBoxData = element.Data
	checkbox.button_pressed = checkbox_data.Default
	
	GuiElement._connect_element_signals(checkbox, "toggled", element)
	
	return checkbox

static func _create_line_edit_element(element: ElementData):
	assert(element.Data is LineEditData)
	var line_edit: LineEdit = preload(CONTROL_SCENES_PATH + "/line_edit.tscn").instantiate()
	
	var line_edit_data: LineEditData = element.Data
	line_edit.text = line_edit_data.Default
	line_edit.placeholder_text = line_edit_data.Placeholder
	
	GuiElement._connect_element_signals(line_edit, "text_changed", element)
	
	return line_edit

static func _create_text_edit_element(element: ElementData):
	assert(element.Data is TextEditData)
	var text_edit: TextEdit = preload(CONTROL_SCENES_PATH + "/text_edit.tscn").instantiate()
	
	var text_edit_data: TextEditData = element.Data
	text_edit.text = text_edit_data.Default
	text_edit.placeholder_text = text_edit_data.Placeholder
	
	GuiElement._connect_element_signals(text_edit, "text_changed_data", element)
	
	return text_edit

static func _create_menu_select_element(element: ElementData):
	assert(element.Data is MenuSelectData)
	var menu_select: MenuBar = preload(CONTROL_SCENES_PATH + "/menu_select.tscn").instantiate()
	
	var menu_select_data: MenuSelectData = element.Data
	menu_select.setup_menu(menu_select_data.Items, menu_select_data.Default)
	menu_select.setup_update_menu_signal(menu_select_data.UpdateMenuSignal)
	
	GuiElement._connect_element_signals(menu_select, "menu_item_selected", element)
	
	return menu_select

static func _create_gui_tab_menu_element(element: ElementData):
	assert(element.Data is GuiTabMenuData)
	var gui_container: GuiTabMenuBase = element.Data.GuiTabMenuNode
	gui_container.name = &"GuiSideMenu" # Rename so that scrollable_elements.gd can properly find new node
	gui_container.set_element_name(element.Name)
	
	# TODO: Use a better method than creating and replacing GuiSideMenu node
	var scrollable_elements := SCROLLABLE_ELEMENTS_NODE.instantiate()
	var old_gui_container: GuiTabMenuBase = scrollable_elements.get_child(0)
	scrollable_elements.remove_child(old_gui_container)
	old_gui_container.owner = null
	old_gui_container.queue_free()
	
	scrollable_elements.add_child(gui_container)
	gui_container.owner = scrollable_elements
	
	return scrollable_elements

static func _create_custom_element(element: ElementData):
	#TODO: Implement custom element
	assert(element.Data is CustomData)
	
	if element.Data.SignalConnectCallback is Callable:
		element.Data.SignalConnectCallback.call(element.OnDataChangedCallable, element.SetDataSignal)
	
	return element.Data.CustomNode

static func create_element(element_data: ElementData)-> Control:
	var element_node: Control = null
	if element_data.Data is SliderData:
		element_node = GuiElement._create_slider_element(element_data)
	elif element_data.Data is ButtonData:
		element_node = GuiElement._create_button_element(element_data)
	elif element_data.Data is CheckBoxData:
		element_node = GuiElement._create_checkbox_element(element_data)
	elif element_data.Data is LineEditData:
		element_node = GuiElement._create_line_edit_element(element_data)
	elif element_data.Data is TextEditData:
		element_node = GuiElement._create_text_edit_element(element_data)
	elif element_data.Data is MenuSelectData:
		element_node = GuiElement._create_menu_select_element(element_data)
	elif element_data.Data is GuiTabMenuData:
		element_node = GuiElement._create_gui_tab_menu_element(element_data)
	elif element_data.Data is CustomData:
		element_node = GuiElement._create_custom_element(element_data)
	else:
		print("Unknown input element data type ", typeof(element_data.Data))
	
	return element_node

static func create_elements(elements: Array[ElementData])-> Array[Control]:
	var element_nodes: Array[Control] = []
	for element_data in elements:
		var element_node: Control = GuiElement.create_element(element_data)
		if element_node:
			element_nodes.push_back(element_node)
	
	return element_nodes
