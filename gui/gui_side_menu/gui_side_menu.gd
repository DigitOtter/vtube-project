class_name GuiSideMenu
extends GuiTabMenuBase

const TAB_ITEM_NODE := preload("./tab_item.tscn")
const TAB_ITEM_CLASS: GDScript = preload("./tab_item.gd")

const GUI_CONTAINER_NODE := preload("../gui_arrangeable_container/gui_arrangeable_container.tscn")

func _find_tab_item(tab_name: String) -> TAB_ITEM_CLASS:
	var tab_list: VBoxContainer = %TabList
	for id in range(0, tab_list.get_child_count()):
		var tab_item: TAB_ITEM_CLASS = tab_list.get_child(id)
		if tab_item.name == tab_name:
			return tab_item
	
	return null

func _find_tab_id(tab_name: String) -> int:
	var tab_item: TAB_ITEM_CLASS = self._find_tab_item(tab_name)
	if not tab_item:
		return -1
	return tab_item.tab_id

func _find_tab(tab_name: String) -> GuiContainerBase:
	var tab_id := self._find_tab_id(tab_name)
	if tab_id < 0:
		return null
	
	return %Containers.get_child(tab_id)

func _on_tab_item_selected(tab_id: int):
	var tab_list: VBoxContainer = %TabList
	# Set all other tab items as deselected
	for tab_item: TAB_ITEM_CLASS in tab_list.get_children():
		tab_item.set_pressed_no_signal(false)
	
	# Set tab as selected
	var tab_item: TAB_ITEM_CLASS = tab_list.get_child(tab_id)
	assert(tab_item)
	tab_item.set_pressed_no_signal(true)
	
	# Set correct tab container as visible
	var containers: Control = %Containers
	for container: GuiContainerBase in containers.get_children():
		container.set_visible(false)
	
	var visible_container: GuiContainerBase = containers.get_child(tab_id)
	visible_container.set_visible(true)

func _add_tab_item(tab_name: String) -> TAB_ITEM_CLASS:
	var tab_list: VBoxContainer = %TabList
	
	var tab_item: TAB_ITEM_CLASS = TAB_ITEM_NODE.instantiate()
	tab_item.name = tab_name
	tab_item.text = tab_name
	tab_item.tab_id = tab_list.get_child_count()
	
	tab_list.add_child(tab_item)
	tab_item.owner = tab_list
	
	tab_item.connect(&"tab_selected", self._on_tab_item_selected)
	
	return tab_item

func _ready():
	pass

func _create_tab_internal(tab_name: String) -> GuiContainerBase:
	var tab_container := self._find_tab(tab_name)
	if tab_container:
		return tab_container
	
	var tab_item := self._add_tab_item(tab_name)
	if not tab_item:
		return
	
	var containers = %Containers
	var new_container: GuiContainerBase = GUI_CONTAINER_NODE.instantiate()
	new_container.set_visible(false)
	containers.add_child(new_container)
	new_container.owner = containers
	
	# If this is the first item, set it as selected
	var tab_list: VBoxContainer = %TabList
	if tab_list.get_child_count() == 1:
		tab_item.set_pressed(true)
	
	return new_container

func _create_tab(tab_name: String) -> bool:
	var tab_id = self._create_tab_internal(tab_name)
	return tab_id >= 0

func _remove_tab(tab_name: String) -> bool:
	var tab_id: int = self._find_tab_id(tab_name)
	if tab_id < 0:
		return true
	
	# Remove tab_item
	var tab_list: VBoxContainer = %TabList
	var old_tab_item = tab_list.get_child(tab_id)
	tab_list.remove_child(old_tab_item)
	old_tab_item.owner = null
	old_tab_item.queue_free()
	
	# Remove corresponding container
	var containers: ScrollContainer = %Containers
	var container_node = containers.get_child(tab_id)
	if container_node:
		containers.remove_child(container_node)
		container_node.owner = null
		container_node.queue_free()
	
	# Adjust tab_ids
	for id in range(tab_id, tab_list.get_child_count()):
		var tab_item: TAB_ITEM_CLASS = tab_list.get_child(id)
		tab_item.tab_id -= 1
	
	# Select other tab
	if tab_id >= tab_list.item_count:
		tab_id = tab_list.item_count - 1
	
	if tab_id >= 0:
		tab_list.select(tab_id)
	
	return true

