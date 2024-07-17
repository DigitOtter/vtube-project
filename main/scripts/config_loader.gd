class_name ConfigLoader
extends FileDialogClose

static func save_config(file_name: String, gui_menu: GuiTabMenuBase) -> Error:
	var gui_data: Dictionary = gui_menu.save_data()
	var save_data: String = JSON.stringify(gui_data, "\t")
	
	var file := FileAccess.open(file_name, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	
	file.store_string(save_data)
	
	return Error.OK

static func load_config(file_name: String, gui_menu: GuiTabMenuBase) -> Error:
	var file := FileAccess.open(file_name, FileAccess.READ)
	if not file:
		return FileAccess.get_open_error()
	
	var load_data: Dictionary = JSON.parse_string(file.get_as_text())
	gui_menu.load_data(load_data)
	
	return Error.OK

func is_save_mode() -> bool:
	return self.file_mode == FileDialogClose.FILE_MODE_SAVE_FILE
