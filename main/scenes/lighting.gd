extends DirectionalLight3D

const LOOK_POSITION_NODE_NAME: String = "LookOffset"
const DEFAULT_LIGHTING_OFFSET: float = 0.591
const DEFAULT_LIGHTING_ROTATION: Basis = Basis(Vector3(1.0, 0.0, 0.0), -30.0*PI/180.0)

func _on_avatar_loaded(avatar_base: AvatarBase):
	var lighting_pose: Transform3D = Transform3D()
	
	var look_node: Node3D = avatar_base.find_child(LOOK_POSITION_NODE_NAME)
	if look_node:
		lighting_pose = look_node.global_transform
		lighting_pose.basis = lighting_pose.basis * DEFAULT_LIGHTING_ROTATION
		lighting_pose.origin += lighting_pose.basis * Vector3(0.0, 0.0, DEFAULT_LIGHTING_OFFSET)
		
		self.transform = lighting_pose

func _ready():
	get_node(Main.MAIN_NODE_PATH).connect_avatar_loaded(self._on_avatar_loaded)
