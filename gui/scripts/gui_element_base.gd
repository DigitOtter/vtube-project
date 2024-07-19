class_name GuiElementBase
extends Control

var _element_name: String = ""

static func create_element(element_data: GuiElement.ElementData)-> Control:
	return GuiElement.create_element(element_data)

static func create_elements(element_data: Array[GuiElement.ElementData])-> Array[Control]:
	return GuiElement.create_elements(element_data)

# Set name of element. Used during save/load
func set_element_name(element_name: String):
	self._element_name = element_name

# Get name of element. Used during save/load
func get_element_name() -> String:
	return self._element_name

## Load data from variant
func load_data(_data) -> void:
	pass

## Save data to variant
func save_data():
	return null
