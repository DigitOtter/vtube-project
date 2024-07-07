class_name ConfigLoader
extends FileDialog

func set_save_mode():
	self.file_mode = FileDialog.FILE_MODE_SAVE_FILE

func set_load_mode():
	self.file_mode = FileDialog.FILE_MODE_OPEN_FILE

func is_save_mode() -> bool:
	return self.file_mode == FileDialog.FILE_MODE_SAVE_FILE

static func save_config(file_name: String, gui: GuiElements) -> Error:
	var gui_data: Dictionary = gui.save_data()
	var save_data: String = JSON.stringify(gui_data, "\t")
	
	var file := FileAccess.open(file_name, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	
	file.store_string(save_data)
	
	return Error.OK

static func load_config(file_name: String, gui: GuiElements) -> Error:
	var file := FileAccess.open(file_name, FileAccess.READ)
	if not file:
		return FileAccess.get_open_error()
	
	var load_data: Dictionary = JSON.parse_string(file.get_as_text())
	gui.load_data(load_data)
	
	return Error.OK
