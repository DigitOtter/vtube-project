extends FileDialog

signal model_file_selected(file_path: String)

func _on_file_selected(path):
	self.emit_signal("model_file_selected", path)
	self.hide()

func _on_canceled():
	self.emit_signal("model_file_selected", "")
	self.hide()
