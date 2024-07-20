class_name GuiTabMenuBase
extends GuiElementBase

enum Type {
	TAB,
	SIDE
}

static func create_new(type: Type):
	var menu: GuiTabMenuBase = null
	if type == Type.TAB:
		menu = preload("../gui_tab_menu/gui_tab_menu.tscn").instantiate()
	elif type == Type.SIDE:
		menu = preload("../gui_side_menu/gui_side_menu.tscn").instantiate()
	
	return menu

## Get tab or create it if it doesn't exist yet
func get_or_create_tab(tab_name: String) -> GuiContainerBase:
	var tab := self.get_tab(tab_name)
	return tab if tab else self.create_tab(tab_name)

func add_element_to_tab(tab_name: String, element: GuiElement.ElementData) -> GuiElementBase:
	var tab: GuiContainerBase = self.get_or_create_tab(tab_name)
	return tab.add_element(element)

func add_elements_to_tab(tab_name: String, elements: Array[GuiElement.ElementData]) -> Array[GuiElementBase]:
	var tab: GuiContainerBase = self.get_or_create_tab(tab_name)
	return tab.add_elements(elements)

#################################################
## Create new tab for menu
func create_tab(_tab_name: String) -> GuiContainerBase:
	return null

## Remove tab from menu
func remove_tab(_tab_name: String) -> void:
	pass

## Get tab from menu
func get_tab(_tab_name: String) -> GuiContainerBase:
	return null

## Set tab as active
func select_tab(_tab_name: String) -> bool:
	return false

## Move tab to new position in tab menu. Negative values are counted from the back
func move_tab(_tab_name: String, pos: int) -> void:
	pass

## Load data from dictionary. The function should call element_node.load_data(element_data) 
## for each element in the menu.
## [param_name data] should be of the form 
## { self.name: { 
##     $tab1.name: { $element1.name: Variant, $element2.name: Variant, ... },
##     $tab2.name: { $element1.name: Variant, $element2.name: Variant, ... },
##     ... }
## }
func load_data(_data: Dictionary) -> void:
	pass

## Save data to dictionary. Elements in data should be of the form "$element_name": Variant
## for each element in the menu. The function should call element_node.save_data() for each element
## Return value should be of the form 
## { self.name: { 
##     $tab1.name: { $element1.name: Variant, $element2.name: Variant, ... },
##     $tab2.name: { $element1.name: Variant, $element2.name: Variant, ... },
##     ... }
## }
func save_data():
	return null
