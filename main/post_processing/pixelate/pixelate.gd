class_name Pixelate
extends PostProcessingBase

const PIXELATE_EFFECT_NAME := &"Pixelate"

signal pixelation_amount_change(amount: float, propagate: bool)

func _on_pixelation_amount_change(amount: float):
	self.get_child(0).material.set_shader_parameter(&"amount", amount)

## Generate effect data. This is used by [PostProcessingManager] to create effect nodes on demand
static func generate_effect_data() -> PostProcessingData:
	var effect_data := PostProcessingData.new()
	effect_data.effect_name = PIXELATE_EFFECT_NAME
	effect_data.create_fcn = func(): return Pixelate.create()
	return effect_data

## Create effect node
static func create() -> PostProcessingBase:
	return preload("./pixelate.tscn").instantiate()

## Called when input texture was changed
func update_input_texture(input_texture: Texture2D):
	self.get_child(0).material.set_shader_parameter(&"input_texture", input_texture)

## Add gui elements when starting post-processing effect
func add_gui(post_processing_gui_menu: GuiTabMenuBase):
	var pixelation_amount_element := GuiElement.ElementData.new()
	pixelation_amount_element.Name = &"Amount"
	pixelation_amount_element.OnDataChangedCallable = self._on_pixelation_amount_change
	pixelation_amount_element.SetDataSignal = [ self, &"pixelation_amount_change" ]
	pixelation_amount_element.Data = GuiElement.SliderData.new()
	pixelation_amount_element.Data.Default = self.get_child(0).material.get_shader_parameter(&"amount")
	pixelation_amount_element.Data.MinValue = 1
	pixelation_amount_element.Data.MaxValue = 1000
	pixelation_amount_element.Data.Step = 1
	
	post_processing_gui_menu.add_elements_to_tab(PIXELATE_EFFECT_NAME, [ pixelation_amount_element ])

## Remove gui elements when stopping post-processing effect
func remove_gui(post_processing_gui_menu: GuiTabMenuBase):
	post_processing_gui_menu.remove_tab(PIXELATE_EFFECT_NAME)
