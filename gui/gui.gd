#class_name Gui
extends Node
## Gui Control Node.
##
## Manages the GUI subwindow. [kbd]gui_open[/kbd] opens the window.

const GUI_NODE_PATH: NodePath = "/root/Gui"
const GUI_TAB_MENU_SCENE := preload("./gui_tab_menu/gui_tab_menu.tscn")
const FILE_DIALOG_CLOSE_SCENE := preload("./scenes/file_dialog_close.tscn")

func _init_input():
	InputSetup.set_input_default_key("gui_open", KEY_E, true)

func _input(event):
	if event.is_action_pressed("gui_open"):
		$GuiWindow.open_window()

func _ready():
	self._init_input()

## Access to GUI tab elements
func get_gui_menu() -> GuiSideMenu:
	return $GuiWindow.get_gui_menu()

func open_gui_window():
	$GuiWindow.open_window()
