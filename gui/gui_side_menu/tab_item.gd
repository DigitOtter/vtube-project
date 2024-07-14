extends Button

signal tab_selected(tab_id: int)

var tab_id: int = -1

func _on_toggled(toggled_on: bool):
	# Only allow enable toggle
	if not toggled_on:
		# Prevent disabling
		self.set_pressed_no_signal(true)
	else:
		self.emit_signal(&"tab_selected", self.tab_id)
