extends ControlCamera3D

const LOOK_POSITION_NODE_NAME: String = "LookOffset"
const DEFAULT_CAM_HEAD_DISTANCE: float = 0.591

@onready
var _default_tf: Transform3D = self.transform

@onready
var _default_pivot_pos: Vector3 = self.global_transform.origin

func _on_avatar_loaded(avatar_base: AvatarBase):
	var cam_pose: Transform3D = Transform3D()
	
	var look_node: Node3D = avatar_base.find_child(LOOK_POSITION_NODE_NAME)
	if look_node:
		cam_pose = look_node.global_transform
		cam_pose.origin += cam_pose.basis * Vector3(0.0, 0.0, DEFAULT_CAM_HEAD_DISTANCE)
		
		self.global_transform = cam_pose
		self.pivot_pos = look_node.global_transform.origin

func _ready():
	self.zoom_in = 1e-1
	self.zoom_out = INF
	
	get_node(Main.MAIN_NODE_PATH).connect_avatar_loaded(self._on_avatar_loaded)
	var props_control: Node = get_node_or_null(Effects.EFFECTS_NODE_PATH).get_props_control()
	if props_control:
		props_control.camera = self

func reset_view():
	self.transform = self._default_tf
	self.pivot_pos = self._default_pivot_pos
