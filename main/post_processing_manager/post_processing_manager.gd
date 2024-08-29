class_name PostProcessingManager
extends Control

const GUI_TAB_NAME := &"PostProcessing"
const PostProcessingData = PostProcessingBase.PostProcessingData

signal effect_toggle(effect_name: String, enable: bool)


## Input node for all post-processing effects
var _input_node: SubViewportContainer = null

## Input texture for first effect in chain. If null, assume screen_texture
var _input_texture: Texture2D = null

var _post_processing_order_gui: GuiArrangeableContainer = GuiContainerBase.create_new(GuiContainerBase.Type.ARRANGEABLE)
var _post_processing_gui: GuiTabMenu = GuiMenuFactory.create_new(GuiMenuFactory.Type.TAB)

## List of available effects. Can be toggled via GUI.
var _available_effects: Array[PostProcessingData] = []

func _on_input_resized():
	var p_size := self._input_node.size
	for effect: PostProcessingBase in self.get_children():
		effect.resize_effect(p_size)
	
	self._update_texture_chain()

func _compute_element_node_pos(effect_data: PostProcessingData):
	var node_pos: int = 0
	for data: PostProcessingData in self._available_effects:
		if data.effect_name == effect_data.effect_name:
			break
		elif data.is_loaded():
			node_pos += 1
	return node_pos

func _on_gui_reorder(effect_name: String, new_gui_pos: int):
	var effect_data := self._find_effect_data(effect_name)
	self._available_effects.erase(effect_data)
	self._available_effects.insert(new_gui_pos, effect_data)
	
	if not effect_data.is_loaded():
		return
	
	# Move node to new pos in chain
	var new_node_pos: int = self._compute_element_node_pos(effect_data)
	self.move_child(effect_data.get_effect_node(), new_node_pos)
	
	self._update_texture_chain()

func _create_effect_node(effect_data: PostProcessingData) -> PostProcessingBase:
	var effect_node: PostProcessingBase = effect_data.get_effect_node()
	if effect_node:
		return effect_node
	
	effect_node = effect_data.get_or_create_node()
	if not effect_node:
		return null
	
	self.add_child(effect_node)
	effect_node.owner = self
	effect_data.set_effect_node(effect_node)
	
	self._reorder_effect_nodes()
	
	return effect_node

func _reorder_effect_nodes():
	# Reorder nodes
	var node_id: int = 0
	for effect_data: PostProcessingData in self._available_effects:
		var effect_node := effect_data.get_effect_node()
		if not effect_node:
			continue
		self.move_child(effect_node, node_id)
		node_id += 1
	
	self._update_texture_chain()

func _update_texture_chain():
	var prev_texture: Texture2D = self._input_texture
	for effect: PostProcessingBase in self.get_children():
		effect.update_input_texture(prev_texture)
		prev_texture = effect.get_output_texture()
	
	self.material.set_shader_parameter(&"view_texture", prev_texture)
	
	# Adjust visibility
	var effect_visible: bool = self.get_child_count() > 0
	self.visible = effect_visible
	#if self._input_node:
		## When toggling visibility, the update_mode is automatically set to disabled.
		## As we still want the avatar to be updated, re-enable update_mode
		#self._input_node.visible = !effect_visible
		#self._input_node.set_process_input(true)
		#self._input_node.set_process_unhandled_input(true)
		#self._input_node.set_process(true)
		#self._input_node.set_physics_process(true)
		#var input_view_port: SubViewport = self._input_node.get_child(0)
		#if input_view_port:
			#input_view_port.set_update_mode(SubViewport.UPDATE_ALWAYS)
			#input_view_port.set_process_input(true)
			#input_view_port.set_process_unhandled_input(true)
			#input_view_port.set_process(true)
			#input_view_port.set_physics_process(true)

func _on_effect_toggled(effect_name: String, enabled: bool):
	if enabled:
		self._start_effect(effect_name)
	else:
		self._stop_effect(effect_name)

