## Base class for post processing effects
## To add a custom effect, inherit the [method PostProcessingBase.generate_effect_data] 
## and [method PostProcessingBase.create] methods. If the effect should automatically
## be added to [PostProcessingManager], adjust [method PostProcessingBase.available_effects]
class_name PostProcessingBase
extends Control

const PostProcessingData = preload("./post_processing_data.gd")

## Generate list of available effects. Add effects here to register them with PostProcessingManager
static func available_effects() -> Array[PostProcessingData]:
	return [
		AsciiShading.generate_effect_data(),
	]

func _ready():
	pass

## Generate effect data. This is used by [PostProcessingManager] to create effect nodes on demand
static func generate_effect_data() -> PostProcessingData:
	var effect_data := PostProcessingData.new()
	effect_data.effect_name = &""
	effect_data.create_fcn	 = Callable()
	return effect_data

## Create effect node
static func create() -> PostProcessingBase:
	return null

## Updates effect node. Called when effect order has been rearranged and [param_name input_texture] 
## has changed. If [param_name input_texture] is null, assume screen_texture
func update_input_texture(input_texture: Texture2D):
	pass

## Get output texture of this effect. If null, assume screen_texture
func get_output_texture() -> Texture2D:
	return null

## Add gui elements when starting post-processing effect
func add_gui(post_processing_gui_menu: GuiTabMenuBase):
	pass

## Remove gui elements when stopping post-processing effect
func remove_gui(post_processing_gui_menu: GuiTabMenuBase):
	pass
