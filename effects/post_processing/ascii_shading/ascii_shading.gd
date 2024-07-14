extends "../scripts/post_processing_base.gd"

const GUI_TAB_NAME: String = "Ascii Shader"
const ASCII_SHADER_MATERIAL: ShaderMaterial = preload("./shaders/TextShaderMaterial.tres")

signal ascii_shader_toggled
signal ascii_color_toggled
signal ascii_pixelization_changed

var _color_enabled: bool = true
var _pixelization: float = 75.0

func _on_ascii_toggle(enable: bool):
	var main: Main = get_node(Main.MAIN_NODE_PATH)
	if enable:
		main.get_avatar_viewport_container().visible = false
		self.visible = true
		
		# Add shader
		self.material = ASCII_SHADER_MATERIAL
		self.material.setup_local_to_scene()
		self.material.set_shader_parameter(&"view", main.get_avatar_viewport().get_texture())
		self._apply_material_settings()
	else:
		main.get_avatar_viewport_container().visible = true
		self.visible = false
		
		# Remove shader from scene
		self.material = null

func _on_color_toggle(enable: bool):
	self._color_enabled = enable
	if self.material:
		self.material.set_shader_parameter(&"color", enable)

func _on_pixelization_change(pixelization_amount: float):
	self._pixelization = pixelization_amount
	if self.material:
		self.material.set_shader_parameter(&"pixelization", pixelization_amount)

func _apply_material_settings():
	self._on_color_toggle(self._color_enabled)
	self._on_pixelization_change(self._pixelization)

func _init_gui():
	# Toggle Shading
	var ascii_toggle := GuiElement.ElementData.new()
	ascii_toggle.Name = "Enable ASCII Shading"
	ascii_toggle.OnDataChangedCallable = self._on_ascii_toggle
	ascii_toggle.SetDataSignal = [ self, &"ascii_shader_toggled" ]
	ascii_toggle.OnLoadData = func(enabled: bool) -> bool: return enabled
	ascii_toggle.OnSaveData = func(enabled: bool) -> bool: return enabled
	var ascii_toggle_data := GuiElement.CheckBoxData.new()
	ascii_toggle_data.Default = false
	ascii_toggle.Data = ascii_toggle_data
	
	# Toggle Color
	var color_toggle := GuiElement.ElementData.new()
	color_toggle.Name = "Enable Color"
	color_toggle.OnDataChangedCallable = self._on_color_toggle
	color_toggle.SetDataSignal = [ self, &"ascii_color_toggled" ]
	color_toggle.OnLoadData = func(enabled: bool) -> bool: 
		self._color_enabled = enabled
		return self._color_enabled
	color_toggle.OnSaveData = func(_enabled: bool) -> bool: return self._color_enabled
	var color_toggle_data := GuiElement.CheckBoxData.new()
	color_toggle_data.Default = self._color_enabled
	color_toggle.Data = color_toggle_data
	
	# Set _pixelization
	var pixelization_range := GuiElement.ElementData.new()
	pixelization_range.Name = "Pixelization"
	pixelization_range.OnDataChangedCallable = self._on_pixelization_change
	pixelization_range.SetDataSignal = [ self, &"ascii_pixelization_changed" ]
	pixelization_range.OnLoadData = func(pixelization_amount: float) -> float: 
		self._pixelization = pixelization_amount
		return self._pixelization
	pixelization_range.OnSaveData = func(_pixelization_amount: float) -> float: return self._pixelization
	var pixelization_range_data := GuiElement.SliderData.new()
	pixelization_range_data.Default  = self._pixelization
	pixelization_range_data.Step     = 1
	pixelization_range_data.MinValue = 0
	pixelization_range_data.MaxValue = 1000
	pixelization_range.Data = pixelization_range_data
	
	var tab_elements: Array[GuiElement.ElementData] = [ascii_toggle, color_toggle, pixelization_range]
	
	var gui_menu: GuiTabMenuBase = get_node(Gui.GUI_NODE_PATH).get_gui_menu()
	gui_menu.add_elements_to_tab(GUI_TAB_NAME, tab_elements)

func _ready():
	super()
	self._init_gui()

func toggle_ascii_shader(enabled: bool):
	self.emit_signal(&"ascii_shader_toggled", enabled, true)

func toggle_ascii_color(enabled: bool):
	self.emit_signal(&"ascii_color_toggled", enabled, true)

func set_ascii_pixelization(pixelization_amount: float):
	self.emit_signal(&"ascii_pixelization_changed", pixelization_amount, true)
