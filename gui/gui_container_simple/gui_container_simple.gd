extends GuiContainerBase

const LABELED_ELEMENT_CONTAINER_NODE := preload("./labeled_element_container.tscn")
const LABELED_ELEMENT_CONTAINER_CLASS: GDScript = preload("./labeled_element_container.gd")

static func _iterate_children(node: Node, fcn: Callable):
	for child in node.get_children():
		fcn.call(child)
		_iterate_children(child, fcn)

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
func add_element(element: ElementData):
	var element_container = self._create_element_container(element.Name, element)
	self.add_child(element_container)
	element_container.owner = self

## Remove element
func remove_element(element_name: String):
	var element_container := self as Control as VBoxContainer
	for single_container: LABELED_ELEMENT_CONTAINER_CLASS in element_container.get_children():
		if single_container.get_element_name() == element_name:
			element_container.remove_child(single_container)
			single_container.owner = null
			single_container.queue_free()

## Calls each control element's [method ElementData.OnLoadData]. 
## For each control element, we look for a key in [param data] with node.element_name
## and pass that to the element.
func load_data(data: Dictionary) -> void:
	var load_node_data_fcn: Callable = func(node: Node):
		# Check that this is an element node
		if not node.has_method(&"load_data"):
			return
		
		# Get saved data
		var node_data = data.get(node.element_name)
		if node_data == null:
			return
		
		node.load_data(node_data)
	
	# Call load_node_data_fcn on all child nodes
	_iterate_children(self, load_node_data_fcn)

## Calls each control element's [method ElementData.OnSaveData]. The results are
## stored in a dictionary, with the format node.element_name: node.save_data()
## for each element.  
func save_data() -> Dictionary:
	var data: Dictionary = {}
	var save_node_data_fcn: Callable = func(node: Node):
		# Check that this is an element node
		if not node.has_method(&"save_data"):
			return
		
		var val = node.save_data()
		data[node.element_name] = val
	
	# Call save_node_data_fcn on all child nodes
	_iterate_children(self, save_node_data_fcn)
	
	return data