func _start_effect(effect_name: StringName):
	var effect_data := self._find_effect_data(effect_name)
	if not effect_data or effect_data.is_loaded():
		return
	
	var effect_node := self._create_effect_node(effect_data)
	if effect_node:
		effect_node.add_gui(self._post_processing_gui)
		# Make sure gui is removed when node is deleted
		effect_node.connect(&"tree_exiting", func():
			effect_node.remove_gui(self._post_processing_gui)
		)
		
		# Set to proper size on start
		if self._input_node:
			effect_node.resize_effect(self._input_node.size)

func _stop_effect(effect_name: StringName):
	var old_effect_data := self._find_effect_data(effect_name)
	if not old_effect_data or not old_effect_data.is_loaded():
		return
	
	var effect_node := old_effect_data.get_effect_node()
	self.remove_child(effect_node)
	effect_node.owner = null
	effect_node.queue_free()
	old_effect_data.set_effect_node(null)
	
	self._update_texture_chain()

func _find_effect_data(effect_name: StringName) -> PostProcessingData:
	for effect_data: PostProcessingData in self._available_effects:
		if effect_name == effect_data.effect_name:
			return effect_data
	return null

func _generate_toggle_ui(effect_data: PostProcessingData):
	var gui_menu := self._post_processing_order_gui
	var effect_name: StringName = effect_data.effect_name
	
	var toggle_element := GuiElement.ElementData.new()
	toggle_element.Name = effect_name
	toggle_element.OnDataChangedCallable = func(enabled: bool):
		self._on_effect_toggled(effect_name, enabled)
	toggle_element.SetDataSignal = [ self, &"effect_toggle" ]
	toggle_element.Data = GuiElement.CheckBoxData.new()
	(toggle_element.Data as GuiElement.CheckBoxData).Default = false
	
	gui_menu.add_element(toggle_element)

func _init_gui():
	self._post_processing_order_gui.connect(&"element_moved", self._on_gui_reorder)
	
	var gui_menu: GuiTabMenuBase = get_node(Gui.GUI_NODE_PATH).get_gui_menu()
	var effect_order := GuiElement.ElementData.new()
	effect_order.Name = "Effect Order"
	effect_order.Data = GuiElement.GuiContainerData.new()
	effect_order.Data.GuiContainerNode = self._post_processing_order_gui
	
	var effect_gui := GuiElement.ElementData.new()
	effect_gui.Name = "Effect Options"
	effect_gui.Data = GuiElement.GuiTabMenuData.new()
	effect_gui.Data.GuiTabMenuNode = self._post_processing_gui
	
	gui_menu.add_elements_to_tab(GUI_TAB_NAME, [effect_order, effect_gui])

func _ready():
	var main: Main = get_node(Main.MAIN_NODE_PATH)
	var input_node := main.get_avatar_viewport_container()
	var input_texture := main.get_avatar_viewport().get_texture()
	self.set_input_node(input_node, input_texture)
	
	self._init_gui()
	
	var effect_classes := PostProcessingBase.available_effects()
	for class_type in effect_classes:
		self.register_effect(class_type)

func set_input_node(input_node: Control, input_texture: Texture2D = null):
	# Disconnect old signal
	if self._input_node:
		self._input_node.disconnect(&"resized", self._on_input_resized)
	
	# Reconnect resize signal
	self._input_node = input_node
	if self._input_node:
		self._input_node.connect(&"resized", self._on_input_resized)
	
	self._input_texture = input_texture
	self._reorder_effect_nodes()

func register_effect(effect_data: PostProcessingData):
	var reg_effect := self._find_effect_data(effect_data.effect_name)
	if reg_effect:
		reg_effect.effect_name = effect_data.effect_name
		reg_effect.create_fcn = effect_data.create_fcn
		return reg_effect
	
	self._available_effects.push_back(effect_data)
	self._generate_toggle_ui(effect_data)

func toggle_effect(effect_name: String) -> void:
	self.effect_toggle.emit(effect_name, true)
