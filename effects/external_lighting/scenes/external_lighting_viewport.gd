extends SubViewport

const LIGHTING_SHADER_PARAM: String  = "project_texture"
const BLUR_SHADER_PARAM: String      = "blur"
const MIN_COLOR_SHADER_PARAM: String = "min_col"
const FindMaterialsWithParam = preload("../scripts/find_materials_with_param.gd")

signal lighting_toggled(toggle: bool, propagate: bool)
signal lighting_flipped_h(is_flipped: bool, propagate: bool)
signal lighting_min_color_changed(val: float, propagate: bool)
signal lighting_blur_changed(val: float, propagate: bool)

var _active_lighting_texture: Texture2D = null
var _blur_level: float = 0.0
var _min_color: Color = Color(0,0,0,1)

var reactive_materials: Array[ShaderMaterial]

func _on_lighting_toggle(lighting_active: bool):
	self._active_lighting_texture = self.get_texture() if lighting_active else null
	for mat in self.reactive_materials:
		mat.set_shader_parameter(LIGHTING_SHADER_PARAM, self._active_lighting_texture)

func _on_lighting_flipped_h(is_flipped: bool):
	%ExternalTexture.flip_h = is_flipped

func _on_blur_changed(blur_level: float):
	self._blur_level = blur_level
	%BlurTexture.material.set_shader_parameter(BLUR_SHADER_PARAM, self._blur_level)

func _on_min_color_changed(min_color_value: float):
	self._set_min_color(Color(min_color_value, min_color_value, min_color_value))

func _set_min_color(min_color: Color):
	self._min_color = min_color
	%BlurTexture.material.set_shader_parameter(MIN_COLOR_SHADER_PARAM, self._min_color)

func _init_gui(gui_menu: GuiTabMenuBase):
	var control_elements: Array[GuiElement.ElementData] = []
	
	# Lighting toggle
	var toggle_lighting := GuiElement.ElementData.new()
	toggle_lighting.Name = "Toggle Lighting"
	toggle_lighting.Data = GuiElement.CheckBoxData.new()
	toggle_lighting.Data.Default = false
	toggle_lighting.OnDataChangedCallable = self._on_lighting_toggle
	toggle_lighting.SetDataSignal = [ self, &"lighting_toggled" ]
	
	control_elements.append(toggle_lighting)
	
	# Lighting toggle
	var flip_lighting := GuiElement.ElementData.new()
	flip_lighting.Name = "Flip Texture H"
	flip_lighting.Data = GuiElement.CheckBoxData.new()
	flip_lighting.Data.Default = $ExternalTexture.flip_h
	flip_lighting.OnDataChangedCallable = self._on_lighting_flipped_h
	flip_lighting.SetDataSignal = [ self, &"lighting_flipped_h" ]
	
	control_elements.append(flip_lighting)
	
	# Blur level
	var blur_level_limits := GuiElement.SliderData.new()
	blur_level_limits.MinValue = 0.0
	blur_level_limits.MaxValue = 20.0
	blur_level_limits.Step     = 0.1
	blur_level_limits.Default  = 5.3
	
	var blur_level := GuiElement.ElementData.new()
	blur_level.Name = "Blur"
	blur_level.Data = blur_level_limits
	blur_level.OnDataChangedCallable = self._on_blur_changed
	blur_level.SetDataSignal = [ self, &"lighting_blur_changed" ]
	
	control_elements.append(blur_level)
	
	# Min Lighting color
	var min_color_limits := GuiElement.SliderData.new()
	min_color_limits.MinValue = 0.0
	min_color_limits.MaxValue = 1.0
	min_color_limits.Step     = 0.05
	min_color_limits.Default  = 0.1
	
	var min_color := GuiElement.ElementData.new()
	min_color.Name = "Minimum Color"
	min_color.Data = min_color_limits
	min_color.OnDataChangedCallable = self._on_min_color_changed
	min_color.SetDataSignal = [ self, &"lighting_min_color_changed" ]
	
	control_elements.append(min_color)
	
	gui_menu.add_elements_to_tab("External Lighting", control_elements)

func _init_input():
	InputSetup.set_input_default_key(&"external_lighting_toggle",      KEY_KP_1, true)
	InputSetup.set_input_default_key(&"external_lighting_min_col_dec", KEY_KP_2, true)
	InputSetup.set_input_default_key(&"external_lighting_min_col_inc", KEY_KP_3, true)
	InputSetup.set_input_default_key(&"external_lighting_flip_h",      KEY_KP_4, true)
	InputSetup.set_input_default_key(&"external_lighting_blur_dec",    KEY_KP_5, true)
	InputSetup.set_input_default_key(&"external_lighting_blur_inc",    KEY_KP_6, true)

func _handle_input(event):
	# Subviewport doesn't handle _input() for some reason, use a parent node instead
	if event.is_action_pressed(&"external_lighting_toggle"):
		var lighting_active: bool = self._active_lighting_texture != null
		self.lighting_toggled.emit(!lighting_active, true)
	elif event.is_action_pressed(&"external_lighting_flip_h", true):
		self.lighting_flipped_h.emit(!%ExternalTexture.flip_h, true)
	elif event.is_action_pressed(&"external_lighting_min_col_inc", true):
		var new_col: Color = self._min_color + Color(0.05, 0.05, 0.05)
		self.lighting_min_color_changed.emit(new_col.r, true)
	elif event.is_action_pressed(&"external_lighting_min_col_dec", true):
		var new_col: Color = self._min_color + Color(-0.05, -0.05, -0.05)
		self.lighting_min_color_changed.emit(new_col.r, true)
	elif event.is_action_pressed(&"external_lighting_blur_inc", true):
		self.lighting_blur_changed.emit(self._blur_level + 0.1, true)
	elif event.is_action_pressed(&"external_lighting_blur_dec", true):
		self.lighting_blur_changed.emit(self._blur_level - 0.1, true)

func _ready():
	self._init_gui(get_node(Gui.GUI_NODE_PATH).get_gui_menu())
	self._init_input()
	get_node(Main.MAIN_NODE_PATH).connect_avatar_loaded(update_reactive_materials)

func update_reactive_materials(avatar_base: AvatarBase):
	var find_materials: FindMaterialsWithParam = FindMaterialsWithParam.new(LIGHTING_SHADER_PARAM)
	self.reactive_materials = find_materials.find_materials_with_parameter(avatar_base)
	for mat in self.reactive_materials:
		mat.set_shader_parameter(LIGHTING_SHADER_PARAM, self._active_lighting_texture)
	
	self._on_blur_changed(self._blur_level)
	self._set_min_color(self._min_color)
