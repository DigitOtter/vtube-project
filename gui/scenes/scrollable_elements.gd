extends ScrollContainer

var element_name: String = "":
	get:
		return $GuiSideMenu.element_name

func load_data(data: Dictionary):
	return $GuiSideMenu.load_data(data)

func save_data() -> Dictionary:
	return $GuiSideMenu.save_data()
