class_name GuiElements
extends TabContainer

const CONTROL_SCENES_PATH: String = "res://gui/scenes/controls"
const SCROLLABLE_ELEMENTS_NODE: PackedScene = preload("../scenes/scrollable_elements.tscn")

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

class GuiElementsData:
	var GuiElementsNode: GuiElements = null

## Setup data for a custom menu element
class CustomData:
	var CustomNode: Control
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

# Name of element. Used during save/load
var element_name: String = ""

func _add_elements_to_tab(tab_node: Node, elements: Array[ElementData], tab_name: String):
	for element_data in elements:
		var element_node: Node = null
		if element_data.Data is SliderData:
			element_node = self._create_slider_element(element_data, tab_name)
		elif element_data.Data is ButtonData:
			element_node = self._create_button_element(element_data, tab_name)
		elif element_data.Data is CheckBoxData:
			element_node = self._create_checkbox_element(element_data, tab_name)
		elif element_data.Data is LineEditData:
			element_node = self._create_line_edit_element(element_data, tab_name)
		elif element_data.Data is TextEditData:
			element_node = self._create_text_edit_element(element_data, tab_name)
		elif element_data.Data is MenuSelectData:
			element_node = self._create_menu_select_element(element_data, tab_name)
		elif element_data.Data is GuiElementsData:
			element_node = self._create_gui_elements_element(element_data, tab_name)
		elif element_data.Data is CustomData:
			element_node = self._create_custom_element(element_data, tab_name)
		else:
			print("Unknown input element data type ", typeof(element_data.Data))
		
		# Add element to container
		if element_node:
			tab_node.add_child(element_node)
			element_node.owner = tab_node

func _create_label(text: String) -> Label:
	var label: Label = load(CONTROL_SCENES_PATH + "/label.tscn").instantiate()
	label.text = text
	return label

func _connect_element_signals(element: Node, data_changed_signal: String, element_data: ElementData, tab_name: String):
	if element_data.OnDataChangedCallable:
		element.connect(data_changed_signal, element_data.OnDataChangedCallable)
	if element_data.SetDataSignal:
		element_data.SetDataSignal[0].connect(element_data.SetDataSignal[1], element._on_external_data_changed)
	
	element.element_name = tab_name + "/" + element_data.Name
	element.on_save_data_fcn = element_data.OnSaveData
	element.on_load_data_fcn = element_data.OnLoadData

static func _iterate_children(node: Node, fcn: Callable):
	for child in node.get_children():
		fcn.call(child)
		_iterate_children(child, fcn)

# ################################################
# The following are various element container 
# creation functions. Each of these functions
# also connect the signal to their callable
func _create_slider_element(element: ElementData, tab_name: String):
	assert(element.Data is SliderData)
	var slider: Node = load(CONTROL_SCENES_PATH + "/slider.tscn").instantiate()
	
	# Set min_value, max_value, and step before value to prevent unintended rounding
	var slider_data: SliderData = element.Data
	slider.min_value = slider_data.MinValue
	slider.max_value = slider_data.MaxValue
	slider.step      = slider_data.Step
	slider.value = slider_data.Default
	
	self._connect_element_signals(slider, "value_changed", element, tab_name)
	
	return self._create_element_container(self._create_label(element.Name), slider)

func _create_button_element(element: ElementData, tab_name: String):
	assert(element.Data is ButtonData)
	var button: Button = load(CONTROL_SCENES_PATH + "/button.tscn").instantiate()
	
	var button_data: ButtonData = element.Data
	button.text = button_data.Text
	button.icon = button_data.Icon
	
	self._connect_element_signals(button, "pressed_val", element, tab_name)
	
	return self._create_element_container(self._create_label(element.Name), button)

func _create_checkbox_element(element: ElementData, tab_name: String):
	assert(element.Data is CheckBoxData)
	var checkbox: CheckButton = load(CONTROL_SCENES_PATH + "/check_button.tscn").instantiate()
	
	var checkbox_data: CheckBoxData = element.Data
	checkbox.button_pressed = checkbox_data.Default
	
	self._connect_element_signals(checkbox, "toggled", element, tab_name)
	
	return self._create_element_container(self._create_label(element.Name), checkbox)

func _create_line_edit_element(element: ElementData, tab_name: String):
	assert(element.Data is LineEditData)
	var line_edit: LineEdit = load(CONTROL_SCENES_PATH + "/line_edit.tscn").instantiate()
	
	var line_edit_data: LineEditData = element.Data
	line_edit.text = line_edit_data.Default
	line_edit.placeholder_text = line_edit_data.Placeholder
	
	self._connect_element_signals(line_edit, "text_changed", element, tab_name)
	
	return self._create_element_container(self._create_label(element.Name), line_edit)

func _create_text_edit_element(element: ElementData, tab_name: String):
	assert(element.Data is TextEditData)
	var text_edit: TextEdit = load(CONTROL_SCENES_PATH + "/text_edit.tscn").instantiate()
	
	var text_edit_data: TextEditData = element.Data
	text_edit.text = text_edit_data.Default
	text_edit.placeholder_text = text_edit_data.Placeholder
	
	self._connect_element_signals(text_edit, "text_changed_data", element, tab_name)
	
	return self._create_element_container(self._create_label(element.Name), text_edit)

