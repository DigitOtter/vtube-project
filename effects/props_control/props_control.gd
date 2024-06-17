class_name PropsControl
extends Node

const SELECT_COLLISION_LAYER: int = 2
const CLICKABLE_AREA = preload("./scenes/clickable_area_3d.tscn")
const MAINTAIN_POSE_SCRIPT = preload("./scripts/prop_maintain_pose.gd")
const GUI_TAB_NAME: String = "Props"
const BORDER_HIGHLIGHT_SHADER: ShaderMaterial = preload("./shaders/border_highlighting.material")
const LOAD_PROP_DIALOG = preload("./scenes/load_prop_dialog.tscn")

signal load_prop_signal
signal change_prop_to_create_sig
signal update_asset_list(asset_list: Array[String], default: int)

var _prop_file_to_create: String
var _selected_prop: Node3D

var _load_prop_dialog: FileDialog = null

@onready
var _available_props: Array[Node3D] = []

@export
var camera: Camera3D = null

func _load_prop(
		asset_file_path: String, 
		mesh_triangle_point: MeshTrianglePoint) -> Node3D:
	var new_prop: Node3D = AssetManager.load_asset(asset_file_path)
	if new_prop is Sprite3D:
		self._configure_sprite3d_prop(new_prop, mesh_triangle_point)
	
	if new_prop:
		new_prop.asset_file = asset_file_path
	
	self.set_selected_prop(new_prop)
	return new_prop

func _configure_sprite3d_prop(
		prop: Sprite3D, 
		mesh_triangle_point: MeshTrianglePoint):
	# Make prop selectable
	var clickable_area: Area3D = CLICKABLE_AREA.instantiate()
	prop.add_child(clickable_area)
	clickable_area.owner = prop
	
	# Set selectable area
	var collision_shape: CollisionShape3D = clickable_area.get_child(0)
	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = Vector3(prop.texture.get_width()*prop.pixel_size, prop.texture.get_height()*prop.pixel_size, 0.05)
	
	# Add script to maintain prop pose on triangle
	prop.set_script(MAINTAIN_POSE_SCRIPT)
	prop.set_process(true)
	prop.request_ready()
	
	mesh_triangle_point.mesh_instance.add_child(prop)
	prop.owner = mesh_triangle_point.mesh_instance
	
	# Update prop pose
	prop.mesh_triangle_point = mesh_triangle_point
	prop.triangle_transform  = AvatarSelect.get_triangle_transform(prop.mesh_triangle_point, Basis())
	prop.update_pose()
	
	return prop

func _create_prop(avatar_camera: Camera3D, pixel: Vector2i):
	var mesh_triangle_point: MeshTrianglePoint = AvatarSelect.select_triangle(avatar_camera, pixel)
	if mesh_triangle_point.mesh_instance:
		var asset_file_path: String = self._prop_file_to_create
		var new_prop: Node3D = self._load_prop(asset_file_path, mesh_triangle_point)
		if new_prop:
			self._available_props.append(new_prop)

func _on_prop_load_requested(toggled: bool):
	if not toggled:
		return
	
	if self._load_prop_dialog:
		return
	
	self._load_prop_dialog = LOAD_PROP_DIALOG.instantiate()
	self._load_prop_dialog.connect("prop_file_selected", _on_prop_file_selected)
	
	self.add_child(self._load_prop_dialog)

func _on_prop_file_selected(prop_path: String):
	if self._load_prop_dialog:
		self._load_prop_dialog.queue_free()
		self._load_prop_dialog = null
	
	# Update GUI on selection
	if prop_path:
		AssetManager.add_file(prop_path)
		self._prop_file_to_create = prop_path
		self.update_prop_list(AssetManager.list_available_assets())

func update_prop_list(asset_list: Array[String]):
	# Update GUI prop selection list
	var default = asset_list.find(self._prop_file_to_create)
	self.emit_signal("update_asset_list", asset_list, default if default != null else -1)

func _on_selected_prop_changed(selected_prop: String):
	self._prop_file_to_create = selected_prop

