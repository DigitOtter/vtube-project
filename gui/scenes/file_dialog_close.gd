## FileDialog that closes itself automatically when selection is confirmed or canceled
class_name FileDialogClose
extends FileDialog

## Called when a file is selected. Should be of the form func(file_path: String)
var _user_on_file_selected: Callable

## Called when file selection is canceled. Should be of the form func(dialog_dir: String)
var _user_on_cancelled: Callable

var _destroy_on_close: bool = true

func _set_file_mode(dialog_mode: FileDialog.FileMode, title: String = ""):
	self.title = ""
	self.file_mode = dialog_mode
	if not title.is_empty():
		self.title = title

func _finish_dialog():
	self.hide()
	
	if self._destroy_on_close:
		#self.get_parent().remove_child(self)
		#self.owner = null
		self.queue_free()

func _on_file_selected(path: String):
	if self._user_on_file_selected.is_valid():
		self._user_on_file_selected.callv([path])
	
	self._finish_dialog()

func _on_canceled():
	if self._user_on_cancelled.is_valid():
		self._user_on_cancelled.callv([self.current_dir])
	
	self._finish_dialog()

## Initialize dialog. 
## [param_name on_file_selected] should be a function of the form func(file_path: String)
## [param_name on_cancelled] should be a function of the form func(dialog_dir_path: String)
## [param_name save_mode] if true, sets dialog to save mode; if false, sets dialog to load mode
## [param_name destroy_on_close] if true, dialog node is freed on close
func initialize(on_file_selected: Callable, 
				on_cancelled: Callable, 
				save_mode: bool = false,
				title: String = "",
				destroy_on_close: bool = true):
	self._user_on_file_selected = on_file_selected
	self._user_on_cancelled = on_cancelled
	
	self._destroy_on_close = destroy_on_close
	
	self.set_save_file_mode(save_mode, title)

## Sets dialog to either save (if [param_name save_mode] is true) or load a file
func set_save_file_mode(save_mode: bool, title: String = ""):
	if save_mode:
		self._set_file_mode(FileDialog.FILE_MODE_SAVE_FILE, title)
	else:
		self._set_file_mode(FileDialog.FILE_MODE_OPEN_FILE, title)
