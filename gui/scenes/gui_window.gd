extends Window

func _ready():
	# Close on startup
	self.hide()
	
	# Close window when 'X' button is pressed
	self.connect("close_requested", hide)

func get_gui_elements() -> GuiElements:
	return $ScrollableWindow/GuiElements

## Open GUI window and switch to [param selected_tab]
func open_window(selected_tab: String = ""):
	# Open window
	self.popup()
	
	# Set current tab to selected_tab
	if not selected_tab.is_empty():
		var tab_node: GuiElements = self.get_gui_elements()
		for i in range(0,tab_node.get_tab_count()):
			if tab_node.get_tab_title(i) == selected_tab:
				tab_node.set_current_tab(i)
				break