func _add_element_to_tab(tab_name: String, element: GuiElement.ElementData):
	var tab_container: GuiContainerBase = self._create_tab_internal(tab_name)
	assert(tab_container)
	
	return tab_container.add_element(element)

## Create new tab for menu
func create_tab(tab_name: String) -> GuiContainerBase:
	return self._create_tab_internal(tab_name)

## Remove tab from menu
func remove_tab(tab_name: String) -> void:
	var tab_id: int = self._find_tab_id(tab_name)
	if tab_id < 0:
		return
	
	# Remove tab_item
	var tab_list: VBoxContainer = %TabList
	var old_tab_item = tab_list.get_child(tab_id)
	tab_list.remove_child(old_tab_item)
	old_tab_item.owner = null
	old_tab_item.queue_free()
	
	# Remove corresponding container
	var containers: ScrollContainer = %Containers
	var container_node = containers.get_child(tab_id)
	if container_node:
		containers.remove_child(container_node)
		container_node.owner = null
		container_node.queue_free()
	
	# Adjust tab_ids
	for id in range(tab_id, tab_list.get_child_count()):
		var tab_item: TAB_ITEM_CLASS = tab_list.get_child(id)
		tab_item.tab_id -= 1
	
	# Select other tab
	if tab_id >= tab_list.item_count:
		tab_id = tab_list.item_count - 1
	
	if tab_id >= 0:
		tab_list.select(tab_id)
	
	return

## Get tab from menu
func get_tab(tab_name: String) -> GuiContainerBase:
	return self._find_tab(tab_name)

## Set tab as active
func select_tab(tab_name: String) -> bool:
	var tab_item: TAB_ITEM_CLASS = self._find_tab_item(tab_name)
	if not tab_item:
		return false
	
	tab_item.set_pressed(true)
	return true

## Push tab to front of tab menu
func push_tab_to_front(tab_name: String) -> void:
	var tab_id: int = self._find_tab_id(tab_name)
	
	# Move tab_item to front
	var tab_list: VBoxContainer = %TabList
	var tab_item: TAB_ITEM_CLASS = tab_list.get_child(tab_id)
	assert(tab_item)
	tab_list.move_child(tab_item, 0)
	
	# Update tab_ids
	for id in range(0, tab_list.get_child_count()):
		var item: TAB_ITEM_CLASS = tab_list.get_child(id)
		item.tab_id = id
	
	# Move corresponding container to front
	var containers: Control = %Containers
	var tab_container = containers.get_child(tab_id)
	assert(tab_container)
	containers.move_child(tab_container, 0)

## Calls each control element's [method ElementData.OnLoadData]. 
## For each control element, we look for a key in [param data] with node.element_name
## and pass that to the element.
func load_data(data: Dictionary) -> void:
	var tab_list: VBoxContainer = %TabList
	var containers: Control = %Containers
	for tab_item: TAB_ITEM_CLASS in tab_list.get_children():
		var container_data = data.get(tab_item.name, null)
		if container_data == null:
			continue
		
		var container: GuiContainerBase = containers.get_child(tab_item.tab_id)
		container.load_data(container_data)

## Calls each control element's [method ElementData.OnSaveData]. The results are
## stored in a dictionary, with the format {node.element_name: node.save_data()}
## for each element.  
func save_data():
	var data: Dictionary = {}
	
	var tab_list: VBoxContainer = %TabList
	var containers: Control = %Containers
	for tab_item: TAB_ITEM_CLASS in tab_list.get_children():
		var container: GuiContainerBase = containers.get_child(tab_item.tab_id)
		
		var container_data = container.call(&"save_data")
		if container_data != null:
			data[tab_item.name] = container_data
	
	return data
