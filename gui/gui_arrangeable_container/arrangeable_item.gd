extends HBoxContainer

func add_gui_element(element: Control):
	if self.get_child_count() > 2:
		push_warning("Node already contains a gui element")
	self.add_child(element)
	self.move_child(element, 1)
	
	element.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func get_label() -> Label:
	return self.get_child(0)

func get_element() -> GuiElementBase:
	var element_node: Node = self.get_child(1)
	if not element_node or not element_node is GuiElementBase:
		return null
	return element_node

func get_element_name() -> String:
	var element_node: Node = self.get_child(1)
	if not element_node or not element_node is GuiElementBase:
		return ""
	
	return (element_node as GuiElementBase).get_element_name()

func get_move_up_button() -> Button:
	return %MoveUp

func get_move_down_button() -> Button:
	return %MoveDown
