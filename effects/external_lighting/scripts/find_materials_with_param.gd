extends Object

var shader_param: String

func _iterate_over_node(node: Node) -> Array[ShaderMaterial]:
	var ret: Array[ShaderMaterial] = []
	if node is MeshInstance3D:
		ret += self._iterate_over_mesh_materials(node)
	
	for child in node.get_children():
		ret += self._iterate_over_node(child)
	
	return ret

func _iterate_over_mesh_materials(mesh_instance: MeshInstance3D) -> Array[ShaderMaterial]:
	var ret: Array[ShaderMaterial] = []
	for i in range(0, mesh_instance.get_surface_override_material_count()):
		ret += self._iterate_over_material_passes(mesh_instance.get_active_material(i))
	
	return ret

func _iterate_over_material_passes(material: Material):
	var ret: Array[ShaderMaterial] = []
	while material:
		if material is ShaderMaterial:
			# Check if material has the requested shader_param
			for param_dict in material.shader.get_shader_uniform_list():
				if param_dict.get("name", "") == self.shader_param:
					ret.append(material)
					break
		
		material = material.next_pass
	
	return ret

func _init(shader_param_to_find: String):
	self.shader_param = shader_param_to_find

func find_materials_with_parameter(avatar_base: AvatarBase) -> Array[ShaderMaterial]:
	return self._iterate_over_node(avatar_base.get_avatar_root())
