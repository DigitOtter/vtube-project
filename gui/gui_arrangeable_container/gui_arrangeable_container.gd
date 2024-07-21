class_name GuiArrangeableContainer
extends GuiContainerBase

const ARRANGEABLE_ITEM_NODE := preload("./arrangeable_item.tscn")
const ARRANGEABLE_ITEM_CLASS: GDScript = preload("./arrangeable_item.gd")

## Signals that an element has changed position
signal element_moved(element_name: String, new_pos: int)

func _create_element_container(label_name: String, 
							   element_data: ElementData) -> ARRANGEABLE_ITEM_CLASS:
	var element_node = GuiElementBase.create_element(element_data)
	if not element_node:
		return null
	
	var container: ARRANGEABLE_ITEM_CLASS = ARRANGEABLE_ITEM_NODE.instantiate()
	var label: Label = container.get_label()
	label.text = label_name
	
	# Set container and label ordering
	if element_data.Data is GuiElement.GuiTabMenuData:
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Add element
	container.add_gui_element(element_node)
	
	return container

func _move_item(item: ARRANGEABLE_ITEM_CLASS, pos: int):
	self.move_child(item, pos)
	self.emit_signal(&"element_moved", item.get_element_name(), item.get_index())

func _on_move_item_up(item: ARRANGEABLE_ITEM_CLASS):
	var idx: int = item.get_index()
	if idx <= 0:
		return
	self._move_item(item, idx-1)

func _on_move_item_down(item: ARRANGEABLE_ITEM_CLASS):
	var idx: int = item.get_index()
	if idx >= self.get_child_count()-1:
		return
	self._move_item(item, idx+1)

func _find_element_container(element: String) -> ARRANGEABLE_ITEM_CLASS:
	for single_container: ARRANGEABLE_ITEM_CLASS in self.get_children():
		if single_container.get_element_name() == element:
			return single_container
	return null

## Create a new tab with the given input elements
func add_element(element: GuiElement.ElementData) -> GuiElementBase:
	var element_container := self._create_element_container(element.Name, element)
	self.add_child(element_container)
	element_container.owner = self
	
	# Connect arrange buttons
	var up_button := element_container.get_move_up_button()
	up_button.connect(&"pressed", func():
		self._on_move_item_up(element_container))
	var down_button := element_container.get_move_down_button()
	down_button.connect(&"pressed", func():
		self._on_move_item_down(element_container))
	
	return element_container.get_element()

## Remove element
func remove_element(element_name: String):
	var container := self._find_element_container(element_name)
	if not container:
		return
	self.remove_child(container)
	container.owner = null
	container.queue_free()

## Get number of elements in container
func get_element_count() -> int:
	return self.get_child_count()

## Get elements in container
func get_elements() -> Array[GuiElementBase]:
	var elements: Array[GuiElementBase] = []
	for c: ARRANGEABLE_ITEM_CLASS in self.get_children():
		elements.append(c.get_element())
	return elements

## Move element to new position
func move_element(element_name: String, pos: int) -> bool:
	var element := self._find_element_container(element_name)
	if not element: 
		return false
	
	self._move_item(element, pos)
	return true

## Load data from variant
func load_data(data: Dictionary) -> void:
	var elements := self.get_elements()
	for e: GuiElementBase in elements:
		var element_data = data.get(e.get_element_name(), null)
		if element_data != null:
			e.load_data(element_data)

## Save data to variant
func save_data():
	var data: Dictionary = {}
	
	var elements := self.get_elements()
	for e: GuiElementBase in elements:
		var element_data = e.save_data()
		if element_data != null:
			data[e.get_element_name()] = element_data
	
	return data

