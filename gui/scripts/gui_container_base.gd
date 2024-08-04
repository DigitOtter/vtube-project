class_name GuiContainerBase
extends GuiElementBase

enum Type {
	SIMPLE,
	ARRANGEABLE
}

const ElementData = GuiElement.ElementData

static func create_new(type: Type) -> GuiContainerBase:
	var container: GuiContainerBase = null
	if type == Type.SIMPLE:
		container = preload("../gui_container_simple/gui_container_simple.tscn").instantiate()
	elif type == Type.ARRANGEABLE:
		container = preload("../gui_arrangeable_container/gui_arrangeable_container.tscn").instantiate()
	
	return container

func add_elements(elements: Array[GuiElement.ElementData]) -> Array[GuiElementBase]:
	var new_elements: Array[GuiElementBase] = []
	for element in elements:
		new_elements.append(self.add_element(element))
	
	return new_elements

#################################################
## Create a new tab with the given input elements
func add_element(_element: GuiElement.ElementData) -> GuiElementBase:
	return null

## Remove element
func remove_element(__element_name: String):
	pass

## Get number of elements in container
func get_element_count() -> int:
	return -1

## Get elements in container
func get_elements() -> Array[GuiElementBase]:
	return []

## Move element to new position
func move_element(__element_name: String, _pos: int) -> bool:
	return false

## Calls each control element's [method ElementData.OnLoadData]. 
## For each control element, we look for a key in [param data] with node.get_element_name()
## and pass that to the element.
func load_data(_data: Dictionary) -> void:
	pass

## Calls each control element's [method ElementData.OnSaveData]. The results are
## stored in a dictionary, with the format node.get_element_name(): node.save_data()
## for each element.  
func save_data():
	return null
