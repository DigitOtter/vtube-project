extends Window

func _ready():
	# Close on startup
	self.hide()
	
	# Close window when 'X' button is pressed
	self.connect(&"close_requested", hide)

func get_gui_menu() -> GuiSideMenu:
	return $ScrollableWindow/GuiSideMenu

## Open GUI window and switch to [param selected_tab]
func open_window(selected_tab: String = ""):
	# Open window
	self.popup()
	
	# Set current tab to selected_tab
	if not selected_tab.is_empty():
		var menu: GuiSideMenu = self.get_gui_menu()
		menu.select_tab(selected_tab)
