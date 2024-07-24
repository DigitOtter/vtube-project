class_name GuiMenuFactory

const Type = GuiTabMenuBase.Type

static func create_new(type: GuiTabMenuBase.Type) -> GuiTabMenuBase:
	var menu: GuiTabMenuBase = null
	if type == Type.SIDE:
		menu = preload("../gui_side_menu/gui_side_menu.tscn").instantiate()
	elif type == Type.TAB:
		menu = preload("../gui_tab_menu/gui_tab_menu.tscn").instantiate()
	return menu
