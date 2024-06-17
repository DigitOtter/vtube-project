extends Area3D

func _input_event(_camera, event, _position, _normal, _shape_idx):
	self.get_parent()._handle_input(event)
