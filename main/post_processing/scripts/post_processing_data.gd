extends RefCounted

var effect_name: StringName
var create_fcn: Callable
var _effect_node: PostProcessingBase = null

func get_or_create_node() -> PostProcessingBase:
	if self._effect_node:
		return self._effect_node
	
	return self.create_fcn.call()

func is_loaded() -> bool:
	return true if self._effect_node else false

func set_effect_node(effect_node: PostProcessingBase):
	self._effect_node = effect_node

func get_effect_node() -> PostProcessingBase:
	return self._effect_node
