extends ScrollContainer

func load_data(data: Dictionary):
	return $GuiElements.load_data(data)

func save_data() -> Dictionary:
	return $GuiElements.save_data()
