extends HSplitContainer

func get_element_name() -> String:
	if self.get_child_count() < 2:
		return ""
	
	var element: GuiElementBase = self.get_child(1)
	return element.element_name
