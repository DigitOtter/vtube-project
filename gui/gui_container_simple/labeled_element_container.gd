extends HSplitContainer

func get_element_name() -> String:
	var element: GuiElementBase = self.get_element()
	if not element:
		return ""
	return element.get_element_name()

func get_element() -> GuiElementBase:
	if self.get_child_count() < 2:
		return null
	return self.get_child(1)
