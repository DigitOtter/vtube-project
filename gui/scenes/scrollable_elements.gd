extends GuiElementBase

func get_element_name() -> String:
	return $GuiSideMenu.get_element_name()

func load_data(data: Dictionary):
	return $GuiSideMenu.load_data(data)

func save_data():
	return $GuiSideMenu.save_data()
