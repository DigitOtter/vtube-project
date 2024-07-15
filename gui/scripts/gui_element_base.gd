class_name GuiElementBase
extends Control

# Name of element. Used during save/load
@export var element_name: String = ""

static func create_element(element_data: GuiElement.ElementData)-> Control:
	return GuiElement.create_element(element_data)

static func create_elements(element_data: Array[GuiElement.ElementData])-> Array[Control]:
	return GuiElement.create_elements(element_data)

## Load data from variant
func load_data(_data) -> void:
	pass

## Save data to variant
func save_data():
	return null
