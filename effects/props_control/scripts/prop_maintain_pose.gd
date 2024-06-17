extends Node3D

var mesh_triangle_point: MeshTrianglePoint
var triangle_transform: TriangleTransform

var asset_file: String

@onready
var normal_offset: float = 0.0

@onready var _props_control: PropsControl = get_node(Effects.EFFECTS_NODE_PATH).get_props_control()

func _get_cam_projection_normal(camera: Camera3D) -> Vector3:
	return camera.global_basis * Vector3(0.0, 0.0, -1.0)

func _get_z_depth(camera: Camera3D, global_pos: Vector3) -> float:
	var projection_normal: Vector3 = self._get_cam_projection_normal(camera)
	var projection_plane: Plane = Plane(projection_normal, camera.global_position)
	return projection_plane.distance_to(global_pos)

static func _init_input():
	InputSetup.set_input_default_mouse_button("prop_select",         MOUSE_BUTTON_LEFT)
	InputSetup.set_input_default_key(         "prop_delete",         KEY_DELETE)
	InputSetup.set_input_default_mouse_button("prop_move",           MOUSE_BUTTON_LEFT, true, true)
	InputSetup.set_input_default_mouse_button("prop_translate_down", MOUSE_BUTTON_WHEEL_DOWN, true)
	InputSetup.set_input_default_mouse_button("prop_translate_up",   MOUSE_BUTTON_WHEEL_UP,   true)
	InputSetup.set_input_default_mouse_button("prop_scale_down",     MOUSE_BUTTON_WHEEL_DOWN, false, true)
	InputSetup.set_input_default_mouse_button("prop_scale_up",       MOUSE_BUTTON_WHEEL_UP,   false, true)
	InputSetup.set_input_default_key(         "prop_flip_v",         KEY_V, true)
	InputSetup.set_input_default_key(         "prop_flip_h",         KEY_H, true)

func _handle_input(event: InputEvent):
	var prop_already_selected: bool = self._props_control.get_selected_prop() == self
	if event.is_action("prop_select"):
		self._props_control.set_selected_prop(self)
	
	# Everything after this is only acted on if prop is selected
	if not prop_already_selected:
		return
	
	if Input.is_action_pressed("prop_move"):
		# Move prop to new mouse position
		var new_mtp: MeshTrianglePoint = null
		if not Input.is_key_pressed(KEY_SHIFT):
			# If shift is not pressed, keep prop pinned to the mesh
			new_mtp = AvatarSelect.select_triangle(self._props_control.camera, event.global_position)
		elif self.mesh_triangle_point:
			# If shift is pressed, move prop along camera projection plane instead of pinning it to the mesh
			new_mtp = self.mesh_triangle_point
			
			var z_depth: float = self._get_z_depth(self._props_control.camera, new_mtp.point_on_triangle)
			new_mtp.point_on_triangle = self._props_control.camera.project_position(event.global_position, z_depth)
		
		if new_mtp:
			self.mesh_triangle_point = new_mtp
			self.triangle_transform  = AvatarSelect.get_triangle_transform(self.mesh_triangle_point)
	elif Input.is_action_pressed("prop_delete"):
		# Delete prop
		self._props_control.delete_prop(self)
		return
	elif event.is_action_pressed("prop_translate_down"):
		# Move prop in relation to selected triangle
		self.normal_offset -= 0.01
	elif event.is_action_pressed("prop_translate_up"):
		# Move prop in relation to selected triangle
		self.normal_offset += 0.01
	elif event.is_action_pressed("prop_scale_up"):
		# Scale prop
		self.scale += Vector3(0.001, 0.001, 0.001)
	elif event.is_action_pressed("prop_scale_down"):
		# Scale prop
		self.scale -= Vector3(0.001, 0.001, 0.001)
	
	if Input.is_action_just_pressed("prop_flip_v"):
		self._flip_prop_v()
	elif Input.is_action_just_pressed("prop_flip_h"):
			self._flip_prop_h()

func _flip_prop_v():
	var node = self.get_node(".")
	if node is Sprite3D:
		var t: Sprite3D = node
		t.set_flip_v(!t.is_flipped_v())

func _flip_prop_h():
	var node = self.get_node(".")
	if node is Sprite3D:
		var t: Sprite3D = node
		t.set_flip_h(!t.is_flipped_h())

func _process(_delta):
	if not mesh_triangle_point:
		return
	
	# Keep prop aligned to selected triangle
	self.update_pose()

func update_pose():
	# Keep prop aligned to selected triangle
	var new_tf: Transform3D = AvatarSelect.get_update_triangle_point_transform(
		self.mesh_triangle_point, 
		self.triangle_transform, 
		self.normal_offset)
	#var orig_euler: Vector3 = self.triangle_transform.get_original_rotation().get_euler(2)
	new_tf.basis = new_tf.basis * self.triangle_transform.get_original_rotation().inverse()# * Basis(Vector3(0.0, 1.0, 0.0), 180.0*PI/180.0)
	
	if new_tf.origin.is_finite():
		self.transform.origin = new_tf.origin
		self.transform.basis = new_tf.basis.scaled(self.scale)