func _load_props(prop_data: Array[String]) -> String:
	# First value is "prop_to_load"
	var prop_to_load: String = prop_data[0]
	
	var avatar_scene_node: Node = get_node(Main.MAIN_NODE_PATH).get_avatar_root_node()
	for pdat in prop_data.slice(1):
		var deser_dat: Dictionary = SerializePropData.deserialize_prop(avatar_scene_node, pdat)
		var prop: Node3D = self._load_prop(deser_dat["asset_file"], deser_dat["mtp"])
		if prop:
			prop.triangle_transform = deser_dat["triangle_transform"]
	
	return prop_to_load

func _init_gui():
	var tab_elements: Array[GuiElements.ElementData] = []
	
	# Prop loading
	var prop_loading: GuiElements.ElementData = GuiElements.ElementData.new()
	prop_loading.Name = "Load prop"
	prop_loading.OnDataChangedCallable = self._on_prop_load_requested
	prop_loading.SetDataSignal = [ self, "load_prop_signal" ]
	var prop_loading_data: GuiElements.ButtonData = GuiElements.ButtonData.new()
	prop_loading_data.Text = "Load Property"
	prop_loading.Data = prop_loading_data
	
	tab_elements.append(prop_loading)
	
	# Prop selection
	var prop_selection: GuiElements.ElementData = GuiElements.ElementData.new()
	prop_selection.Name = "Current Prop"
	prop_selection.OnDataChangedCallable = self._on_selected_prop_changed
	prop_selection.SetDataSignal = [ self, "change_prop_to_create_sig"]
	prop_selection.OnSaveData = func(val: String) -> Array[String]:
		var avatar_scene_node: Node = get_node(Main.MAIN_NODE_PATH).get_avatar_root_node()
		var ser: Array[String] = [ val ]
		for prop in self._available_props:
			ser.append(SerializePropData.serialize_prop(avatar_scene_node, prop))
		
		return ser
	
	var prop_selection_data: GuiElements.MenuSelectData = GuiElements.MenuSelectData.new()
	prop_selection_data.Items = AssetManager.list_available_assets()
	if prop_selection_data.Items.is_empty():
		prop_selection_data.Default = -1
		self._prop_file_to_create = ""
	else:
		prop_selection_data.Default = 0
		self._prop_file_to_create = prop_selection_data.Items[prop_selection_data.Default]
	prop_selection_data.UpdateMenuSignal = [ self, "update_asset_list" ]
	prop_selection.Data = prop_selection_data
	
	tab_elements.append(prop_selection)
	
	var gui_elements: GuiElements = get_node(Gui.GUI_NODE_PATH).get_gui_elements()
	gui_elements.add_element_tab(GUI_TAB_NAME, tab_elements)

func _highlight_prop(prop: Node3D):
	if prop is Sprite3D:
		var border_shader: ShaderMaterial = BORDER_HIGHLIGHT_SHADER
		border_shader.set_shader_parameter("border_width", Vector2(0.01, 0.01*prop.texture.get_size().aspect()))
		prop.set_material_overlay(border_shader)

func _unhighlight_prop(prop: Node3D):
	if prop is Sprite3D:
		prop.set_material_overlay(null)

func _init_input():
	InputSetup.set_input_default_mouse_button("prop_add",      MOUSE_BUTTON_RIGHT, true, true)
	InputSetup.set_input_default_mouse_button("prop_deselect", MOUSE_BUTTON_LEFT)


func _input(event):
	if event.is_action_pressed("prop_add"):
		self._create_prop(self.camera, event.position)
	elif event.is_action_pressed("prop_deselect"):
		self.set_selected_prop(null)

func _ready():
	self._init_gui()
	self._init_input()
	MAINTAIN_POSE_SCRIPT._init_input()

func get_selected_prop() -> Node3D:
	return self._selected_prop

func set_selected_prop(prop: Node3D):
	if self._selected_prop:
		self._unhighlight_prop(self._selected_prop)
	
	self._selected_prop = prop
	self._highlight_prop(self._selected_prop)

func change_prop_to_create(prop_name: String, propagate: bool = true):
	self.emit_signal("change_prop_to_create_sig", prop_name, propagate)

func delete_prop(prop_node: Node3D):
	if self._selected_prop as Node3D == prop_node:
		self._selected_prop = null
	self._available_props.erase(prop_node)
	prop_node.queue_free()
