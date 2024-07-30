extends Node

@onready
var triangle_ray_select: TriangleRaySelect = TriangleRaySelect.new()
var selectable_meshes: Array[MeshInstance3D]

func _get_child_meshes(node: Node) -> Array[MeshInstance3D]:
	if not node:
		return []
	
	var ret: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		ret.append(node)
	
	for child in node.get_children():
		ret += self._get_child_meshes(child)
	
	return ret

func _on_model_loaded(avatar_base: AvatarBase):
	# Reset avatar meshes
	self.selectable_meshes.clear()
	self.selectable_meshes = self._get_child_meshes(avatar_base)

func _ready():
	get_node(Main.MAIN_NODE_PATH).connect_avatar_loaded(self._on_model_loaded)

func get_triangle_ray_select() -> TriangleRaySelect:
	return self.triangle_ray_select

func select_triangle(camera: Camera3D, pixel: Vector2i) -> MeshTrianglePoint:
	return self.triangle_ray_select.select_triangle_from_meshes_cam(self.selectable_meshes, camera, pixel)

func get_triangle_transform(mesh_triangle_point: MeshTrianglePoint, rotation: Basis = Basis()) -> TriangleTransform:
	if not mesh_triangle_point or not mesh_triangle_point.mesh_instance:
		return TriangleTransform.new()
	
	return self.triangle_ray_select.get_triangle_transform_msi(mesh_triangle_point, Transform3D(rotation, mesh_triangle_point.point_on_triangle))

func get_update_triangle_point_transform(mesh_triangle_point: MeshTrianglePoint, 
		triangle_transform: TriangleTransform, normal_offset: float = 0.0) -> Transform3D:
	var updated_verts: PackedVector3Array = self.triangle_ray_select.get_triangle_vertices(mesh_triangle_point)
	return triangle_transform.adjust_transform(updated_verts, normal_offset) if updated_verts.size() == 3 else Transform3D(Basis(), Vector3.INF)
