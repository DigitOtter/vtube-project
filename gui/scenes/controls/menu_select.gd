extends MenuBar

signal menu_item_selected

# Name of element. Used during save/load
var element_name: String = ""

# Callable of the form on_save_data_fcn(gui_value: Dictionary{"menu_packed": PackedScene, "selected": String})
var on_save_data_fcn: Callable

# Callable of the form on_load_data_fcn(stored_value) -> Dictionary{"menu_packed": PackedScene, "selected": String}
var on_load_data_fcn: Callable


########################################################################
## Signals
func _on_popup_menu_index_pressed(index):
	var selected_item: String = $PopupMenu.get_item_text(index)
	self.set_menu_title(0, selected_item)
	self.emit_signal("menu_item_selected", selected_item)

func _on_external_data_changed(selected_menu_item: String, propagate: bool):
	for i in range(0, $PopupMenu.item_count):
		if $PopupMenu.get_item_text(i) == selected_menu_item:
			self.set_menu_title(0, selected_menu_item)
			if propagate:
				self.emit_signal("menu_item_selected", selected_menu_item)
			break

func _on_update_menu(menu_items: Array[String], default_selection: int):
	$PopupMenu.clear()
	self.setup_menu(menu_items, default_selection)

func setup_update_menu_signal(signal_data: Array):
	if !signal_data.is_empty():
		signal_data[0].connect(signal_data[1], self._on_update_menu)

func setup_menu(menu_items: Array[String], default_selection: int):
	for item in menu_items:
		$PopupMenu.add_item(item)
	
	if default_selection >= 0:
		self.set_menu_title(0, menu_items[default_selection])

func serialize_menu() -> Dictionary:
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack($PopupMenu)
	
	return { "menu_packed": packed_scene, "selected": self.get_menu_title(0) }

func save_data():
	var save_value = self.serialize_menu()
	if self.on_save_data_fcn:
		save_value = self.on_save_data_fcn.call(save_value)
	
	return save_value

func load_data(stored_value):
	if self.on_load_data_fcn:
		stored_value = self.on_load_data_fcn.call(stored_value)
	
	# Replace popup menu with stored scene
	var packed_scene: PackedScene = stored_value["menu_packed"]
	var sel_val: String = stored_value["selected"]
	
	$PopupMenu.owner = null
	self.remove_child($PopupMenu)
	$PopupMenu.queue_free()
	
	var popup_menu: PopupMenu = packed_scene.instantiate()
	self.add_child(popup_menu)
	popup_menu.owner = self
	popup_menu.connect("index_pressed", self._on_popup_menu_index_pressed)
	
	self._on_external_data_changed(sel_val, true)
