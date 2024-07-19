class_name GuiContainerSimple
extends GuiContainerBase

const LABELED_ELEMENT_CONTAINER_NODE := preload("./labeled_element_container.tscn")
const LABELED_ELEMENT_CONTAINER_CLASS: GDScript = preload("./labeled_element_container.gd")

static func _iterate_children(node: Node, fcn: Callable):
	for child in node.get_children():
		fcn.call(child)
		GuiContainerSimple._iterate_children(child, fcn)

func _find_element_container(element_name: String) -> LABELED_ELEMENT_CONTAINER_CLASS:
	for single_container: LABELED_ELEMENT_CONTAINER_CLASS in self.get_children():
		if single_container.get_element_name() == element_name:
			return single_container
	return null

func _create_element_container(label_name: String, 
							   element_data: ElementData) -> Node:
	var element_node = GuiElementBase.create_element(element_data)
	if not element_node:
		return null
	
	var container: LABELED_ELEMENT_CONTAINER_CLASS = LABELED_ELEMENT_CONTAINER_NODE.instantiate()
	var label: Label = container.find_child("Label")
	label.text = label_name
	
	# Set container and label ordering
	if element_data.Data is GuiElement.GuiTabMenuData:
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Add element
	container.add_child(element_node)
	element_node.owner = container
	
	return container

## Add element
func add_element(element: ElementData) -> GuiElementBase:
	var element_container = self._create_element_container(element.Name, element)
	self.add_child(element_container)
	element_container.owner = self
	return element_container.get_child(1)

## Remove element
func remove_element(element_name: String):
	var container: LABELED_ELEMENT_CONTAINER_CLASS = self._find_element_container(element_name)
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
	for c: LABELED_ELEMENT_CONTAINER_CLASS in self.get_children():
		assert(c.get_child_count() == 2)
		var e: GuiElementBase = c.get_child(1)
		elements.push_back(e)
	return elements

## Move element to new position
func move_element(element_name: String, pos: int) -> bool:
	var container: LABELED_ELEMENT_CONTAINER_CLASS = self._find_element_container(element_name)
	if not container: 
		return false
	self.move_child(container, pos)
	return true

## Calls each control element's [method ElementData.OnLoadData]. 
## For each control element, we look for a key in [param data] with node.get_element_name()
## and pass that to the element.
func load_data(data: Dictionary) -> void:
	var load_node_data_fcn: Callable = func(node: Node):
		# Check that this is an element node
		if not node is GuiElementBase:
			return
		
		# Get saved data
		var node_data = data.get(node.get_element_name())
		if node_data == null:
			return
		
		node.load_data(node_data)
	
	# Call load_node_data_fcn on all child nodes
	GuiContainerSimple._iterate_children(self, load_node_data_fcn)

## Calls each control element's [method ElementData.OnSaveData]. The results are
## stored in a dictionary, with the format node.get_element_name(): node.save_data()
## for each element.  
func save_data():
	var data: Dictionary = {}
	var save_node_data_fcn: Callable = func(node: Node):
		# Check that this is an element node
		if not node is GuiElementBase:
			return
		
		var val = node.save_data()
		data[node.get_element_name()] = val
	
	# Call save_node_data_fcn on all child nodes
	GuiContainerSimple._iterate_children(self, save_node_data_fcn)
	
	return data
