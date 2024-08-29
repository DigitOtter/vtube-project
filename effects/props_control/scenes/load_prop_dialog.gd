extends FileDialog

signal prop_file_selected(file_path: String)

func _on_file_selected(path):
	self.prop_file_selected.emit(path)
	self.hide()

func _on_close_requested():
	self.prop_file_selected.emit("")
	self.hide()
