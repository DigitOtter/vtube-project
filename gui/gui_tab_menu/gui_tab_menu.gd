class_name GuiTabMenu
extends GuiTabMenuBase

const GUI_CONTAINER_NODE := preload("../gui_container_simple/gui_container_simple.tscn")

func _find_tab_id(tab_name: String) -> int:
	var tab_container: TabContainer = self as Node as TabContainer
	for id in range(0, tab_container.get_tab_count()):
		if tab_name == tab_container.get_tab_title(id):
			return id
	
	return -1

func _find_tab(tab_name: String) -> GuiContainerBase:
	var tab_container: TabContainer = self as Node as TabContainer
	var tab_id: int = self._find_tab_id(tab_name)
	if tab_id < 0:
		return null
	
	return tab_container.get_tab_control(tab_id)

## Create new tab for menu
func create_tab(tab_name: String, element_container: GuiContainerBase = null) -> GuiContainerBase:
	if not element_container:
		element_container = GUI_CONTAINER_NODE.instantiate()
	
	# Add new tab to self
	self.add_child(element_container)
	element_container.owner = self
	
	var tab_container: TabContainer = self as Node as TabContainer
	tab_container.set_tab_title(tab_container.get_tab_count()-1, tab_name)
	
	return element_container

## Remove tab from menu
func remove_tab(tab_name: String) -> void:
	var tab_node := self._find_tab(tab_name)
	if not tab_node:
		return
	
	self.remove_child(tab_node)
	tab_node.owner = null
	tab_node.queue_free()

## Get tab from menu
func get_tab(tab_name: String) -> GuiContainerBase:
	return self._find_tab(tab_name)

## Set tab as active
func select_tab(tab_name: String) -> bool:
	var tab_id: int = self._find_tab_id(tab_name)
	if tab_id < 0:
		return false
	
	var tab_container: TabContainer = self as Node as TabContainer
	tab_container.set_current_tab(tab_id)
	return true

## Push tab to front of tab menu
func move_tab(tab_name: String, pos: int) -> void:
	var tabs: TabContainer = self as Node
	
	var tab_id: int = -1
	var tab_container: GuiElementBase = null
	for id in range(0, tabs.get_tab_count()):
		if tabs.get_tab_title(id) == tab_name:
			tab_id = id
			tab_container = tabs.get_tab_control(id)
			break
	
	if tab_id < 0:
		return
	
	while pos < 0:
		pos = tabs.get_tab_count() + pos
	
	tabs.get_tab_bar().move_tab(tab_id, pos)
	self.move_child(tab_container, pos)
	
	return

## Calls each control element's [method ElementData.OnLoadData]. 
## For each control element, we look for a key in [param data] with node.get_element_name()
## and pass that to the element.
func load_data(data: Dictionary) -> void:
	var tab_container: TabContainer = self as Node
	for tab_id: int in range(0, tab_container.get_tab_count()):
		var tab_name: String = tab_container.get_tab_title(tab_id)
		var tab_data: Dictionary = data.get(tab_name, null)
		if tab_data == null:
			continue
		
		var container: GuiContainerBase = tab_container.get_tab_control(tab_id)
		container.load_data(tab_data)

## Calls each control element's [method ElementData.OnSaveData]. The results are
## stored in a dictionary, with the format {node.get_element_name(): node.save_data()}
## for each element.  
func save_data():
	var data: Dictionary = {}
	
	var tab_container: TabContainer = self as Node
	for tab_id: int in range(0, tab_container.get_tab_count()):
		var container: GuiContainerBase = tab_container.get_tab_control(tab_id)
		var tab_data: Dictionary = container.call(&"save_data")
		if tab_data != null:
			continue
		
		var tab_name: String = tab_container.get_tab_title(tab_id)
		data[tab_name] = tab_data
	
	return data
