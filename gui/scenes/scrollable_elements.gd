extends ScrollContainer

var element_name: String = "":
	get:
		return $GuiElements.element_name

func load_data(data: Dictionary):
	return $GuiElements.load_data(data)

func save_data() -> Dictionary:
	return $GuiElements.save_data()
