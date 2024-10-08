class_name AsciiShading
extends PostProcessingBase

const GUI_TAB_NAME: String = "Ascii Shader"
const ASCII_SHADER_MATERIAL: ShaderMaterial = preload("./shaders/TextShaderMaterial.tres")

signal ascii_color_toggled
signal ascii_pixelization_changed

## Generate effect data. This is used by [PostProcessingManager] to create effect nodes on demand
static func generate_effect_data() -> PostProcessingData:
	var effect_data := PostProcessingData.new()
	effect_data.effect_name = GUI_TAB_NAME
	effect_data.create_fcn = AsciiShading.create
	return effect_data

## Create effect node
static func create() -> PostProcessingBase:
	return preload("./ascii_shading.tscn").instantiate()

func _on_color_toggle(enable: bool):
	%Effect.material.set_shader_parameter(&"color", enable)

func _on_pixelization_change(pixelization_amount: float):
	%Effect.material.set_shader_parameter(&"pixelization", pixelization_amount)

func _init_gui(gui_menu: GuiTabMenuBase):
	# Toggle Color
	var color_toggle := GuiElement.ElementData.new()
	color_toggle.Name = "Enable Color"
	color_toggle.OnDataChangedCallable = self._on_color_toggle
	color_toggle.SetDataSignal = [ self, &"ascii_color_toggled" ]
	var color_toggle_data := GuiElement.CheckBoxData.new()
	color_toggle_data.Default = %Effect.material.get_shader_parameter(&"color")
	color_toggle.Data = color_toggle_data
	
	# Set _pixelization
	var pixelization_range := GuiElement.ElementData.new()
	pixelization_range.Name = "Pixelization"
	pixelization_range.OnDataChangedCallable = self._on_pixelization_change
	pixelization_range.SetDataSignal = [ self, &"ascii_pixelization_changed" ]
	var pixelization_range_data := GuiElement.SliderData.new()
	pixelization_range_data.Default  = %Effect.material.get_shader_parameter(&"pixelization")
	pixelization_range_data.Step     = 1
	pixelization_range_data.MinValue = 0
	pixelization_range_data.MaxValue = 1000
	pixelization_range.Data = pixelization_range_data
	
	var tab_elements: Array[GuiElement.ElementData] = [color_toggle, pixelization_range]
	gui_menu.add_elements_to_tab(GUI_TAB_NAME, tab_elements)

func _ready():
	super()

func toggle_ascii_color(enabled: bool):
	self.ascii_color_toggled.emit(enabled, true)

func set_ascii_pixelization(pixelization_amount: float):
	self.ascii_pixelization_changed.emit(pixelization_amount, true)

## Called when input texture was changed
func update_input_texture(input_texture: Texture2D):
	%Effect.material.set_shader_parameter(&"view", input_texture)

## Add gui elements when starting post-processing effect
func add_gui(post_processing_gui_menu: GuiTabMenuBase):
	self._init_gui(post_processing_gui_menu)

## Remove gui elements when stopping post-processing effect
func remove_gui(post_processing_gui_menu: GuiTabMenuBase):
	post_processing_gui_menu.remove_tab(GUI_TAB_NAME)