func _create_menu_select_element(element: ElementData, tab_name: String):
	assert(element.Data is MenuSelectData)
	var menu_select: MenuBar = load(CONTROL_SCENES_PATH + "/menu_select.tscn").instantiate()
	
	var menu_select_data: MenuSelectData = element.Data
	menu_select.setup_menu(menu_select_data.Items, menu_select_data.Default)
	menu_select.setup_update_menu_signal(menu_select_data.UpdateMenuSignal)
	
	self._connect_element_signals(menu_select, "menu_item_selected", element, tab_name)
	
	return self._create_element_container(self._create_label(element.Name), menu_select)

func _create_gui_elements_element(element: ElementData, tab_name: String):
	assert(element.Data is GuiElementsData)
	var gui_elements: GuiElements = element.Data.GuiElementsNode
	gui_elements.name = &"GuiElements" # Rename so that scrollable_elements.gd can properly find new node
	gui_elements.element_name = tab_name + "/" + element.Name
	
	# TODO: Use a better method than creating and replacing GuiElements node
	var scrollable_elements := SCROLLABLE_ELEMENTS_NODE.instantiate()
	var old_gui_elements: GuiElements = scrollable_elements.get_child(0)
	old_gui_elements.queue_free()
	old_gui_elements.replace_by(gui_elements)
	
	var label := self._create_label(element.Name)
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	return self._create_element_container(
		label, 
		scrollable_elements,
		Control.SIZE_EXPAND_FILL | Control.SIZE_SHRINK_BEGIN
	)

func _create_custom_element(element: ElementData, _tab_name: String):
	#TODO: Implement custom element
	assert(element.Data is CustomData)
	
	if element.Data.SignalConnectCallback is Callable:
		element.Data.SignalConnectCallback.call(element.OnDataChangedCallable, element.SetDataSignal)
	
	return element.Data.CustomNode

func _create_element_container(label_node: Label, element_node: Node, 
							   size_vertical: Control.SizeFlags = Control.SIZE_SHRINK_CENTER) -> HSplitContainer:
	var container: HSplitContainer = HSplitContainer.new()
	
	container.dragger_visibility = SplitContainer.DRAGGER_HIDDEN
	container.set_anchors_preset(PRESET_TOP_WIDE)
	container.size_flags_horizontal = Control.SIZE_FILL
	container.size_flags_vertical   = size_vertical
	
	# Add label
	container.add_child(label_node)
	label_node.owner = container
	
	# Add element input
	container.add_child(element_node)
	element_node.owner = container
	
	return container

func _find_tab(tab_name: String) -> Control:
	for i in range(0, self.get_tab_count()):
		if tab_name == self.get_tab_title(i):
			return self.get_tab_control(i)
	
	return null

#################################################3
## Create a new tab with the given input elements
func add_element_tab(tab_name: String, elements: Array[ElementData]):
	var element_container: VBoxContainer = VBoxContainer.new()
	element_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	#element_container.size_flags_horizontal = Control.SIZE_FILL
	#element_container.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	
	# Create input elements
	self._add_elements_to_tab(element_container, elements, tab_name)
	
	# Add new tab to self
	self.add_child(element_container)
	element_container.owner = self
	
	self.set_tab_title(self.get_tab_count()-1, tab_name)
	
	return element_container

## Attempts to add elements to a tab with the given name
func add_elements_to_tab_name(tab_name: String, elements: Array[ElementData]) -> bool:
	var tab_node := self._find_tab(tab_name)
	if not tab_node:
		return false
	
	self._add_elements_to_tab(tab_node, elements, tab_name)
	return true

## Attempts to add elements to a tab with the given name. If the tab is not present, create it
func add_or_create_elements_to_tab_name(tab_name: String, elements: Array[ElementData]):
	var elements_added = self.add_elements_to_tab_name(tab_name, elements)
	if not elements_added:
		self.add_element_tab(tab_name, elements)

## Removes tab with the given name
func remove_tab(tab_name: String):
	var tab_node := self._find_tab(tab_name)
	if not tab_node:
		return
	
	tab_node.owner = null
	self.remove_child(tab_node)
	tab_node.queue_free()

## Push tab with node.element_name == [param tab_name] to front of tab menu
func push_tab_to_front(tab_name: String) -> bool:
	var tab_id: int = -1
	for i in range(0, self.get_tab_count()):
		if self.get_tab_title(i) == tab_name:
			tab_id = i
			break
	
	if tab_id < 0:
		return false
	
	self.get_tab_bar().move_tab(tab_id, 0)
	self.move_child(self.get_child(tab_id), 0)
	
	return true

## Calls each control element's [method ElementData.OnLoadData]. 
## For each control element, we look for a key in [param data] with node.element_name
## and pass that to the element.
func load_data(data: Dictionary) -> void:
	var load_node_data_fcn: Callable = func(node: Node):
		# Check that this is an element node
		if not node.has_method("load_data"):
			return
		
		# Get saved data
		var node_data = data.get(node.element_name)
		if node_data == null:
			return
		
		node.load_data(node_data)
	
	# Call load_node_data_fcn on all child nodes
	_iterate_children(self, load_node_data_fcn)

## Calls each control element's [method ElementData.OnSaveData]. The results are
## stored in a dictionary, with the format {node.element_name: node.save_data()}
## for each element.  
func save_data() -> Dictionary:
	var data: Dictionary = {}
	var save_node_data_fcn: Callable = func(node: Node):
		# Check that this is an element node
		if not node.has_method("save_data"):
			return
		
		var val = node.save_data()
		data[node.element_name] = val
	
	# Call save_node_data_fcn on all child nodes
	_iterate_children(self, save_node_data_fcn)
	
	return data
