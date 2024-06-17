class_name SerializePropData

static func serialize_mtp(avatar_scene_node: Node, mtp: MeshTrianglePoint) -> String:
	var ser_dict: Dictionary = {}
	ser_dict["mesh_instance_path"] = avatar_scene_node.get_path_to(mtp.mesh_instance)
	ser_dict["point_on_triangle"] = mtp.point_on_triangle
	ser_dict["ray_origin_dist"] = mtp.ray_origin_dist
	ser_dict["surface_id"] = mtp.surface_id
	ser_dict["vertex_ids"] = mtp.vertex_ids
	
	return JSON.stringify(ser_dict)

static func deserialize_mtp(avatar_scene_node: Node, data: String) -> MeshTrianglePoint:
	var ser_dict: Dictionary = JSON.parse_string(data)
	
	var mtp: MeshTrianglePoint = MeshTrianglePoint.new()
	mtp.mesh_instance = avatar_scene_node.get_node(ser_dict["mesh_instance_path"])
	mtp.point_on_triangle = ser_dict["point_on_triangle"]
	mtp.ray_origin_dist = ser_dict["ray_origin_dist"]
	mtp.surface_id = mtp.surface_id
	mtp.vertex_ids = ser_dict["vertex_ids"]
	
	return mtp

static func serialize_triangle_transform(triangle_transform: TriangleTransform) -> String:
	var ser_dict: Dictionary = {}
	ser_dict["coord_lengths"] = triangle_transform.coord_lengths
	ser_dict["original_rotation"] = triangle_transform.original_rotation
	
	return JSON.stringify(ser_dict)

static func deserialize_triangle_transform(data: String) -> TriangleTransform:
	var ser_dict: Dictionary = JSON.parse_string(data)
	
	var triangle_transform: TriangleTransform = TriangleTransform.new()
	triangle_transform.coord_lengths = ser_dict["coord_lengths"]
	triangle_transform.original_rotation = ser_dict["original_rotation"]
	
	return triangle_transform

static func serialize_prop(avatar_scene_node: Node, prop: Node3D) -> String:
	var ser_dict: Dictionary = {}
	ser_dict["mtp"]  = SerializePropData.serialize_mtp(avatar_scene_node, prop.mesh_triangle_point)
	ser_dict["triangle_transform"]  = SerializePropData.serialize_triangle_transform(prop.triangle_transform)
	ser_dict["asset_file"] = prop.asset_file
	
	return JSON.stringify(ser_dict)

static func deserialize_prop(avatar_scene_node: Node, prop_data: String) -> Dictionary:
	var ret: Dictionary = JSON.parse_string(prop_data)
	ret["mtp"] = SerializePropData.deserialize_mtp(avatar_scene_node, ret["mtp"])
	ret["triangle_transform"] = SerializePropData.deserialize_triangle_transform(ret["triangle_transform"])
	
	return ret
