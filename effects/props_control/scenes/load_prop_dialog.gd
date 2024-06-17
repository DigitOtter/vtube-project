extends FileDialog

signal prop_file_selected(file_path: String)

func _on_file_selected(path):
	self.emit_signal("prop_file_selected", path)
	self.hide()

func _on_close_requested():
	self.emit_signal("prop_file_selected", "")
	self.hide()
