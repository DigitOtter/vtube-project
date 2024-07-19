class_name PostProcessingManager
extends Node

const GUI_TAB_NAME := &"PostProcessing"

## Control node used for all post-processing effects
var post_processing_node: Control = null

var _post_processing_gui: GuiTabMenu = GuiTabMenuBase.create_new(GuiTabMenuBase.Type.TAB)
var _post_processing_name: String = ""

func _init_gui():
	var gui_menu: GuiTabMenuBase = get_node(Gui.GUI_NODE_PATH).get_gui_menu()
	var element := GuiElement.ElementData.new()
	element.Name = GUI_TAB_NAME
	element.Data = GuiElement.GuiTabMenuData.new()
	element.Data.GuiTabMenuNode = self._post_processing_gui
	
	gui_menu.add_element_to_tab(GUI_TAB_NAME, element)

func _ready():
	self._init_gui()

func get_post_processing_name() -> String:
	return self._post_processing_name

func set_post_processing_name(post_processing_name: String):
	self._post_processing_name = post_processing_name

## Add gui elements when starting post-processing effect
func add_gui():
	pass

## Remove gui elements when stopping post-processing effect
func remove_gui():
	pass
