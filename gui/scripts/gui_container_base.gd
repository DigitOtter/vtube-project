class_name GuiContainerBase
extends GuiElementBase

const ElementData = GuiElement.ElementData

func add_elements(elements: Array[GuiElement.ElementData]) -> Array[GuiElementBase]:
	var new_elements: Array[GuiElementBase] = []
	for element in elements:
		new_elements.append(self.add_element(element))
	
	return new_elements

#################################################
## Create a new tab with the given input elements
func add_element(element: GuiElement.ElementData) -> GuiElementBase:
	return null

## Remove element
func remove_element(element_name: String):
	pass

## Calls each control element's [method ElementData.OnLoadData]. 
## For each control element, we look for a key in [param data] with node.element_name
## and pass that to the element.
func load_data(data: Dictionary) -> void:
	pass

## Calls each control element's [method ElementData.OnSaveData]. The results are
## stored in a dictionary, with the format node.element_name: node.save_data()
## for each element.  
func save_data():
	return null
